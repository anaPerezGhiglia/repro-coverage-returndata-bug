// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";
import { Reverter, CustomError } from "../contracts/Reverter.sol";
import { UnsafeForwarder } from "../contracts/UnsafeForwarder.sol";
import { SafeForwarder } from "../contracts/SafeForwarder.sol";

/// @notice Reproduces a Hardhat 3 coverage bug where coverage instrumentation
/// injects calls to 0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE that overwrite
/// the EVM returndata buffer. Any code that relies on returndatasize() /
/// returndatacopy() after a .call() reads stale data under --coverage.
contract CoverageReturndataBugTest is Test {
    Reverter reverter;
    UnsafeForwarder unsafeForwarder;
    SafeForwarder safeForwarder;

    function setUp() public {
        reverter = new Reverter();
        unsafeForwarder = new UnsafeForwarder();
        safeForwarder = new SafeForwarder();
    }

    /// @notice FAILS under --coverage. Uses returndatasize/returndatacopy
    /// in inline assembly — the returndata buffer gets overwritten by
    /// the coverage instrumentation call.
    function test_UnsafeForward_RevertsWithCustomError() public {
        vm.expectRevert(CustomError.selector);
        unsafeForwarder.forward(
            address(reverter),
            abi.encodeCall(Reverter.doRevert, ())
        );
    }

    /// @notice PASSES under --coverage. Captures returndata into bytes memory
    /// so it survives instrumentation calls that overwrite the returndata buffer.
    function test_SafeForward_RevertsWithCustomError() public {
        vm.expectRevert(CustomError.selector);
        safeForwarder.forward(
            address(reverter),
            abi.encodeCall(Reverter.doRevert, ())
        );
    }
}
