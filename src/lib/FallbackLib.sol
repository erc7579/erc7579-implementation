import { RData } from "EIP7702Storage/RDataLib.sol";
import { CallType } from "src/lib/ModeLib.sol";

struct FallbackHandler {
    address handler;
    CallType calltype;
}

library FallbackStorage {
    using RData for RData.Bytes;

    function load(RData.Bytes storage self)
        internal
        view
        returns (FallbackHandler memory handler)
    {
        bytes memory handlerEncoded = self.load();
        if (handlerEncoded.length != 0) {
            handler = abi.decode(handlerEncoded, (FallbackHandler));
        }
    }

    function store(RData.Bytes storage self, FallbackHandler memory handler) internal {
        self.store(abi.encode(handler));
    }

    function remove(RData.Bytes storage self) internal {
        self.store("");
    }
}
