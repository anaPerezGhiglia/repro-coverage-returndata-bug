// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @dev Forwards a call and re-reverts via inline assembly. PASSES under --coverage.
contract InlineForwarder {
    function forward(address target, bytes calldata data) external {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = target.call(data);
        if (!success) {
            assembly ("memory-safe") {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}
