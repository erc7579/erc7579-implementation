// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct taddress {
    address __value;
}

library TransientCacheLib {
    function set(taddress storage self, address value) public {
        assembly {
            tstore(self.slot, value)
        }
    }

    function get(taddress storage self) public returns (address value) {
        assembly {
            value := tload(self.slot)
        }
    }
}
