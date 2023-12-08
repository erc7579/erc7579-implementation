// SPDX-License-Identifier: MIT

import "src/utils/Bootstrap.sol";
import "src/interfaces/IModule.sol";

contract BootstrapUtil {
    Bootstrap bootstrapSingleton;

    constructor() {
        bootstrapSingleton = new Bootstrap();
    }

    function _makeBootstrapConfig(
        address module,
        bytes memory data
    )
        public
        pure
        returns (BootstrapConfig memory config)
    {
        config.module = IModule(module);
        config.data = abi.encodeCall(IModule.enable, data);
    }

    function makeBootstrapConfig(
        address module,
        bytes memory data
    )
        public
        pure
        returns (BootstrapConfig[] memory config)
    {
        config = new BootstrapConfig[](1);
        config[0].module = IModule(module);
        config[0].data = abi.encodeCall(IModule.enable, data);
    }

    function makeBootstrapConfig(
        address[] memory modules,
        bytes[] memory datas
    )
        public
        pure
        returns (BootstrapConfig[] memory configs)
    {
        configs = new BootstrapConfig[](modules.length);

        for (uint256 i; i < modules.length; i++) {
            configs[i] = _makeBootstrapConfig(modules[i], datas[i]);
        }
    }
}
