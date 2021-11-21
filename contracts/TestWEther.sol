// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WEther is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, 10000000);
    }
}
