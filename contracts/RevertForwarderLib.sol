// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @dev Minimal library that forwards revert data using returndatasize/returndatacopy.
/// This is the standard pattern used by many projects (e.g. 1inch RevertReasonForwarder).
library RevertForwarderLib {
    function reRevert() internal pure {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}
