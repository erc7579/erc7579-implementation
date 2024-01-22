import "../interfaces/IModule.sol";
import "../interfaces/IMSA.sol";
import "../lib/ModeLib.sol";

contract SimpleExecutionValidator is IValidator {
    error InvalidExec();

    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}

    function isModuleType(uint256 typeID) external view override returns (bool) {}

    function validateUserOp(IERC4337.UserOperation calldata userOp, bytes32 userOpHash)
        external
        override
        returns (uint256)
    {
        bytes4 execFunction = bytes4(userOp.callData[:4]);
        if (execFunction != IMSA.execute.selector) revert InvalidExec();
        bytes32 mode = bytes32(userOp.callData[4:36]);
        // if (callType == CALLTYPE_BATCH) {
        //     Execution[] calldata executions = executionCalldata.decodeBatch();
        // } else if (callType == CALLTYPE_SINGLE) {
        //     (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
        // }
    }

    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
        external
        view
        override
        returns (bytes4)
    {}
}
