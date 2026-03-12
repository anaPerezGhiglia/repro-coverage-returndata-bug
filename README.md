# Bug: Coverage instrumentation overwrites returndata buffer in library functions

## Summary

Hardhat 3's `--coverage` instrumentation injects calls to `0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE` for tracking code coverage. When these instrumentation calls are injected into a **library function** that uses `returndatasize()` / `returndatacopy()` in inline assembly, the injected call overwrites the EVM returndata buffer, causing the assembly to read stale/wrong data.

This breaks the common Solidity pattern of forwarding revert reasons via inline assembly after a failed low-level `.call()`.

## Environment

- Hardhat `^3.1.12`
- Solidity `0.8.23` with `viaIR: true`, optimizer runs: 1,000,000

## Reproduction

```bash
pnpm install
pnpm test             # Both tests PASS
pnpm run test:coverage  # Library variant FAILS
```

### Expected behavior

Both tests pass — the `LibForwarder` (library-based) and `InlineForwarder` (inline assembly) should behave identically. Both forward a call to a contract that reverts with `CustomError()` and then re-revert with the original revert data.

### Actual behavior

Under `--coverage`, the library variant fails:

```
Error: Error != expected error: call to non-contract address 0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE != CustomError()
```

The inline variant passes.

## Root cause

Coverage instrumentation injects calls to `0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE` to track which lines are executed. When this injection happens inside a library function that relies on `returndatasize()` / `returndatacopy()`, the injected call **overwrites the EVM's returndata buffer**. The subsequent `returndatacopy` then reads the result of the instrumentation call instead of the original revert data.

The inline variant works because the instrumentation is not injected between the `.call()` and the assembly block when they're in the same function — but when the assembly is in a separate library function, the instrumentation gets injected at the library function entry point, before `returndatasize()` is read.

## Key insight

The bug is specific to **library functions** containing `returndatasize()` / `returndatacopy()` in inline assembly. The same assembly inlined directly in the calling contract does not exhibit the bug.

## Contracts

| File | Description |
|------|-------------|
| `contracts/RevertForwarderLib.sol` | Library with `reRevert()` — uses `returndatasize`/`returndatacopy` |
| `contracts/LibForwarder.sol` | Calls the library — **FAILS** under coverage |
| `contracts/InlineForwarder.sol` | Same logic inlined — **PASSES** under coverage |
| `contracts/Reverter.sol` | Target that reverts with `CustomError()` |
| `test/CoverageReturndataBug.t.sol` | Forge-style test demonstrating the bug |

## Suggested fix

Coverage instrumentation should not inject calls that modify the returndata buffer inside functions that use `returndatasize()` / `returndatacopy()` in inline assembly. Alternatively, the instrumentation could save and restore the returndata buffer around its tracking calls.
