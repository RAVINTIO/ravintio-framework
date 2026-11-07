#!/usr/bin/env node
/**
 * release-check.mjs - detect a framework release update and each changed pack
 * file (feature 0000041, req-003, ADR-004).
 *
 * Usage: node release-check.mjs [--root <dir>] [--files-only]
 *
 * The root defaults to the working directory. The script is read-only. It
 * writes no file, so step 1a writes plan/framework-release.yml with Write.
 *
 * Inputs, each read without following a link:
 *   ravintio-framework/release.yml   in req-002's format
 *   ravintio-framework/component.yml the fallback for a pack before 0.39.0
 *   plan/framework-release.yml       the release this repo last trusted
 *   docs/about.md                    the first-upgrade fallback version
 *
 * Output lines:
 *   release:, recorded:, update: release | own-build | none, record:,
 *   changed:, missing:, unlisted:, files: not checked, no release.yml,
 *   warn:, and skipped: in --files-only mode.
 *
 * Hash rule (req-002): SHA-256 of the content after each CRLF pair reads as
 * LF, in lowercase hex.
 *
 * Exit codes:
 *   0 - nothing to confirm
 *   1 - a candidate update: update: release, or any file line
 *   2 - the check could not run, reason on stderr
 */

import { closeSync, constants, fstatSync, lstatSync, openSync, readFileSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { join, resolve } from "node:path";
import { projectKind } from "./project-kind.mjs";

const COPY = "ravintio-framework";
const SRC_REL = "src/ravintio-framework";
const RECORD_REL = "plan/framework-release.yml";
const SEGMENT_RE = /^[A-Za-z0-9._-]+$/;
const VERSION_RE = /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/;
const SHA_RE = /^[0-9a-f]{40}$/;
const HASH_RE = /^[0-9a-f]{64}$/;
const TOP_SKIP = new Set(["release.yml", "component.yml"]);
const ANY_SKIP = new Set([".DS_Store", "Thumbs.db", "desktop.ini"]);
const MAX_LEN = 300;
const O_NOFOLLOW = constants.O_NOFOLLOW ?? 0;

class Refusal extends Error {}

function clean(v) {
  return String(v).replace(/[^\x20-\x7e]/g, "?").slice(0, MAX_LEN);
}

function lstatOrNull(p) {
  try { return lstatSync(p); } catch (e) {
    if (e.code === "ENOENT") return null;
    throw new Refusal(`lstat ${clean(p)}: ${e.code ?? "error"}`);
  }
}

// readNoFollow: the bytes of a regular file, opened without following a link.
function readNoFollow(p) {
  let fd;
  try {
    fd = openSync(p, constants.O_RDONLY | O_NOFOLLOW);
    if (!fstatSync(fd).isFile()) throw new Refusal(`read ${clean(p)}: not a regular file`);
    return readFileSync(fd);
  } catch (e) {
    if (e instanceof Refusal) throw e;
    throw new Refusal(`read ${clean(p)}: ${e.code ?? "error"}`);
  } finally {
    if (fd !== undefined) closeSync(fd);
  }
}

// readRegular: the text of a file that must be absent or a regular file.
// Returns null when absent. A link or any other entry is a refusal.
function readRegular(root, rel) {
  const st = lstatOrNull(join(root, rel));
  if (!st) return null;
  if (st.isSymbolicLink()) throw new Refusal(`${rel} is a link`);
  if (!st.isFile()) throw new Refusal(`${rel} is not a regular file`);
  return readNoFollow(join(root, rel)).toString("utf-8");
}

// The hash rule, as build-release.mjs applies it.
const sha256 = (buf) => createHash("sha256").update(buf).digest("hex");
const lfHash = (buf) => sha256(Buffer.from(buf.toString("latin1").replace(/\r\n/g, "\n"), "latin1"));

const lines = (text) => text.split("\n").map((l) => l.replace(/\r$/, ""));

// parseRelease: { version, commit, files: Map(path -> hash) }, or a refusal.
function parseRelease(text) {
  const bad = (why) => new Refusal(`${COPY}/release.yml breaks the format: ${why}`);
  if (!text.endsWith("\n")) throw bad("no final line feed");
  const all = lines(text).slice(0, -1);
  let i = 0;
  while (i < all.length && all[i].startsWith("#")) i++;
  const take = (re, name) => {
    const m = (all[i] ?? "").match(re);
    if (!m) throw bad(`expected ${name} at line ${i + 1}`);
    i++;
    return m[1];
  };
  const format = take(/^format: ([0-9]+)$/, "format");
  if (format !== "1") throw bad(`format ${clean(format)} is not 1`);
  const version = take(/^version: "([^"]*)"$/, "version");
  if (!VERSION_RE.test(version)) throw bad("version is not MAJOR.MINOR.PATCH");
  const commit = take(/^source-commit: "([^"]*)"$/, "source-commit");
  if (!SHA_RE.test(commit)) throw bad("source-commit is not 40 lowercase hex characters");
  take(/^built: "([0-9]{4}-[0-9]{2}-[0-9]{2})"$/, "built");
  take(/^(files):$/, "files");
  const files = new Map();
  let last = null;
  for (; i < all.length; i++) {
    const m = all[i].match(/^ {2}"([^"]+)": "([^"]+)"$/);
    if (!m) throw bad(`line ${i + 1} is not a file entry`);
    const [, path, hash] = m;
    if (!HASH_RE.test(hash)) throw bad(`line ${i + 1} has no SHA-256`);
    if (path.split("/").some((s) => !SEGMENT_RE.test(s) || s === "." || s === "..")) {
      throw bad(`line ${i + 1} has a path segment outside [A-Za-z0-9._-]+`);
    }
    if (last !== null && !(last < path)) throw bad(`line ${i + 1} is out of order`);
    last = path;
    files.set(path, hash);
  }
  return { version, commit, files };
}

