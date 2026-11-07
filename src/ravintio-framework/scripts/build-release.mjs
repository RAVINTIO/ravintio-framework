#!/usr/bin/env node
/**
 * build-release.mjs - rebuild the root ravintio-framework/ release copy from
 * src/ravintio-framework/ (feature 0000041, req-002, ADR-003).
 *
 * Usage: node build-release.mjs
 *
 * The script takes no arguments. The root comes from the working directory,
 * with CLAUDE_PROJECT_DIR cleared. It runs only when projectKind(root) returns
 * `framework source`. The real working directory, the root, and the git top
 * level must be one path.
 *
 * What it builds:
 *   - Each file that `git ls-files -z -- src/ravintio-framework` lists, except
 *     component.yml, with its bytes and its executable bit.
 *   - ravintio-framework/release.yml, with format, version, source-commit,
 *     built, and a SHA-256 for each file (CRLF read as LF).
 *
 * Write boundary (risk R-002): every write and delete lands inside one of
 * three folders at the root:
 *   ravintio-framework/, .ravintio-framework-build/, .ravintio-framework-previous/
 * Before any change, each of them and src/ravintio-framework/ must be absent
 * or a real folder that resolves to its own place inside the real root. The
 * recursive delete never follows a link. Source files open with O_NOFOLLOW,
 * and new files open with O_CREAT | O_EXCL | O_NOFOLLOW.
 *
 * Build and swap:
 *   1. Recover a leftover state from an interrupted run.
 *   2. Build the new copy and release.yml in .ravintio-framework-build/.
 *   3. Rename ravintio-framework/ to .ravintio-framework-previous/.
 *   4. Rename .ravintio-framework-build/ to ravintio-framework/.
 *   5. Delete .ravintio-framework-previous/.
 *
 * Output: one `added:`, `changed:`, or `removed:` line per differing file,
 * then one `summary:` line.
 *
 * Exit codes:
 *   0 - the new copy is in place
 *   2 - a refusal; nothing written, reason on stderr
 *   1 - a file-system or git failure; the old copy stays whole, and stderr
 *       names the operation
 */

import {
  closeSync, constants, fchmodSync, fstatSync, lstatSync, mkdirSync, openSync, readdirSync,
  readFileSync, realpathSync, renameSync, rmdirSync, unlinkSync, writeSync,
} from "node:fs";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { join, sep } from "node:path";
import { resolveRoot } from "../hooks/enforcement/path-rules.mjs";
import { projectKind } from "./project-kind.mjs";

const SRC_REL = "src/ravintio-framework";
const COPY = "ravintio-framework";
const BUILD = ".ravintio-framework-build";
const PREVIOUS = ".ravintio-framework-previous";
const BOUNDARY = [COPY, BUILD, PREVIOUS];
const SEGMENT_RE = /^[A-Za-z0-9._-]+$/;
const VERSION_RE = /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/;
const SHA_RE = /^[0-9a-f]{40}$/;
const MAX_LEN = 300;
const O_NOFOLLOW = constants.O_NOFOLLOW ?? 0;

class Refusal extends Error {}
class Failure extends Error {}

// Sanitise a value before it reaches output: printable ASCII only, capped.
function clean(v) {
  return String(v).replace(/[^\x20-\x7e]/g, "?").slice(0, MAX_LEN);
}

function lstatOrNull(p) {
  try { return lstatSync(p); } catch (e) {
    if (e.code === "ENOENT") return null;
    throw new Failure(`lstat ${clean(p)}: ${e.code ?? "error"}`);
  }
}

// An argument is named by its flag part only, never by a value.
function argName(arg, index) {
  const s = String(arg);
  if (s.startsWith("-")) return clean(s.split("=")[0].slice(0, 40));
  return `argument ${index + 1}`;
}

// git: run git in root. The child environment drops every variable that can
// move the repository or inject config, and fsmonitor stays off (F-06).
function git(root, args) {
  const env = { ...process.env };
  for (const name of Object.keys(env)) {
    if (/^GIT_CONFIG_(KEY|VALUE)_/.test(name)) delete env[name];
  }
  delete env.GIT_DIR;
  delete env.GIT_WORK_TREE;
  delete env.GIT_INDEX_FILE;
  delete env.GIT_CONFIG_COUNT;
  delete env.GIT_CONFIG_PARAMETERS;
  try {
    return execFileSync("git", ["-c", "core.fsmonitor=false", "-C", root, ...args], {
      env, stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 * 1024,
    });
  } catch (e) {
    throw new Failure(`git ${args[0]} failed: ${e.code ?? `exit ${e.status}`}`);
  }
}

