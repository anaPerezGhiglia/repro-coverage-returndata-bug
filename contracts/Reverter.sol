// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

error CustomError();

/// @dev Target contract that always reverts with a custom error.
contract Reverter {
    function doRevert() external pure {
        revert CustomError();
    }
}
