// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { SentinelListLib, SENTINEL } from "sentinellist/SentinelList.sol";
import {
    CallType, CALLTYPE_SINGLE, CALLTYPE_DELEGATECALL, CALLTYPE_STATIC
} from "../lib/ModeLib.sol";
import { AccountBase } from "./AccountBase.sol";
import "../interfaces/IERC7579Module.sol";
import "forge-std/interfaces/IERC165.sol";
import "./Receiver.sol";

/**
 * @title ModuleManager
 * @author zeroknots.eth | rhinestone.wtf
 * @dev This contract manages Validator, Executor and Fallback modules for the MSA
 * @dev it uses SentinelList to manage the linked list of modules
 * NOTE: the linked list is just an example. accounts may implement this differently
 */
abstract contract ModuleManager is AccountBase, Receiver {
    using SentinelListLib for SentinelListLib.SentinelList;

    error InvalidModule(address module);
    error NoFallbackHandler(bytes4 selector);
    error CannotRemoveLastValidator();

    event ValidatorUninstallFailed(address validator, bytes data);
    event ExecutorUninstallFailed(address executor, bytes data);

    // forgefmt: disable-next-line
    // keccak256(abi.encode(uint256(keccak256("modulemanager.storage.msa")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 internal constant MODULEMANAGER_STORAGE_LOCATION =
        0xe3a55571e8f241b58442871487cc151a8cb048bb4ad24e833467f724ec89a900;

    struct FallbackHandler {
        address handler;
        CallType calltype;
    }

    /// @custom:storage-location erc7201:modulemanager.storage.msa
    struct ModuleManagerStorage {
        // linked list of validators. List is initialized by initializeAccount()
        SentinelListLib.SentinelList $valdiators;
        // linked list of executors. List is initialized by initializeAccount()
        SentinelListLib.SentinelList $executors;
        // single fallback handler for all fallbacks
        // account vendors may implement this differently. This is just a reference implementation
        mapping(bytes4 selector => FallbackHandler fallbackHandler) $fallbacks;
    }

    function $moduleManager() internal pure virtual returns (ModuleManagerStorage storage $ims) {
        bytes32 position = MODULEMANAGER_STORAGE_LOCATION;
        assembly {
            $ims.slot := position
        }
    }

    modifier onlyExecutorModule() {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        if (!$executors.contains(msg.sender)) revert InvalidModule(msg.sender);
        _;
    }

    modifier onlyValidatorModule(address validator) {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        if (!$valdiators.contains(validator)) revert InvalidModule(validator);
        _;
    }

    function _initModuleManager() internal virtual {
        ModuleManagerStorage storage $ims = $moduleManager();
        $ims.$executors.init();
        $ims.$valdiators.init();
    }

    function isAlreadyInitialized() internal view virtual returns (bool) {
        ModuleManagerStorage storage $ims = $moduleManager();
        return $ims.$valdiators.alreadyInitialized();
    }

    /////////////////////////////////////////////////////
    //  Manage Validators
    ////////////////////////////////////////////////////
    function _installValidator(address validator, bytes calldata data) internal virtual {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        $valdiators.push(validator);
        IValidator(validator).onInstall(data);
    }

    function _uninstallValidator(address validator, bytes calldata data) internal {
        // TODO: check if its the last validator. this might brick the account
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        $valdiators.pop(prev, validator);
        IValidator(validator).onUninstall(disableModuleData);
    }

    /*
    function _tryUninstallValidators(bytes[] calldata data) internal {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        uint256 length = data.length;
        uint256 index;
        address validator = $valdiators.getNext(SENTINEL);
        while (validator != SENTINEL) {
            bytes memory uninstallData;
            if (index < length) {
                uninstallData = data[index];
            }
            try IValidator(validator).onUninstall(uninstallData) {} catch {
                emit ValidatorUninstallFailed(validator, uninstallData);
            }
            validator = $valdiators.getNext(validator);
            index++;
        }
        $valdiators.popAll();
    }
    */

    function _tryUninstallValidators() internal {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        address validator = $valdiators.getNext(SENTINEL);
        while (validator != SENTINEL) {
            try IValidator(validator).onUninstall("") { }
            catch {
                emit ValidatorUninstallFailed(validator, "");
            }
            validator = $valdiators.getNext(validator);
        }
        $valdiators.popAll();
    }

    function _isValidatorInstalled(address validator) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        return $valdiators.contains(validator);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getValidatorsPaginated(
        address cursor,
        uint256 size
    )
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage $valdiators = $moduleManager().$valdiators;
        return $valdiators.getEntriesPaginated(cursor, size);
    }

    /////////////////////////////////////////////////////
    //  Manage Executors
    ////////////////////////////////////////////////////

    function _installExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        $executors.push(executor);
        IExecutor(executor).onInstall(data);
    }

    function _uninstallExecutor(address executor, bytes calldata data) internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        (address prev, bytes memory disableModuleData) = abi.decode(data, (address, bytes));
        $executors.pop(prev, executor);
        IExecutor(executor).onUninstall(disableModuleData);
    }

    /*
    function _tryUninstallExecutors(bytes[] calldata data) internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        uint256 length = data.length;
        uint256 index;
        address executor = $executors.getNext(SENTINEL);
        while (executor != SENTINEL) {
            bytes memory uninstallData;
            if (index < length) {
                uninstallData = data[index];
            }
            try IExecutor(executor).onUninstall(uninstallData) {} catch {
                emit ExecutorUninstallFailed(executor, uninstallData);
            }
            executor = $executors.getNext(executor);
            index++;
        }
        $executors.popAll();
    }
    */

    function _tryUninstallExecutors() internal {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        address executor = $executors.getNext(SENTINEL);
        while (executor != SENTINEL) {
            try IExecutor(executor).onUninstall("") { }
            catch {
                emit ExecutorUninstallFailed(executor, "");
            }
            executor = $executors.getNext(executor);
        }
        $executors.popAll();
    }

    function _isExecutorInstalled(address executor) internal view virtual returns (bool) {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        return $executors.contains(executor);
    }

    /**
     * THIS IS NOT PART OF THE STANDARD
     * Helper Function to access linked list
     */
    function getExecutorsPaginated(
        address cursor,
        uint256 size
    )
        external
        view
        virtual
        returns (address[] memory array, address next)
    {
        SentinelListLib.SentinelList storage $executors = $moduleManager().$executors;
        return $executors.getEntriesPaginated(cursor, size);
    }

    /////////////////////////////////////////////////////
    //  Manage Fallback
    ////////////////////////////////////////////////////

    function _installFallbackHandler(address handler, bytes calldata params) internal virtual {
        bytes4 selector = bytes4(params[0:4]);
        CallType calltype = CallType.wrap(bytes1(params[4]));
        bytes memory initData = params[5:];

        if (_isFallbackHandlerInstalled(selector)) {
            revert("Function selector already used");
        }
        $moduleManager().$fallbacks[selector] = FallbackHandler(handler, calltype);
        IFallback(handler).onInstall(initData);
    }

    function _uninstallFallbackHandler(
        address handler,
        bytes calldata deInitData
    )
        internal
        virtual
    {
        bytes4 selector = bytes4(deInitData[0:4]);
        bytes memory _deInitData = deInitData[4:];

        if (!_isFallbackHandlerInstalled(selector)) {
            revert("Function selector not used");
        }

        FallbackHandler memory activeFallback = $moduleManager().$fallbacks[selector];

        if (activeFallback.handler != handler) {
            revert("Function selector not used by this handler");
        }

        $moduleManager().$fallbacks[selector] = FallbackHandler(address(0), CallType.wrap(0x00));

        IFallback(handler).onUninstall(_deInitData);
    }

    function _isFallbackHandlerInstalled(bytes4 functionSig) internal view virtual returns (bool) {
        FallbackHandler storage $fallback = $moduleManager().$fallbacks[functionSig];
        return $fallback.handler != address(0);
    }

    function _isFallbackHandlerInstalled(
        bytes4 functionSig,
        address _handler
    )
        internal
        view
        virtual
        returns (bool)
    {
        FallbackHandler storage $fallback = $moduleManager().$fallbacks[functionSig];
        return $fallback.handler == _handler;
    }

    function getActiveFallbackHandler(bytes4 functionSig)
        external
        view
        virtual
        returns (FallbackHandler memory)
    {
        return $moduleManager().$fallbacks[functionSig];
    }

    // FALLBACK
    fallback() external payable override(Receiver) receiverFallback {
        FallbackHandler storage $fallbackHandler = $moduleManager().$fallbacks[msg.sig];
        address handler = $fallbackHandler.handler;
        CallType calltype = $fallbackHandler.calltype;
        if (handler == address(0)) revert NoFallbackHandler(msg.sig);

        if (calltype == CALLTYPE_STATIC) {
            assembly {
                function allocate(length) -> pos {
                    pos := mload(0x40)
                    mstore(0x40, add(pos, length))
                }

                let calldataPtr := allocate(calldatasize())
                calldatacopy(calldataPtr, 0, calldatasize())

                // The msg.sender address is shifted to the left by 12 bytes to remove the padding
                // Then the address without padding is stored right after the calldata
                let senderPtr := allocate(20)
                mstore(senderPtr, shl(96, caller()))

                // Add 20 bytes for the address appended add the end
                let success :=
                    staticcall(gas(), handler, calldataPtr, add(calldatasize(), 20), 0, 0)

                let returnDataPtr := allocate(returndatasize())
                returndatacopy(returnDataPtr, 0, returndatasize())
                if iszero(success) { revert(returnDataPtr, returndatasize()) }
                return(returnDataPtr, returndatasize())
            }
        }
        if (calltype == CALLTYPE_SINGLE) {
            assembly {
                function allocate(length) -> pos {
                    pos := mload(0x40)
                    mstore(0x40, add(pos, length))
                }

                let calldataPtr := allocate(calldatasize())
                calldatacopy(calldataPtr, 0, calldatasize())

                // The msg.sender address is shifted to the left by 12 bytes to remove the padding
                // Then the address without padding is stored right after the calldata
                let senderPtr := allocate(20)
                mstore(senderPtr, shl(96, caller()))

                // Add 20 bytes for the address appended add the end
                let success := call(gas(), handler, 0, calldataPtr, add(calldatasize(), 20), 0, 0)

                let returnDataPtr := allocate(returndatasize())
                returndatacopy(returnDataPtr, 0, returndatasize())
                if iszero(success) { revert(returnDataPtr, returndatasize()) }
                return(returnDataPtr, returndatasize())
            }
        }
    }
}