// parseRecord: { version, commit } from plan/framework-release.yml.
function parseRecord(text) {
  const v = text.match(/^version: "([^"]*)"\r?$/m);
  const c = text.match(/^source-commit: "([^"]*)"\r?$/m);
  if (!v || !c || !VERSION_RE.test(v[1]) || !SHA_RE.test(c[1])) {
    throw new Refusal(`${RECORD_REL} has no valid version and source-commit`);
  }
  return { version: v[1], commit: c[1] };
}

function quotedVersion(text) {
  const m = text.match(/^version:\s*(.+?)\s*$/m);
  return m ? m[1].replace(/\s+#.*$/, "").replace(/^["']|["']$/g, "") : "";
}

// aboutVersion: the front-matter version in docs/about.md, or null.
function aboutVersion(root) {
  const text = readRegular(root, "docs/about.md");
  if (text === null) return null;
  const all = lines(text);
  if (all[0] !== "---") return null;
  const end = all.indexOf("---", 1);
  if (end < 0) return null;
  const v = quotedVersion(all.slice(1, end).join("\n"));
  return v || null;
}

// walkCopy: rel -> { hash } for each regular file, or { link: true } for any
// other entry. Never follows a link.
function walkCopy(top) {
  const map = new Map();
  const walk = (dir, prefix) => {
    let names;
    try { names = readdirSync(dir); } catch (e) {
      throw new Refusal(`read ${clean(dir)}: ${e.code ?? "error"}`);
    }
    for (const name of names) {
      const abs = join(dir, name);
      const rel = prefix ? `${prefix}/${name}` : name;
      const st = lstatOrNull(abs);
      if (!st) continue;
      if (st.isDirectory()) walk(abs, rel);
      else if (st.isFile()) map.set(rel, { hash: lfHash(readNoFollow(abs)) });
      else map.set(rel, { link: true });
    }
  };
  walk(top, "");
  return map;
}

// fileLines: the changed:, missing: and unlisted: lines, sorted by path.
function fileLines(top, files) {
  const found = walkCopy(top);
  const out = [];
  const report = (kind, rel) => out.push([rel, `${kind}: ${COPY}/${clean(rel)}`]);
  for (const [rel, entry] of found) {
    const listed = files.get(rel);
    if (entry.link) {
      report("changed", rel);
    } else if (listed !== undefined) {
      if (listed !== entry.hash) report("changed", rel);
    } else if (!(TOP_SKIP.has(rel) || ANY_SKIP.has(rel.split("/").pop()))) {
      report("unlisted", rel);
    }
  }
  for (const rel of files.keys()) {
    if (!found.has(rel)) report("missing", rel);
  }
  out.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  return out.map(([, line]) => line);
}

// ownBuild: each release.yml entry matches the same path under src/, and git
// tracks no source file that release.yml lacks, except component.yml.
function ownBuild(root, files) {
  if (projectKind(root).kind !== "framework source") return false;
  // 0000041 P5 F-08: no inherited repo or config override, and no fsmonitor.
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_CONFIG_COUNT", "GIT_CONFIG_PARAMETERS"].includes(key)
      || key.startsWith("GIT_CONFIG_KEY_") || key.startsWith("GIT_CONFIG_VALUE_")) delete env[key];
  }
  let tracked;
  try {
    tracked = execFileSync("git", ["-c", "core.fsmonitor=false", "-C", root, "ls-files", "-z", "--", SRC_REL], {
      env, stdio: ["ignore", "pipe", "ignore"], maxBuffer: 64 * 1024 * 1024,
    }).toString("utf-8").split("\0").filter(Boolean);
  } catch {
    return false;
  }
  for (const path of tracked) {
    const rel = path.slice(SRC_REL.length + 1);
    if (rel !== "component.yml" && !files.has(rel)) return false;
  }
  for (const [rel, hash] of files) {
    const parts = rel.split("/");
    let walked = join(root, SRC_REL);
    for (const part of parts) {
      walked = join(walked, part);
      const st = lstatOrNull(walked);
      if (!st || st.isSymbolicLink()) return false;
    }
    try {
      if (lfHash(readNoFollow(walked)) !== hash) return false;
    } catch {
      return false;
    }
  }
  return true;
}

