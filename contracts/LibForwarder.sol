// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { RevertForwarderLib } from "./RevertForwarderLib.sol";

/// @dev Forwards a call and re-reverts via library function. FAILS under --coverage.
contract LibForwarder {
    function forward(address target, bytes calldata data) external {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = target.call(data);
        if (!success) RevertForwarderLib.reRevert();
    }
}
