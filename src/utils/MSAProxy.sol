// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "src/lib/Initializable.sol";

contract MSAProxy is Proxy {
    constructor(address implementation, bytes memory _data) payable {
        Initializable.setInitializable();
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
