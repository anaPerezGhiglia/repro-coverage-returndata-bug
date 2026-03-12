// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";
import { Reverter, CustomError } from "../contracts/Reverter.sol";
import { LibForwarder } from "../contracts/LibForwarder.sol";
import { InlineForwarder } from "../contracts/InlineForwarder.sol";

/// @notice Reproduces a Hardhat 3 coverage bug where coverage instrumentation
/// injects calls to 0xc0bEc0BEc0BeC0bEC0beC0bEC0bEC0beC0beC0BE inside library
/// functions, overwriting the EVM returndata buffer. This causes returndatasize()
/// and returndatacopy() to return stale data instead of the original revert reason.
///
/// The library variant (LibForwarder) FAILS under --coverage.
/// The inline variant (InlineForwarder) PASSES under --coverage.
contract CoverageReturndataBugTest is Test {
    Reverter reverter;
    LibForwarder libForwarder;
    InlineForwarder inlineForwarder;

    function setUp() public {
        reverter = new Reverter();
        libForwarder = new LibForwarder();
        inlineForwarder = new InlineForwarder();
    }

    /// @notice FAILS under --coverage. Uses library function — coverage injects
    /// a call to 0xc0bE..c0BE at the library function entry, overwriting returndata.
    function test_LibraryForward_RevertsWithCustomError() public {
        vm.expectRevert(CustomError.selector);
        libForwarder.forward(
            address(reverter),
            abi.encodeCall(Reverter.doRevert, ())
        );
    }

    /// @notice PASSES under --coverage. Same logic inlined — no library boundary
    /// means no instrumentation call between .call() and returndatacopy.
    function test_InlineForward_RevertsWithCustomError() public {
        vm.expectRevert(CustomError.selector);
        inlineForwarder.forward(
            address(reverter),
            abi.encodeCall(Reverter.doRevert, ())
        );
    }
}
