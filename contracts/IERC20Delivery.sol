// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20Delivery {
    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);
}
