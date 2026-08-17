---
name: moonrepo
description: Work in a moonrepo monorepo — discover projects and tasks, run and debug them, read the action graph, and diagnose caching and task-dependency defects in moon.yml. Use when the repository contains a .moon directory, or the user asks how to run tasks, debug caching, or read the task graph in a moonrepo monorepo.
---

You are invoked via the `/moonrepo` skill. Use it when a repository contains a `.moon/`
directory. It tells you how to discover what exists, how to run it, and where moon
configurations commonly go wrong.

Verified against **moon 2.5**. Check `moon --version` first; moon 1.x differs (see the
Version differences section).

---

## Step 1 — Discover before you run

Never guess a task name. Ask moon.

```bash
moon --version
moon projects                 # every project, its source path, its toolchains
moon tasks                    # every task, grouped by project
moon project <name>           # one project: language, layer, deps, tasks
moon task <project>:<task>    # one task: command, deps, inputs, outputs, runs-in-CI
```

Machine-readable versions, better for filtering:

```bash
moon query projects
moon query tasks
moon query tasks --affected
moon query changed-files
```

A target is always `project:task`. `#tag:task` runs every project with that tag, and `:task`
runs that task in every project that defines it.

---

## Step 2 — Run

```bash
moon run app:build              # one task
moon run app:build web:build    # several
moon run :test                  # this task in every project
moon check app                  # every build and test task for one project
moon check --all                # the whole workspace
moon ci                         # what CI runs: affected tasks only
```

Useful flags:

```bash
moon run app:test -- -k test_name     # everything after -- passes to the underlying command
moon run app:build --force            # ignore the cache
moon run app:build --updateCache      # write the cache, do not read it
moon run :build --concurrency 1       # serialise, to read the output
moon run app:build --log debug        # verbose moon-level logging
MOON_CACHE=off moon run app:build     # disable caching for this run
```

`moon setup` installs the toolchains declared in `.moon/toolchain.yml`. `moon sync` repairs
project references and dependency links. `moon clean` removes stale cache artifacts.

---

## Step 3 — Read the graphs when order looks wrong

```bash
moon action-graph                 # what will actually execute, in order
moon action-graph app:build       # for one target
moon project-graph                # project dependency graph
moon task-graph                   # task dependency graph
```

These open an interactive view. Add `--dot` for text output you can read or diff.

To find out why a cached result was or was not reused:

```bash
moon run app:build --log debug    # prints the computed hash
moon hash <hash>                  # show what went into that hash
moon hash <hash-a> <hash-b>       # diff two hashes — shows exactly which input changed
```

`moon hash` diffing is the fastest way to prove a caching defect. It tells you the input that
moved, or shows that nothing moved when something should have.

---

## Configuration files

| File | Purpose |
|---|---|
| `.moon/workspace.yml` | Project list or globs, version control, runner settings |
| `.moon/toolchain.yml` | Pinned versions of node, package manager, python, rust |
| `.moon/tasks.yml` | Tasks inherited by every project |
| `.moon/tasks/<lang>.yml` | Tasks inherited by projects of one language |
| `<project>/moon.yml` | That project's layer, language, dependencies, and tasks |

A minimal `moon.yml`:

```yaml
layer: 'library'          # moon 2.x. In moon 1.x this key is `type`.
language: 'typescript'
dependsOn:
  - 'shared'
tasks:
  build:
    command: 'tsc -p tsconfig.json'
    inputs: ['src/**/*', 'tsconfig.json']
    outputs: ['dist']
    deps: ['shared:build']
    options:
      runInCI: true
```

---

## Step 4 — Diagnose the common defects

These are the moon defects worth hunting in a code review. Each one is quiet: the build reports
success while doing the wrong thing.

### Missing `deps` — wrong order, works by luck

A task consumes another project's output but does not declare `deps`. It passes locally because
the output is still on disk from an earlier run, and fails on a cold clone or in CI.

Detect it: `moon clean && moon run <target>` on a fresh checkout, and compare `dependsOn` in
`moon.yml` against the imports the code actually makes.

### Incomplete `inputs` — stale cache, shipped

The sharpest defect of all. A task reads a file that is absent from `inputs`. Changing that file
does not change the hash, so moon replays a cached result and the build ships stale output while
reporting success.

Detect it: change a file the task truly depends on, run the task, and confirm the hash changed.
If moon reports a cache hit, `inputs` is wrong. Confirm with `moon hash <a> <b>`.

Common omissions: `tsconfig.json`, `.env` files, generated protobuf or GraphQL clients, shared
configuration outside the project directory, and lockfiles.

### Over-broad `inputs` — the cache never hits

`inputs: ['**/*']` includes the output directory, so every run changes its own inputs. The task
rebuilds every time. Slow, but not incorrect.

### Missing `outputs` — nothing is cached

Without `outputs`, moon has nothing to restore, so a cache hit still reruns the work and
downstream tasks cannot consume the artifact.

### `runInCI: false` on a task that guards correctness

Type checks and tests marked `runInCI: false` never run in `moon ci`. The pipeline goes green
while nothing is verified. Check every task's `runInCI` against what it does.

### Swallowed exit codes

A `command` written as a shell chain ending in `|| true`, or a script that exits 0 regardless,
makes a failing task look successful.

### Toolchain drift

`.moon/toolchain.yml` pins one Node or Python version, while CI and the Dockerfile use another.
Everything works locally and fails in CI, or worse, passes both and behaves differently.

---

## Traps

- **moon needs at least one commit.** In a repository with none, every command fails with
  `fatal: ambiguous argument 'HEAD'`. Commit first.
- **`layer` replaced `type` in moon 2.x.** A `moon.yml` using `type:` fails to parse on 2.x with
  `unknown field 'type'`.
- **moon manages its own toolchain through proto.** The binary it runs may not be the one on
  your `PATH`. `moon bin node` prints the resolved path, and `moon task <target>` lists the
  lookup paths.
- **`moon ci` only runs affected tasks**, computed from a git revision range. It can legitimately
  run nothing. That is not a passing build.
- **Cache state hides defects.** When you audit, always test cold: `moon clean` first, or
  `MOON_CACHE=off`.
- **moon ships an MCP server** — `moon mcp` — that answers project and task queries directly.

## Version differences

| Concern | moon 1.x | moon 2.x |
|---|---|---|
| Project kind key | `type:` | `layer:` |
| Config location | `.moon/workspace.yml` | same |
| Toolchain plugins | built in | plugin based, `moon toolchain` |

Read `.moon/workspace.yml` and run `moon --version` before you trust any syntax. When the
repository pins a moon version, match it rather than upgrading.
