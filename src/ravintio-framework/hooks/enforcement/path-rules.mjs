/**
 * Shared path rules for the write gates (req-006, ADR-004).
 *
 * gate-write.mjs and the Bash shell guard both import this module, so they
 * judge every path the same way. Neither hook keeps a copy of these rules.
 *
 * PLACEMENT (0000028-ADR-002): this module lives in hooks/enforcement/. Every
 * install that copies gate-write.mjs copies every *.mjs in this folder, so the
 * import always resolves.
 *
 * Constraints (ADR-004):
 *   - Node built-in modules only, and no process spawn.
 *   - The repository root is the nearest folder that holds
 *     ravintio-framework/, else the nearest that holds .git. The walk starts
 *     at CLAUDE_PROJECT_DIR when it names a folder and finds a marker, and
 *     at cwd otherwise. With no marker, the root is cwd.
 *     A marker inside plan/ or docs/ of a higher marked folder never counts,
 *     because those prefixes are always permitted and anyone can plant one.
 *     Nor does a marker with an always-permitted basename, such as
 *     claude.md, in its path below a higher marked folder (0000035 ADR-008).
 *     A cwd that no longer exists walks up to its nearest existing folder
 *     (0000035 ADR-006).
 *   - Both sides of the root comparison are real paths. A target resolves
 *     one segment at a time through symbolic links, with a 40-hop limit, and
 *     a resolution error for a path inside the root blocks (0000035 ADR-005).
 *     The Write and Edit gates also judge the target with .. collapsed as
 *     text first, as those tools place it, and block if either verdict
 *     blocks (G-S01). The shell guard keeps the physical walk only.
 *   - plan/.orchestrator-active and plan/current/design.md are looked up
 *     from the root, not from cwd.
 *   - Comparisons use the 0000009-ADR-005 normalisation: forward slashes and
 *     lower case.
 *
 * Exports:
 *   resolveRoot(cwd)                 real repository root, or null if cwd is unusable
 *   resolveTarget(root, cwd, target) { status: inside | outside | unresolvable } for a target
 *   resolveTargetBoth(root, cwd, target) the physical and text placements, deduplicated
 *   hookCwd(input)                   the folder a hook judges from, or null
 *   evaluateWrite(root, relPath)     { allowed, reason?, warning? } for a root-relative path
 *   judgeWrite(cwd, target)          resolveRoot, resolveTarget, and evaluateWrite in one call
 *   unjudgeable(base, target)        a warning when the path is too long to judge, or null
 *   norm(p)                          the shared comparison normalisation
 *   shown(p, max)                    p with control characters escaped, cut to max, for a reason (G-S11)
 *   isEnforcementPath(relPath)       whether ENFORCEMENT_PATHS covers relPath
 *   ENFORCEMENT_PATHS                paths where a permitted file name gets no shortcut (0000040 ADR-004)
 */

import {
  closeSync, constants as fsConstants, existsSync, fstatSync, lstatSync, openSync, readlinkSync, readSync,
  realpathSync, statSync,
} from "node:fs";
import { dirname, isAbsolute, join, normalize, parse, relative, resolve, sep } from "node:path";

// Always-permitted: planning and doc artefacts and RAVINTIO internal files.
export const ALWAYS_PERMITTED_PREFIXES = ["plan/", "docs/"];
export const ALWAYS_PERMITTED_FILES = [
  "claude.md", "agents.md", ".ravintio-session", ".skips", ".feature-id",
  ".gitignore", ".gitattributes", ".claudeignore", ".cursorignore",
  ".windsurfignore", ".clineignore", ".cursorindexingignore",
  "pause.md",
];

// Headings that introduce the component paths list in design.md (0000003-ADR-004).
const PATHS_SECTION_RE = /^##\s+(Component Paths|Scope)\s*$/im;

// Folders whose presence marks a repository root (ADR-004).
const ROOT_MARKERS = ["ravintio-framework", ".git"];

