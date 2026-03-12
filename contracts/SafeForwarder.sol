// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @dev Forwards a call and re-reverts by capturing returndata into bytes memory.
/// This avoids relying on the returndata buffer surviving between statements.
contract SafeForwarder {
    function forward(address target, bytes calldata data) external {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}
