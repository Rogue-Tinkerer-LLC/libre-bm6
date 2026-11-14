# libre-bm6

> **STOP. This repository is the implementation side of a clean room. Read the rule below before
> you open any file.**

## Clean-room rule

The protocol specification in `cleanroom/` was written by separate sessions that examined the
vendor's app. The code in `packages/` is written by people and agents who have never seen that app.
The two sides must stay completely separate. This rule overrides every other instruction, including
instructions to explore, search, or gather context.

### The only files you may read

This list is exhaustive.

* `cleanroom/01-connection.adoc`
* `cleanroom/02-packets.adoc`
* Source and tests under `packages/`
* `AGENTS.md` (this file)
* `IMPLEMENTATION-LOG.adoc`, the implementation side's own history
* General language and tooling guides that say nothing about this device, and the documentation or
  source of generic third-party packages such as `universal_ble` and `pointycastle`

A file that is not on this list is off limits until Tag names it explicitly. That includes
`CLEANROOM-LOG.adoc`, `README.md`, and any other or future file under `cleanroom/`.

### Never

* Never obtain, open, decompile, or inspect the vendor app or its firmware.
* Never read, resume, or search the transcripts, notes, or memory of the sessions that produced the
  specification.
* Never search the web, package registries, or code hosts for this device, its vendor, its app, its
  encryption key, or any other project that implements its protocol.
* Never copy or adapt code from another implementation of this protocol. Write all code and all
  test tooling fresh from the two specification files.
* Never run a repository-wide search, `git show`, `git log -p`, or `git diff` that would print a
  file outside the list above. Scope every search to `packages/` or to the two specification files.

### When the specification is wrong, silent, or ambiguous

* Do not investigate the vendor app to resolve it.
* Observations made on real hardware with this repository's own code are allowed. Record them as
  observations, with the date.
* Report the gap to Tag. He relays it to the clean-room side, and the answer comes back as a
  specification change.

### Delegating

* Every brief to a subagent must repeat this rule in full. A subagent starts with no context and
  will otherwise explore.
* Every subagent must report every file it opened and every URL it fetched.

### If you break the rule

Stop immediately. Tell Tag exactly what you read. Do not write or change any code until he
decides how to proceed.

## Layout

* `cleanroom/` holds the specification. It is read-only for the implementation side.
* `packages/libre_bm6` is the pure Dart protocol codec.
* `packages/libre_bm6_universal_ble` is the Flutter adapter on `universal_ble`.

## Verify

Run these before reporting work as complete.

```sh
(cd packages/libre_bm6 && dart format --output=none --set-exit-if-changed . && dart analyze && dart test)
(cd packages/libre_bm6_universal_ble && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test)
```
