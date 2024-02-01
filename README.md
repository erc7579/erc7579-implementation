# ERC-7579 Reference Implementation

Reference Implementation to Minimal Modular Smart Account ([ERC-7579](https://eips.ethereum.org/EIPS/eip-7579)).

## Security Note

The contracts in this repository are - at this point - not audited. We advice against using this in production.

## Credits

- Validator Encoding in Signature: MSA_ValidatorInSignature is inspiried by [taek's (ZeroDev) Kernel](https://github.com/zerodevapp/kernel/blob/main/src/Kernel.sol)

- [Validator Encoding in Nonce](./src/uMSABasic.sol): Implementation of validator encoding in userOp nonce is inspired by [ross' (Nani) Account](https://github.com/NaniDAO/accounts/blob/65b08c39ca2859ddec35472ba4698b0d446f84ea/src/Account.sol#L27C1-L68)

- [Fallback Manager](./src/core/ModuleManager.sol): Fallback Manager is inspiried by [Richard's (Safe)](https://github.com/safe-global/safe-contracts/blob/main/contracts/base/FallbackManager.sol) Fallback Manager

## Authors ✨

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="http://twitter.com/zeroknotsETH/"><img src="https://pbs.twimg.com/profile_images/1639062011387715590/bNmZ5Gpf_400x400.jpg" width="100px;" alt=""/><br /><sub><b>zeroknots (rhinestone)</b></sub></a><br /><a href="https://github.com/zeroknots" title="Spec">📝</a></td>

<td align="center"><a href="https://twitter.com/abstractooor"><img src="https://avatars.githubusercontent.com/u/26718079" width="100px;" alt=""/><br /><sub><b>Konrad (rhinestone)</b></sub></a><br /><a href="https://github.com/kopy-kat" title="Spec">📝</a> </td>

<td align="center"><a href="https://twitter.com/leekt216"><img src="https://avatars.githubusercontent.com/u/15259621" width="100px;" alt=""/><br /><sub><b>taek (ZeroDev)</b></sub></a><br /><a href="https://github.com/leekt" title="Spec">📝</a> </td>

<td align="center"><a href="https://twitter.com/filmakarov"><img src="https://avatars.githubusercontent.com/u/3930375" width="100px;" alt=""/><br /><sub><b>filmakarov (Biconomy)</b></sub></a><br /><a href="https://github.com/filmakarov" title="Spec">📝</a> </td>

<td align="center"><a href="https://twitter.com/YaonamP"><img src="https://avatars.githubusercontent.com/u/43309015" width="100px;" alt=""/><br /><sub><b>Elim (OKX)</b></sub></a><br /><a href="https://github.com/yaonam" title="Spec">📝</a> </td>

<td align="center"><a href=""><img src="https://avatars.githubusercontent.com/u/49302884" width="100px;" alt=""/><br /><sub><b>Lyu (OKX)</b></sub></a><br /><a href="https://github.com/rockmin216" title="Spec">📝</a> </td>

  </tr>
</table>