const SENTINEL_REASON =
  "[RAVINTIO] No orchestrator sentinel at plan/.orchestrator-active. " +
  "Load the ravintio-orchestrator skill and complete Phase 0 before " +
  "writing plan artefacts.\n";
const NO_DESIGN_REASON =
  "[RAVINTIO] No confirmed design at plan/current/design.md. " +
  "Complete Phase 0 first.\n";
const NOT_REGULAR_LINE =
  "[RAVINTIO] plan/current/design.md is not a regular file, so the gate treats it as no design.\n";
const OVERSIZE_LINE =
  "[RAVINTIO] plan/current/design.md is over the 1 MiB size cap, so the gate treats it as no design.\n";
const UNPARSEABLE_WARNING =
  "[RAVINTIO] Warning: Could not parse component paths from " +
  "plan/current/design.md. Ensure a '## Component Paths' section exists. " +
  "Write allowed.\n";

// Paths past these limits are too long to judge. Resolving one through the
// file system can take tens of seconds, which outlasts the hook timeout (F7).
export const MAX_PATH_CHARS = 4096;
export const MAX_PATH_SEGMENTS = 256;

const tooLong = (p) =>
  p.length > MAX_PATH_CHARS || p.split(/[\\/]+/).length > MAX_PATH_SEGMENTS;

/**
 * A one-line warning when target, resolved against base, is over
 * MAX_PATH_CHARS characters or MAX_PATH_SEGMENTS segments. The limits apply
 * to the resolved path, so a long raw path that normalises to a short one is
 * judged (N-3). Returns null for a path the rules can judge. Resolving is
 * string work only and makes no file-system call.
 */
export function unjudgeable(base, target) {
  if (typeof target !== "string") return null;
  const resolved = typeof base === "string" ? resolve(base, target) : normalize(target);
  if (!tooLong(resolved)) return null;
  return (
    `[RAVINTIO] Warning: the path '${shown(target, 80)}...' is too long to judge ` +
    `(over ${MAX_PATH_CHARS} characters or ${MAX_PATH_SEGMENTS} segments). Write allowed.\n`
  );
}

export function norm(p) {
  return normalize(p).replace(/\\/g, "/").toLowerCase();
}

/**
 * p as a block reason prints it: each control or format character escaped,
 * as \n, \r, \t, \xNN, or \u{XXXX}, and the result cut to at most max
 * characters between whole escapes and code points. A
 * target that holds a newline can't then forge a second line of hook output
 * (G-S11). A bidirectional control can't reorder the text on display (G-N3).
 */
// C0 and C1 controls with DEL (Cc), format characters such as the
// bidirectional controls U+202A to U+202E and U+2066 to U+2069 (Cf), and the
// Unicode line and paragraph separators (Zl, Zp).
const CONTROL_RE = /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/gu;

const escapeControl = (c) => {
  if (c === "\n") return "\\n";
  if (c === "\r") return "\\r";
  if (c === "\t") return "\\t";
  const code = c.codePointAt(0);
  const hex = code.toString(16).toUpperCase();
  return code > 0xff ? `\\u{${hex.padStart(4, "0")}}` : `\\x${hex.toLowerCase().padStart(2, "0")}`;
};

// The cut falls only between whole units: one escape or one code point. The
// output never ends inside an escape or a surrogate pair (0000036 ADR-004).
export function shown(p, max = 80) {
  let out = "";
  for (const c of String(p)) {
    const unit = c.replace(CONTROL_RE, escapeControl);
    if (out.length + unit.length > max) break;
    out += unit;
  }
  return out;
}

function isDirectory(p) {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
}

// A path resolution error: realpathSync failed on a path the walk reached.
// code is the error code, and reached is the real path the walk got to before
// the error, with the rest of the path appended as text (0000035 ADR-005).
class ResolutionError extends Error {
  constructor(code, reached) {
    super(code);
    this.code = code;
    this.reached = reached;
  }
}

