# Bug: Coverage instrumentation overwrites the EVM returndata buffer

## Summary

Hardhat 3's `--coverage` flag injects calls to `0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE` for tracking code coverage. These calls overwrite the EVM returndata buffer, breaking any code that relies on `returndatasize()` / `returndatacopy()` after a low-level `.call()`.

This is a common Solidity pattern for forwarding revert reasons (used by 1inch, OpenZeppelin, and others).

## Environment

- Hardhat `^3.1.12`
- Solidity `0.8.23` (reproduces with default compiler settings)

## Reproduction

```bash
pnpm install
pnpm test               # Both tests PASS
pnpm run test:coverage   # UnsafeForwarder FAILS, SafeForwarder PASSES
```

### Expected behavior

Both tests pass. Each forwarder calls a target contract that reverts with `CustomError()`, then re-reverts with the original revert data.

### Actual behavior

Under `--coverage`, the variant that uses `returndatasize()` / `returndatacopy()` fails:

```
  ✔ test_SafeForward_RevertsWithCustomError()
  1) test_InlineForward_RevertsWithCustomError()

  Error: Error != expected error:
    call to non-contract address 0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE != CustomError()
```

The `SafeForwarder` — which captures returndata into `bytes memory` before the instrumentation can interfere — passes.

## Root cause

Coverage instrumentation injects calls between Solidity statements to track which lines are executed. When an instrumentation call lands between a `.call()` and a subsequent `returndatasize()` / `returndatacopy()` in inline assembly, it **overwrites the EVM returndata buffer**. The assembly then reads the (empty) return data from the instrumentation call instead of the original revert reason.

The `SafeForwarder` avoids this by capturing returndata into `bytes memory` via Solidity's built-in decoding (`(bool success, bytes memory returnData) = target.call(data)`), which copies the returndata buffer into memory as part of the same compiler-generated sequence, before any instrumentation is injected.

## Contracts

| File | Description |
|------|-------------|
| `contracts/Reverter.sol` | Target that always reverts with `CustomError()` |
| `contracts/UnsafeForwarder.sol` | Re-reverts via `returndatasize`/`returndatacopy` — **FAILS** under coverage |
| `contracts/SafeForwarder.sol` | Captures returndata into `bytes memory` — **PASSES** under coverage |
| `test/CoverageReturndataBug.t.sol` | Forge-style test demonstrating the bug |