// readNoFollow: the bytes of a regular file, opened without following a link.
function readNoFollow(p) {
  let fd;
  try {
    fd = openSync(p, constants.O_RDONLY | O_NOFOLLOW);
    if (!fstatSync(fd).isFile()) throw new Failure(`read ${clean(p)}: not a regular file`);
    return readFileSync(fd);
  } catch (e) {
    if (e instanceof Failure) throw e;
    throw new Failure(`read ${clean(p)}: ${e.code ?? "error"}`);
  } finally {
    if (fd !== undefined) closeSync(fd);
  }
}

function readVersion(root) {
  const text = readNoFollow(join(root, SRC_REL, "component.yml")).toString("utf-8");
  const m = text.match(/^version:\s*(.+?)\s*$/m);
  const v = m ? m[1].replace(/\s+#.*$/, "").replace(/^["']|["']$/g, "") : "";
  if (!VERSION_RE.test(v)) {
    throw new Refusal(`${SRC_REL}/component.yml has no MAJOR.MINOR.PATCH version`);
  }
  return v;
}

// checkBoundary: each folder is absent or a real folder at its own place.
function checkBoundary(root) {
  for (const rel of [...BOUNDARY, SRC_REL]) {
    const abs = join(root, rel);
    const st = lstatOrNull(abs);
    if (!st) continue;
    if (st.isSymbolicLink()) throw new Refusal(`${rel} is a link`);
    if (!st.isDirectory()) throw new Refusal(`${rel} is not a folder`);
    let real;
    try { real = realpathSync(abs); } catch (e) {
      throw new Refusal(`${rel} does not resolve: ${e.code ?? "error"}`);
    }
    if (real !== abs) throw new Refusal(`${rel} resolves outside its place in the root`);
  }
}

function checkClean(root) {
  const out = git(root, ["status", "--porcelain", "-z", "--", SRC_REL]).toString("utf-8");
  const first = out.split("\0")[0];
  if (first) throw new Refusal(`uncommitted change under ${SRC_REL}: ${clean(first.slice(3))}`);
}

// sourceFiles: the tracked pack files as { rel, exec }, sorted by rel.
function sourceFiles(root) {
  const out = git(root, ["ls-files", "-s", "-z", "--", SRC_REL]).toString("utf-8");
  const files = [];
  const folded = new Map();
  for (const entry of out.split("\0")) {
    if (!entry) continue;
    const tab = entry.indexOf("\t");
    const [mode, , stage] = entry.slice(0, tab).split(" ");
    const path = entry.slice(tab + 1);
    if (mode !== "100644" && mode !== "100755") {
      throw new Refusal(`${clean(path)} is not a regular file (mode ${clean(mode)})`);
    }
    if (stage !== "0") throw new Refusal(`${clean(path)} has an unresolved merge`);
    if (!path.startsWith(`${SRC_REL}/`)) throw new Refusal(`${clean(path)} lies outside ${SRC_REL}`);
    const rel = path.slice(SRC_REL.length + 1);
    for (const seg of rel.split("/")) {
      if (!SEGMENT_RE.test(seg) || seg === "." || seg === "..") {
        throw new Refusal(`${clean(path)} has a path segment outside [A-Za-z0-9._-]+`);
      }
    }
    // F-07: the build writes release.yml itself, and a case-only collision
    // would clash on a case-insensitive file system.
    if (rel.toLowerCase() === "release.yml") throw new Refusal(`${clean(path)} clashes with the built release.yml`);
    const segs = rel.split("/");
    for (let i = 1; i <= segs.length; i++) {
      const prefix = segs.slice(0, i).join("/");
      const key = prefix.toLowerCase();
      const had = folded.get(key);
      if (had === undefined) folded.set(key, prefix);
      else if (had !== prefix) throw new Refusal(`${clean(had)} and ${clean(prefix)} differ only in case`);
    }
    if (rel === "component.yml") continue;
    files.push({ rel, exec: mode === "100755" });
  }
  if (files.length === 0) throw new Refusal(`git lists no files under ${SRC_REL}`);
  files.sort((a, b) => (a.rel < b.rel ? -1 : a.rel > b.rel ? 1 : 0));
  return files;
}

// removeTree: delete abs and everything under it, never following a link.
// A link goes as a link. abs must be one of the boundary folders or lie inside one.
function removeTree(root, abs) {
  if (!BOUNDARY.some((rel) => abs === join(root, rel) || abs.startsWith(join(root, rel) + sep))) {
    throw new Failure(`delete ${clean(abs)}: outside the write boundary`);
  }
  const st = lstatOrNull(abs);
  if (!st) return;
  try {
    if (st.isDirectory()) {
      for (const name of readdirSync(abs)) removeTree(root, join(abs, name));
      rmdirSync(abs);
    } else {
      unlinkSync(abs);
    }
  } catch (e) {
    if (e instanceof Failure) throw e;
    throw new Failure(`delete ${clean(abs)}: ${e.code ?? "error"}`);
  }
}

function rename(root, from, to) {
  try { renameSync(join(root, from), join(root, to)); } catch (e) {
    throw new Failure(`rename ${from} to ${to}: ${e.code ?? "error"}`);
  }
}

function recover(root, print) {
  if (lstatOrNull(join(root, BUILD))) removeTree(root, join(root, BUILD));
  if (lstatOrNull(join(root, PREVIOUS))) {
    if (!lstatOrNull(join(root, COPY))) {
      rename(root, PREVIOUS, COPY);
      print(`restored: ${COPY}/ from an interrupted build`);
    } else {
      removeTree(root, join(root, PREVIOUS));
    }
  }
}

const sha256 = (buf) => createHash("sha256").update(buf).digest("hex");
const lfHash = (buf) => sha256(Buffer.from(buf.toString("latin1").replace(/\r\n/g, "\n"), "latin1"));

// readOldCopy: rel -> { hash, exec } for each file, or { link: true } for each
// non-folder entry that is not a regular file. Never follows a link.
function readOldCopy(root) {
  const map = new Map();
  const top = join(root, COPY);
  if (!lstatOrNull(top)) return map;
  const walk = (dir, prefix) => {
    let names;
    try { names = readdirSync(dir); } catch (e) {
      throw new Failure(`read ${clean(dir)}: ${e.code ?? "error"}`);
    }
    for (const name of names) {
      const abs = join(dir, name);
      const rel = prefix ? `${prefix}/${name}` : name;
      const st = lstatOrNull(abs);
      if (!st) continue;
      if (st.isDirectory()) walk(abs, rel);
      else if (st.isFile()) map.set(rel, { hash: sha256(readNoFollow(abs)), exec: (st.mode & 0o100) !== 0 });
      else map.set(rel, { link: true });
    }
  };
  walk(top, "");
  return map;
}

function writeNew(abs, buf, mode) {
  let fd;
  try {
    fd = openSync(abs, constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL | O_NOFOLLOW, mode);
    let off = 0;
    while (off < buf.length) off += writeSync(fd, buf, off, buf.length - off);
    fchmodSync(fd, mode);
  } catch (e) {
    throw new Failure(`write ${clean(abs)}: ${e.code ?? "error"}`);
  } finally {
    if (fd !== undefined) closeSync(fd);
  }
}

// assertRealDirs: no folder between the pack source and a file is a link.
function assertRealDirs(root, rel, seen) {
  const parts = rel.split("/").slice(0, -1);
  let walked = "";
  for (const part of parts) {
    walked = walked ? `${walked}/${part}` : part;
    if (seen.has(walked)) continue;
    const st = lstatOrNull(join(root, SRC_REL, walked));
    if (!st || st.isSymbolicLink() || !st.isDirectory()) {
      throw new Failure(`read ${SRC_REL}/${clean(walked)}: not a real folder`);
    }
    seen.add(walked);
  }
}

// build: the new copy in BUILD. Returns rel -> { hash, exec } for each file.
function build(root, files, header) {
  const out = join(root, BUILD);
  const made = new Map();
  const seen = new Set();
  const lines = [];
  try {
    mkdirSync(out, { mode: 0o700 });
  } catch (e) {
    throw new Failure(`mkdir ${BUILD}: ${e.code ?? "error"}`);
  }
  try {
    const dirs = new Set();
    for (const { rel, exec } of files) {
      assertRealDirs(root, rel, seen);
      const buf = readNoFollow(join(root, SRC_REL, rel));
      const parts = rel.split("/");
      for (let i = 1; i < parts.length; i++) {
        const d = parts.slice(0, i).join("/");
        if (dirs.has(d)) continue;
        try { mkdirSync(join(out, d)); } catch (e) {
          throw new Failure(`mkdir ${BUILD}/${clean(d)}: ${e.code ?? "error"}`);
        }
        dirs.add(d);
      }
      writeNew(join(out, rel), buf, exec ? 0o755 : 0o644);
      made.set(rel, { hash: sha256(buf), exec });
      lines.push(`  "${rel}": "${lfHash(buf)}"\n`);
    }
    const release = Buffer.from(header + lines.join(""), "utf-8");
    writeNew(join(out, "release.yml"), release, 0o644);
    made.set("release.yml", { hash: sha256(release), exec: false });
    return made;
  } catch (e) {
    try { removeTree(root, out); } catch { /* the next run removes it */ }
    throw e;
  }
}

function report(oldMap, newMap, version, commit, print) {
  const all = [...new Set([...oldMap.keys(), ...newMap.keys()])].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  let added = 0, changed = 0, removed = 0, unchanged = 0;
  for (const rel of all) {
    const o = oldMap.get(rel), n = newMap.get(rel);
    if (!o) { print(`added: ${COPY}/${clean(rel)}`); added++; }
    else if (!n) { print(`removed: ${COPY}/${clean(rel)}`); removed++; }
    else if (o.link || o.hash !== n.hash || o.exec !== n.exec) { print(`changed: ${COPY}/${clean(rel)}`); changed++; }
    else unchanged++;
  }
  print(`summary: version ${version}, source-commit ${commit}, added ${added}, changed ${changed}, removed ${removed}, unchanged ${unchanged}`);
}

function resolveRootFromCwd() {
  const saved = process.env.CLAUDE_PROJECT_DIR;
  delete process.env.CLAUDE_PROJECT_DIR;
  try {
    const cwd = process.cwd();
    return resolveRoot(cwd);
  } catch {
    return null;
  } finally {
    if (saved !== undefined) process.env.CLAUDE_PROJECT_DIR = saved;
  }
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.length > 0) throw new Refusal(`takes no arguments, got ${argName(argv[0], 0)}`);

  const found = resolveRootFromCwd();
  if (!found) throw new Refusal("cannot resolve the project root from the working directory");
  let root;
  try { root = realpathSync(found); } catch (e) {
    throw new Refusal(`cannot resolve the project root: ${e.code ?? "error"}`);
  }
  // F-01: the working directory must be the root itself, not a folder under it.
  let cwd;
  try { cwd = realpathSync(process.cwd()); } catch (e) {
    throw new Refusal(`cannot resolve the working directory: ${e.code ?? "error"}`);
  }
  if (cwd !== root) throw new Refusal("run from the project root, not a folder under it");

  const { kind } = projectKind(root);
  if (kind !== "framework source") throw new Refusal(`project kind is ${clean(kind)}, not framework source`);

  // F-01: the root must also be the git top level.
  const top = git(root, ["rev-parse", "--show-toplevel"]).toString("utf-8").replace(/\n$/, "");
  let realTop;
  try { realTop = realpathSync(top); } catch (e) {
    throw new Refusal(`cannot resolve the git top level: ${e.code ?? "error"}`);
  }
  if (realTop !== root) throw new Refusal("the project root is not the git top level");

  const version = readVersion(root);
  checkBoundary(root);
  const commit = git(root, ["rev-parse", "HEAD"]).toString("utf-8").trim();
  if (!SHA_RE.test(commit)) throw new Failure("git rev-parse HEAD gave no 40-character commit");
  checkClean(root);
  const files = sourceFiles(root);

  // Every refusal has run. Changes start here.
  const lines = [];
  const print = (l) => lines.push(l);
  // F-08: the restored line prints at once, so a later failure cannot hide it.
  recover(root, (l) => process.stdout.write(`${l}\n`));
  const oldMap = readOldCopy(root);
  const built = new Date().toISOString().slice(0, 10);
  const header =
    "# Written by scripts/build-release.mjs. Do not edit.\n" +
    "format: 1\n" +
    `version: "${version}"\n` +
    `source-commit: "${commit}"\n` +
    `built: "${built}"\n` +
    "files:\n";
  const newMap = build(root, files, header);

  if (lstatOrNull(join(root, COPY))) rename(root, COPY, PREVIOUS);
  rename(root, BUILD, COPY);
  removeTree(root, join(root, PREVIOUS));

  report(oldMap, newMap, version, commit, print);
  process.stdout.write(lines.map((l) => `${l}\n`).join(""));
}

// process.exitCode, not process.exit(), so a piped stdout drains in full.
try {
  main();
  process.exitCode = 0;
} catch (e) {
  if (e instanceof Refusal) {
    process.stderr.write(`build-release: ${e.message}\n`);
    process.exitCode = 2;
  } else {
    const msg = e instanceof Failure ? e.message : `unexpected error: ${clean(e?.code ?? e?.name ?? "error")}`;
    process.stderr.write(`build-release: ${msg}\n`);
    process.exitCode = 1;
  }
}
