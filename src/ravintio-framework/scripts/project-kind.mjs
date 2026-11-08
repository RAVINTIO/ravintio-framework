#!/usr/bin/env node
/**
 * project-kind.mjs - decide the project kind from the source-repo signal
 * (req-005, ADR-007, feature 0000041).
 *
 * Usage: node project-kind.mjs [--root <dir>]
 *
 * Prints `framework source` or `downstream` on stdout and the reason on
 * stderr. The project is a framework source when all of these hold at the root:
 *   - product.yml is a regular file, not a link.
 *   - Its components[] list has id ravintio-framework with path
 *     src/ravintio-framework/component.yml.
 *   - That component.yml is a regular file and no part of its path is a link.
 * Every other case, including an unreadable or malformed product.yml, reads
 * as downstream.
 *
 * Exit codes:
 *   0 - a kind was printed
 *   2 - bad argument
 *
 * Writes no file. No YAML dependency: it reads product.yml line by line in the
 * constrained shape that product-version.mjs reads.
 */

import { lstatSync, readFileSync, realpathSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const COMPONENT_ID = "ravintio-framework";
const COMPONENT_PATH = "src/ravintio-framework/component.yml";

function unquote(v) {
  return v.trim().replace(/^["']|["']$/g, "");
}

function parseComponents(text) {
  const components = [];
  let inComponents = false;
  let current = null;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.replace(/#.*$/, "").trimEnd();
    if (!line.trim()) continue;
    if (/^components:\s*$/.test(line)) { inComponents = true; current = null; continue; }
    if (/^[A-Za-z]/.test(line)) inComponents = false;
    if (!inComponents) continue;
    const idMatch = line.match(/^\s*-\s*id:\s*(.+)$/);
    if (idMatch) { current = { id: unquote(idMatch[1]), path: null }; components.push(current); continue; }
    const pathMatch = line.match(/^\s*path:\s*(.+)$/);
    if (pathMatch && current) current.path = unquote(pathMatch[1]);
  }
  return components;
}

function lstatOrNull(p) {
  try { return lstatSync(p); } catch { return null; }
}

export function projectKind(root) {
  const down = (reason) => ({ kind: "downstream", reason });

  const productPath = join(root, "product.yml");
  const productStat = lstatOrNull(productPath);
  if (!productStat) return down(`no product.yml at ${root}`);
  if (productStat.isSymbolicLink()) return down("product.yml is a link");
  if (!productStat.isFile()) return down("product.yml is not a regular file");

  let components;
  try {
    components = parseComponents(readFileSync(productPath, "utf-8"));
  } catch (e) {
    return down(`product.yml is unreadable: ${e.message}`);
  }
  if (!components.some((c) => c.id === COMPONENT_ID && c.path === COMPONENT_PATH)) {
    return down(`product.yml has no ${COMPONENT_ID} entry with path ${COMPONENT_PATH}`);
  }

  let walked = root;
  for (const part of COMPONENT_PATH.split("/")) {
    walked = join(walked, part);
    const st = lstatOrNull(walked);
    if (!st) return down(`${COMPONENT_PATH} is missing`);
    if (st.isSymbolicLink()) return down(`${walked} is a link`);
  }
  if (!lstatOrNull(walked).isFile()) return down(`${COMPONENT_PATH} is not a regular file`);

  return { kind: "framework source", reason: `product.yml and ${COMPONENT_PATH} meet the source-repo signal` };
}

function parseArgs(argv) {
  let root = process.cwd();
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--root" && argv[i + 1]) { root = argv[++i]; continue; }
    return { error: `bad argument: ${argv[i]}${argv[i] === "--root" ? " (needs a value)" : ""}` };
  }
  return { root };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.error) {
    process.stderr.write(`project-kind: ${args.error}\nusage: node project-kind.mjs [--root <dir>]\n`);
    process.exit(2);
  }
  const { kind, reason } = projectKind(args.root);
  process.stdout.write(`${kind}\n`);
  process.stderr.write(`project-kind: ${reason}\n`);
  process.exit(0);
}

let direct = false;
try {
  direct = realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url));
} catch { /* imported from -e or stdin: no entry file */ }
if (direct) main();