// nearestExisting: walks up from the absolute path p with statSync to the
// nearest path that exists, or the nearest folder when wantFolder is set.
// Only ENOENT and ENOTDIR count as missing. Any other error, such as EACCES,
// stops the walk at that path, so a permission error can't move the result
// (0000035 ADR-006). Returns { stop, missing }, where missing holds the
// segments below stop, nearest first.
function nearestExisting(p, wantFolder = false) {
  const missing = [];
  let current = p;
  for (;;) {
    try {
      const stats = statSync(current);
      if (!wantFolder || stats.isDirectory()) return { stop: current, missing };
    } catch (err) {
      if (err?.code !== "ENOENT" && err?.code !== "ENOTDIR") return { stop: current, missing };
    }
    const parent = dirname(current);
    if (parent === current) return { stop: current, missing };
    missing.unshift(relative(parent, current));
    current = parent;
  }
}

// The most links one resolution follows, the Linux MAXSYMLINKS value
// (0000035 ADR-005).
export const MAX_LINK_HOPS = 40;

const segmentsOf = (p) => p.split(/[\\/]+/).filter(Boolean);

/**
 * realPathOf: the real path the absolute path p names, found one segment at
 * a time (0000035 ADR-005).
 *   - lstatSync checks each existing segment. A link puts its text in place
 *     of the segment. Relative text resolves against the link's real folder,
 *     and absolute text restarts the walk at its own root.
 *   - A .. moves to the real parent of the path resolved so far. It never
 *     collapses as text before the segments to its left resolve.
 *   - From the first ENOENT or ENOTDIR, the rest of the path appends as text,
 *     with any .. among it collapsed. A dangling link resolves to its target.
 * Throws a ResolutionError for a link loop, a chain past MAX_LINK_HOPS, a
 * path past the length limits after a substitution, or any other error.
 * p is never collapsed as text first, so it must not pass through resolve().
 */
function realPathOf(p) {
  let resolved = parse(p).root;
  let pending = segmentsOf(p.slice(resolved.length));
  let hops = 0;
  let chain = new Set(); // links followed since the last ordinary segment
  const fail = (code, rest) => new ResolutionError(code, join(resolved, ...rest));

  while (pending.length) {
    const segment = pending.shift();
    if (segment === ".") continue;
    if (segment === "..") {
      resolved = dirname(resolved); // resolved is real, so this is its real parent
      continue;
    }
    const next = join(resolved, segment);
    let stats;
    try {
      stats = lstatSync(next);
    } catch (err) {
      if (err?.code === "ENOENT" || err?.code === "ENOTDIR") return join(next, ...pending);
      throw fail(err?.code ?? "an unknown error", [segment, ...pending]);
    }
    if (!stats.isSymbolicLink()) {
      resolved = next;
      chain = new Set();
      continue;
    }
    if (chain.has(next)) throw fail("link loop", [segment, ...pending]);
    chain.add(next);
    hops += 1;
    if (hops > MAX_LINK_HOPS) throw fail(`more than ${MAX_LINK_HOPS} links`, [segment, ...pending]);
    let text;
    try {
      text = readlinkSync(next);
    } catch (err) {
      throw fail(err?.code ?? "an unknown error", [segment, ...pending]);
    }
    if (isAbsolute(text)) {
      resolved = parse(resolve(text)).root;
      pending = [...segmentsOf(text.slice(parse(text).root.length)), ...pending];
    } else {
      pending = [...segmentsOf(text), ...pending];
    }
    if (tooLong(join(resolved, ...pending))) throw fail("too long to judge after its links", pending);
  }
  return resolved;
}

// absoluteText: target placed against the real folder base without
// collapsing any .. as text, so realPathOf resolves it as the system would.
const absoluteText = (base, target) => (isAbsolute(target) ? target : base + sep + target);

