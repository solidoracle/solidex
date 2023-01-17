pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Solids is ERC20 {
    constructor() ERC20("Solids", "SLD") {
        _mint(msg.sender, 0.1 ether);
    }
}