function parseArgs(argv) {
  let root = process.cwd();
  let filesOnly = false;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--root" && i + 1 < argv.length) { root = argv[++i]; continue; }
    if (argv[i] === "--files-only") { filesOnly = true; continue; }
    const name = String(argv[i]).startsWith("-") ? clean(String(argv[i]).split("=")[0].slice(0, 40)) : `argument ${i + 1}`;
    throw new Refusal(`unknown argument ${name}`);
  }
  return { root: resolve(root), filesOnly };
}

function main() {
  const { root, filesOnly } = parseArgs(process.argv.slice(2));
  const out = [];
  const print = (l) => out.push(l);

  const top = join(root, COPY);
  const topStat = lstatOrNull(top);
  if (!topStat) throw new Refusal(`no ${COPY}/ at the root`);
  if (topStat.isSymbolicLink()) throw new Refusal(`${COPY}/ is a link`);
  if (!topStat.isDirectory()) throw new Refusal(`${COPY}/ is not a folder`);

  const relText = readRegular(root, `${COPY}/release.yml`);

  if (filesOnly) {
    if (relText === null) {
      print(`skipped: no ${COPY}/release.yml`);
      return { out, code: 0 };
    }
    const { files } = parseRelease(relText);
    const fl = fileLines(top, files);
    return { out: fl, code: fl.length ? 1 : 0 };
  }

  const recText = readRegular(root, RECORD_REL);
  const recorded = recText === null ? null : parseRecord(recText);
  const about = recorded ? null : aboutVersion(root);

  let release = null;
  let version;
  if (relText !== null) {
    release = parseRelease(relText);
    version = release.version;
    print(`release: version "${version}" source-commit "${release.commit}"`);
  } else {
    const compText = readRegular(root, `${COPY}/component.yml`);
    if (compText === null) throw new Refusal(`${COPY}/ holds neither release.yml nor component.yml`);
    version = quotedVersion(compText);
    if (!VERSION_RE.test(version)) throw new Refusal(`${COPY}/component.yml has no MAJOR.MINOR.PATCH version`);
    print(`release: none, fallback component.yml version "${version}"`);
  }

  if (recorded) print(`recorded: version "${recorded.version}" source-commit "${recorded.commit}"`);
  else if (about) print(`recorded: none, fallback docs/about.md version "${clean(about)}"`);
  else print("recorded: none");

  // A recorded value proves a release.yml was trusted once (0000041 P5 F-02).
  // The component.yml fallback then never applies, and a missing release.yml
  // is a release update.
  if (recorded && !release) {
    print(`missing: ${COPY}/release.yml`);
    print("update: release");
    return { out, code: 1 };
  }

  // A full comparison needs a recorded value and a release.yml. Every other
  // case compares the version only.
  let isRelease;
  if (recorded) isRelease = recorded.version !== version || recorded.commit !== release.commit;
  else if (about) isRelease = about !== version;
  else isRelease = true;

  let fl = [];
  if (release) fl = fileLines(top, release.files);
  else print("files: not checked, no release.yml");
  for (const l of fl) print(l);

  let update = isRelease ? "release" : "none";
  if (isRelease && release && fl.length === 0 && ownBuild(root, release.files)) update = "own-build";
  print(`update: ${update}`);

  if (release && (!recorded || recorded.version !== release.version || recorded.commit !== release.commit)) {
    print(`record: version "${release.version}" source-commit "${release.commit}"`);
  }
  if (release && lstatOrNull(join(top, "component.yml"))) {
    print(`warn: ${COPY}/component.yml sits beside release.yml`);
  }

  return { out, code: update === "release" || fl.length ? 1 : 0 };
}

// process.exitCode, not process.exit(), so a piped stdout drains in full.
try {
  const { out, code } = main();
  process.stdout.write(out.map((l) => `${l}\n`).join(""));
  process.exitCode = code;
} catch (e) {
  const msg = e instanceof Refusal ? e.message : `unexpected error: ${clean(e?.code ?? e?.name ?? "error")}`;
  process.stderr.write(`release-check: ${msg}\n`);
  process.exitCode = 2;
}
