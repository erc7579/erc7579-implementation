import "../interfaces/IERC7579Account.sol";

library HookOffsetLib {
    function offset() internal pure returns (uint256 offset) {
        bytes4 functionSig = bytes4(msg.data[:4]);
        if (
            functionSig == IERC7579Account.execute.selector
                || functionSig == IERC7579Account.executeFromExecutor.selector
        ) {
            return 100 + uint256(bytes32(msg.data[68:100]));
        }

        if (
            functionSig == IERC7579Account.installModule.selector
                || functionSig == IERC7579Account.uninstallModule.selector
        ) {
            return 132 + uint256(bytes32(msg.data[100:132]));
        } else {
            return msg.data.length;
        }
    }
}
