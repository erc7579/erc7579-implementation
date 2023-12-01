import "./IERC4337.sol";
import "./IMiniMSA.sol";
import "./core/Execution.sol";

contract MSA is Execution, IERC4337, IMSA {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        override
    {
        bytes calldata userOpSignature;
        uint256 userOpEndOffset;
        assembly {
            userOpEndOffset := add(calldataload(0x04), 0x24)
            userOpSignature.offset := add(calldataload(add(userOpEndOffset, 0x120)), userOpEndOffset)
            userOpSignature.length := calldataload(sub(userOpSignature.offset, 0x20))
        }
    }

    /////////////////////////////////////////////////////
    // Access Control
    ////////////////////////////////////////////////////

    modifier onlyEntryPoint() virtual {
        if (msg.sender != entryPoint()) revert Unauthorized();
        _;
    }

    function entryPoint() public view virtual returns (address) {
        return 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    }

    /////////////////////////////////////////////////////
    // Executions
    ////////////////////////////////////////////////////
    function execute(address target, uint256 value, bytes calldata callData)
        external
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _execute(target, value, callData);
    }

    function executeDelegateCall(address target, bytes calldata callData)
        external
        override
        onlyEntryPoint
        returns (bytes memory result)
    {
        return _executeDelegatecall(target, callData);
    }

    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata callDatas)
        external
        override
        onlyEntryPoint
    {}

    function executeFromModule(address target, uint256 value, bytes calldata callData)
        external
        override
        onlyExecutorModule
        returns (bool, bytes memory)
    {}

    function executeBatchFromModule(address[] calldata target, uint256[] calldata value, bytes[] calldata callDatas)
        external
        override
        onlyExecutorModule
        returns (bool, bytes memory)
    {}

    function executeDelegateCallFromModule(address target, bytes memory callData)
        external
        override
        onlyExecutorModule
        returns (bool, bytes memory)
    {
        revert Unsupported();
    }

    /////////////////////////////////////////////////////
    // Account Management
    ////////////////////////////////////////////////////

    function setupModule(address validator) external onlyEntryPoint {}
}
