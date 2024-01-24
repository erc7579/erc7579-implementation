import "../interfaces/IModule.sol";
import "../interfaces/IMSA.sol";
import "../lib/ModeLib.sol";
import "../lib/ExecutionLib.sol";

contract SimpleExecutionValidator is IValidator {
    using ExecutionLib for bytes;

    error InvalidExec();

    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function isModuleType(uint256 typeID) external view override returns (bool) { }

    function validateUserOp(
        IERC4337.UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        override
        returns (uint256)
    {
        // get the function selector that will be called by EntryPoint
        bytes4 execFunction = bytes4(userOp.callData[:4]);

        // get the mode
        CallType callType = CallType.wrap(bytes1(userOp.callData[4]));
        bytes calldata executionCalldata = userOp.callData[36:];
        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) =
                executionCalldata.decodeSingle();
        }
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes4)
    { }
}