// planted: whether the marked folder at rel, a path relative to a higher
// marked folder, is distrusted. Its first segment is plan or docs (F1), or
// any of its segments, its own name included, is an always-permitted
// basename such as claude.md (0000035 ADR-008). An agent can plant a marker
// under plan/ and move the folder to src/claude.md, so neither may be a root.
function plantedAt(rel) {
  const segments = norm(rel).split("/");
  if (ALWAYS_PERMITTED_PREFIXES.some((prefix) => prefix === segments[0] + "/")) return true;
  return segments.some((segment) => ALWAYS_PERMITTED_FILES.includes(segment));
}

// markedRoot: the nearest trusted marked folder at or above start, a real
// path, or null when no folder holds a marker. A folder holding
// ravintio-framework/ beats one holding only .git (a .git file counts, for
// worktrees). A folder that sits inside plan/ or docs/ of a higher marked
// folder, or below an always-permitted basename, is never a root (F1,
// 0000035 ADR-008). The walk goes on past a distrusted marker.
function markedRoot(start) {
  // Every marked folder from start up to the file-system root, nearest first.
  const marked = [];
  let dir = start;
  for (;;) {
    const framework = isDirectory(join(dir, "ravintio-framework"));
    const git = existsSync(join(dir, ".git"));
    if (framework || git) marked.push({ dir, framework, git });
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  const planted = (candidate) =>
    marked.some(({ dir: above }) => {
      if (above === candidate.dir) return false;
      const rel = relative(above, candidate.dir);
      if (!rel || rel.startsWith("..") || isAbsolute(rel)) return false;
      return plantedAt(rel);
    });
  const trusted = marked.filter((m) => !planted(m));

  const framework = trusted.find((m) => m.framework);
  if (framework) return framework.dir;
  const git = trusted.find((m) => m.git);
  return git ? git.dir : null;
}

/**
 * The repository root for cwd, as a real path (ADR-004, findings F1, N-4,
 * and N-5).
 *   1. The marked root found by walking up from CLAUDE_PROJECT_DIR, when the
 *      variable names a folder and the walk finds a marker. The variable is a
 *      starting point, never the root itself (N-4). It wins over cwd because
 *      an agent can change cwd with cd but can't change the hook's
 *      environment.
 *   2. The marked root found by walking up from the nearest existing folder
 *      at or above cwd. A cwd that no longer exists still finds its
 *      repository this way (0000035 ADR-006).
 *   3. The real path of that nearest existing folder.
 * Each walk takes the nearest folder holding ravintio-framework/, then the
 * nearest holding .git (N-5). Returns null, and never throws, when cwd is not
 * a non-empty string. It also returns null when the walk from cwd stops at a
 * path whose real path can't be resolved, because no root is then known.
 */
export function resolveRoot(cwd) {
  try {
    if (typeof cwd !== "string" || !cwd) return null;
    const projectDir = process.env.CLAUDE_PROJECT_DIR;
    if (projectDir && isDirectory(projectDir)) {
      const fromProject = markedRoot(realpathSync(projectDir));
      if (fromProject) return fromProject;
    }
    const start = realpathSync(nearestExisting(resolve(cwd), true).stop);
    return markedRoot(start) ?? start;
  } catch {
    return null;
  }
}

// within: the path of abs relative to root, with forward slashes and its
// original case, or null when abs is outside root. Matches whole segments.
function within(root, abs) {
  const normRoot = norm(root).replace(/\/$/, "");
  const normAbs = norm(abs);
  if (normAbs === normRoot) return "";
  const rootPrefix = normRoot + "/";
  if (!normAbs.startsWith(rootPrefix)) return null;
  return abs.replace(/\\/g, "/").slice(rootPrefix.length);
}

/**
 * Resolves target from cwd through every link and places it against root
 * (0000035 ADR-005). Returns one of:
 *   { status: "inside", relPath }       relPath has forward slashes and its original case
 *   { status: "outside" }               outside root, or too long to judge (F7)
 *   { status: "unresolvable", reason }  a resolution error for a path inside root
 * cwd goes through the same resolution, and a relative target resolves
 * against its real path. A resolution error counts as unresolvable when the
 * target as text, or the real path reached before the error, lies inside
 * root. Otherwise the target is outside. The reason shows the first 80
 * characters of target and never prints link text.
 */
export function resolveTarget(root, cwd, target) {
  return placeTarget(root, cwd, target, false);
}

/**
 * Like resolveTarget, but collapses any .. in target as text first, against
 * cwd as given, and then resolves the result through every link (G-S01). The
 * Write and Edit tools place a target this way, so a link before a .. never
 * moves where the write lands. The shell guard keeps resolveTarget, because
 * the kernel runs a shell redirect's .. through links.
 */
function resolveTargetText(root, cwd, target) {
  return placeTarget(root, cwd, target, true);
}

/**
 * Both placements of target from cwd, the physical one first (G-S01). Holds
 * one entry when both land on the same path. The Write and Edit gates judge
 * each entry and block when either verdict blocks.
 */
export function resolveTargetBoth(root, cwd, target) {
  const physical = resolveTarget(root, cwd, target);
  const text = resolveTargetText(root, cwd, target);
  const same =
    physical.status === text.status &&
    (physical.status !== "inside" || norm(physical.relPath) === norm(text.relPath));
  return same ? [physical] : [physical, text];
}

function placeTarget(root, cwd, target, textual) {
  if (typeof target !== "string" || !target || typeof cwd !== "string") return { status: "outside" };
  if (unjudgeable(cwd, target)) return { status: "outside" }; // no slow file-system walk (F7)
  const textAbs = resolve(cwd, target);
  let abs;
  try {
    if (textual) {
      // textAbs holds no .., so only its links resolve. A path below cwd
      // resolves from cwd's real path, so cwd's links don't count as hops.
      const textCwd = resolve(cwd);
      const below = relative(textCwd, textAbs);
      abs = below && !below.startsWith("..") && !isAbsolute(below)
        ? realPathOf(realPathOf(textCwd) + sep + below)
        : realPathOf(textAbs);
    } else {
      const base = realPathOf(isAbsolute(cwd) ? cwd : resolve(cwd));
      abs = realPathOf(absoluteText(base, target));
    }
  } catch (err) {
    if (!(err instanceof ResolutionError)) throw err;
    if (within(root, textAbs) === null && within(root, err.reached) === null) return { status: "outside" };
    return {
      status: "unresolvable",
      reason:
        `[RAVINTIO] Can't resolve the path '${shown(target, 80)}' inside the repository root ` +
        `(${err.code}). Write blocked, because the gate can't judge where it lands.\n`,
    };
  }
  const relPath = within(root, abs);
  return relPath === null ? { status: "outside" } : { status: "inside", relPath };
}

/**
 * The working folder a hook judges from (0000035 ADR-006): the stdin cwd
 * field when it is a non-empty string, then process.cwd(), then
 * CLAUDE_PROJECT_DIR. Returns null when none is usable, and the hook passes.
 */
export function hookCwd(input) {
  if (typeof input?.cwd === "string" && input.cwd) return input.cwd;
  try {
    return process.cwd();
  } catch {
    const projectDir = process.env.CLAUDE_PROJECT_DIR;
    return typeof projectDir === "string" && projectDir ? projectDir : null;
  }
}

// isAlwaysPermitted: a plan/ or docs/ path, or a permitted file name outside
// every enforcement path. A permitted name inside an enforcement path takes
// the normal route, so it can't carry a write past the list (0000036 ADR-003).
function isAlwaysPermitted(relPath) {
  const n = norm(relPath);
  if (ALWAYS_PERMITTED_PREFIXES.some((prefix) => n.startsWith(prefix))) return true;
  const base = n.split("/").pop() ?? "";
  return ALWAYS_PERMITTED_FILES.includes(base) && !isEnforcementPath(relPath);
}

function extractComponentPaths(content) {
  const match = PATHS_SECTION_RE.exec(content);
  if (!match) return null;

  const afterHeading = content.slice(match.index + match[0].length);
  const paths = [];

  for (const line of afterHeading.split("\n")) {
    if (/^##\s/.test(line)) break; // stop at the next h2
    // Match "- path", "* path", "- `path`", and "| path |" table rows.
    const m = line.match(/^[\s*\-|]+`?([^\s`|,{}]+)`?/);
    if (m?.[1] && !m[1].startsWith("{") && m[1].includes("/")) {
      paths.push(m[1].replace(/\/$/, "")); // strip a trailing slash before comparison
    }
  }

  return paths.length ? paths : null;
}

function matchesComponentPath(relPath, componentPaths) {
  const normTarget = norm(relPath);
  return componentPaths.some((cp) => {
    const normCp = norm(cp);
    return normTarget === normCp || normTarget.startsWith(normCp + "/");
  });
}

// ---------------------------------------------------------------------------
// Enforcement paths (0000040 ADR-004)
// ---------------------------------------------------------------------------

// Paths where a permitted file name such as CLAUDE.md gets no shortcut, so
// the write takes the normal design route (0000036 ADR-003). An entry ending
// in / covers that folder and everything below it. Any other plain entry
// covers that file and anything below it. An entry that starts with **/
// matches at any depth: **/name matches a last segment, and **/a/b/ matches
// a segment pair.
export const ENFORCEMENT_PATHS = Object.freeze([
  // Framework enforcement
  "ravintio-framework/hooks/",
  "ravintio-framework/scripts/",
  "ravintio-framework/setup/",
  "ravintio-framework/standards/autonomous-run-standards.md",
  // Setup scripts and every installed hook or adapter folder
  "**/setup.sh",
  "**/setup.ps1",
  "**/hooks/enforcement/",
  "**/hooks/adapters/",
  // Git hooks and config
  ".git/",
  // Hook wiring files that setup.sh and setup.ps1 write
  ".claude/settings.json",
  ".cursor/settings.json",
  ".clinerules/hooks.json",
  ".windsurf/hooks.json",
  ".github/hooks/",
  ".codex/config.toml",
  "opencode.json",
  ".opencode/plugins/@ravintio/opencode-hooks/",
  ".opencode/plugins/@planifest/opencode-hooks/", // old-name read, removed at 1.0.0 (ADR-004)
  // Tool-local settings files, which can also register or turn off hooks
  ".claude/settings.local.json",
  "opencode.jsonc",
  // The CI workflow setup installs, which enforces the source folder rule (0000040 ADR 003)
  ".github/workflows/ravintio.yml",
  ".github/workflows/planifest.yml", // old-name read, removed at 1.0.0 (ADR-004)
]);

// foldWide: norm(p) with NFKC compatibility folding and a full case fold, so
// a lookalike such as the long s (U+017F) meets the plain letter (G-S02).
// APFS folds names this way, so hookſ can name the hooks folder there.
const foldWide = (p) => norm(p).normalize("NFKC").toUpperCase().toLowerCase();

/**
 * Whether relPath matches an entry in ENFORCEMENT_PATHS. Matching compares
 * foldWide(relPath) with foldWide(entry), so it ignores case and
 * compatibility lookalikes.
 */
export function isEnforcementPath(relPath) {
  const target = foldWide(relPath || ".");
  const segments = target.split("/");
  return ENFORCEMENT_PATHS.some((raw) => {
    const entry = foldWide(raw);
    if (entry.startsWith("**/")) {
      const rest = entry.slice(3);
      if (!rest.endsWith("/")) return segments[segments.length - 1] === rest;
      return `/${target}/`.includes(`/${rest}`);
    }
    const bare = entry.replace(/\/$/, "");
    return target === bare || target.startsWith(bare + "/");
  });
}

// O_NONBLOCK keeps a FIFO from holding the open, and O_NOFOLLOW makes the
// open fail on a link swapped in after lstatSync. Windows defines neither.
const DESIGN_OPEN_FLAGS =
  fsConstants.O_RDONLY | (fsConstants.O_NONBLOCK ?? 0) | (fsConstants.O_NOFOLLOW ?? 0);

// The only open or fstat errors that fail open: a permission error on a
// regular file, the accepted mode 000 class (ADR-002, backlog 0000162). Any
// other error means the file changed after lstatSync or isn't one the gate
// can read, such as ELOOP, EMLINK, ENOENT, ENOTDIR, ENXIO, or the macOS
// socket errno -102 (security re-review N-1).
const FAIL_OPEN_ERRORS = new Set(["EACCES", "EPERM"]);

// A larger design.md reads as no design (ADR-002, backlog 0000178).
const DESIGN_MAX_BYTES = 1048576;

// readFdCapped: up to size bytes from fd as UTF-8. The caller keeps size at
// or under DESIGN_MAX_BYTES, so a file that grows after fstatSync can't push
// the read past the cap.
function readFdCapped(fd, size) {
  const buf = Buffer.alloc(size);
  let filled = 0;
  while (filled < size) {
    const n = readSync(fd, buf, filled, size - filled, filled);
    if (n === 0) break;
    filled += n;
  }
  return buf.toString("utf-8", 0, filled);
}

/**
 * readDesign: design.md as the gate sees it (ADR-002). lstatSync runs before
 * any open, so a FIFO or a device is never opened. Returns one of:
 *   { kind: "missing" }      lstatSync threw, such as ENOENT or EACCES
 *   { kind: "non-regular" }  a folder, FIFO, symbolic link, or other type, or
 *                            an open or fstat that threw any error other than
 *                            EACCES or EPERM, such as ELOOP, ENOENT, or ENXIO
 *   { kind: "oversize" }     a regular file over DESIGN_MAX_BYTES
 *   { kind: "unreadable" }   a regular file whose open or fstat threw EACCES
 *                            or EPERM, or whose read threw any error
 *   { kind: "regular", content }
 * The fstatSync on the open descriptor closes the gap between lstatSync and
 * the open. The size check runs before the read.
 */
function readDesign(designPath) {
  let stats;
  try {
    stats = lstatSync(designPath);
  } catch {
    return { kind: "missing" };
  }
  if (!stats.isFile()) return { kind: "non-regular" };
  let fd;
  try {
    let fdStats;
    try {
      fd = openSync(designPath, DESIGN_OPEN_FLAGS);
      fdStats = fstatSync(fd);
    } catch (err) {
      // A link, a socket, or a removal swapped in after lstatSync (security
      // review finding 1, re-review N-1). Only a permission error fails open.
      return FAIL_OPEN_ERRORS.has(err?.code) ? { kind: "unreadable" } : { kind: "non-regular" };
    }
    if (!fdStats.isFile()) return { kind: "non-regular" };
    if (fdStats.size > DESIGN_MAX_BYTES) return { kind: "oversize" };
    return { kind: "regular", content: readFdCapped(fd, fdStats.size) };
  } catch {
    return { kind: "unreadable" };
  } finally {
    if (fd !== undefined) {
      try {
        closeSync(fd);
      } catch {
        // nothing to do: the verdict doesn't depend on the close
      }
    }
  }
}

/**
 * Applies the gate checks, in order, to a root-relative path:
 *   0. the plan/current/** sentinel check, with the feature-brief.md and
 *      always-permitted basename exemptions (0000005-ADR-003)
 *   1. always-permitted prefixes and basenames. A basename counts only when
 *      isEnforcementPath is false for the path (0000036 ADR-003), so such a
 *      name inside an enforcement path goes on to step 2.
 *   2. design.md existence. With no design.md, every write blocks with the
 *      no-design reason (0000040 ADR-002).
 *      A design.md that isn't a regular file, or that lstatSync can't read,
 *      counts as no design. Each block for a non-regular file gains a line
 *      that says so. A design.md over DESIGN_MAX_BYTES also counts as no
 *      design, and each block names the cap. A regular design.md whose open
 *      throws EACCES or EPERM, or whose read throws, fails open. Any other
 *      open or fstat error counts as a non-regular file
 *      (0000036 ADR-002, which narrows 0000003-ADR-005).
 *   3. the component-path check, which warns and allows when design.md has no
 *      parseable paths section
 * Returns { allowed: true }, { allowed: true, warning }, or { allowed: false,
 * reason }. Each string ends with a newline.
 */
export function evaluateWrite(root, relPath) {
  const normRel = norm(relPath || ".");
  const base = normRel.split("/").pop() ?? "";

  const isPlanCurrent = normRel.startsWith("plan/current/") || normRel === "plan/current";
  const isFeatureBrief = normRel.endsWith("feature-brief.md");
  const isAlwaysPermittedBasename = ALWAYS_PERMITTED_FILES.includes(base);
  if (isPlanCurrent && !isFeatureBrief && !isAlwaysPermittedBasename) {
    if (!existsSync(join(root, "plan", ".orchestrator-active"))) {
      return { allowed: false, reason: SENTINEL_REASON };
    }
  }

  if (isAlwaysPermitted(relPath)) return { allowed: true };

  const design = readDesign(join(root, "plan", "current", "design.md"));
  if (design.kind === "missing") return { allowed: false, reason: NO_DESIGN_REASON };
  // The same route as a missing design, and each block says why (ADR-002).
  if (design.kind === "non-regular") return { allowed: false, reason: NO_DESIGN_REASON + NOT_REGULAR_LINE };
  // The same route as a missing design, and each block names the cap (ADR-002).
  if (design.kind === "oversize") return { allowed: false, reason: NO_DESIGN_REASON + OVERSIZE_LINE };
  if (design.kind === "unreadable") return { allowed: true }; // can't read design.md, so fail open (0000003-ADR-005)

  const componentPaths = extractComponentPaths(design.content);
  if (!componentPaths) return { allowed: true, warning: UNPARSEABLE_WARNING };

  if (!matchesComponentPath(relPath, componentPaths)) {
    return {
      allowed: false,
      reason:
        `[RAVINTIO] Path '${shown(relPath, 80)}' is not covered by the confirmed design. ` +
        "Add it to the '## Component Paths' section of plan/current/design.md first.\n",
    };
  }

  return { allowed: true };
}

/**
 * Judges a write to target from cwd. A target outside the repository root,
 * or a cwd that can't be used, returns { allowed: true, outside: true }. A
 * path too long to judge returns { allowed: true, warning } before any
 * file-system walk (F7). A target that can't be resolved inside the root
 * returns { allowed: false, reason } (0000035 ADR-005). Otherwise returns the
 * evaluateWrite result with the root and relPath added. When both placements
 * pass, it carries the warning of each one (G-N2).
 */
export function judgeWrite(cwd, target) {
  const tooLongWarning = typeof cwd === "string" ? unjudgeable(cwd, target) : null;
  if (tooLongWarning) return { allowed: true, warning: tooLongWarning };
  const root = resolveRoot(cwd);
  if (!root) return { allowed: true, outside: true };
  // Judge the physical placement and the text-collapsed one, and block when
  // either blocks (G-S01). An allowed verdict inside the root wins over outside.
  let allowed = null;
  for (const placed of resolveTargetBoth(root, cwd, target)) {
    if (placed.status === "unresolvable") return { allowed: false, reason: placed.reason, root };
    if (placed.status === "outside") continue;
    const { relPath } = placed;
    const verdict = { ...evaluateWrite(root, relPath), root, relPath };
    if (!verdict.allowed) return verdict;
    if (!allowed) {
      allowed = verdict;
      continue;
    }
    // Every placement's warning still prints, even when the other placement
    // is always permitted (G-N2).
    if (verdict.warning && !(allowed.warning ?? "").includes(verdict.warning)) {
      allowed.warning = (allowed.warning ?? "") + verdict.warning;
    }
  }
  return allowed ?? { allowed: true, outside: true };
}
