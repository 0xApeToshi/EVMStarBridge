// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "./DAOController.sol";
import "./IERC20Delivery.sol";

contract ERC20Delivery is DAOController, ERC20Capped {
    event AdminUpdate(address indexed admin);
    // ========== Public variables ==========
    address public admin;

    constructor(
        address _DAO_MULTISIG,
        string memory _name,
        string memory _symbol,
        uint256 _cap
    ) DAOController(_DAO_MULTISIG) ERC20(_name, _symbol) ERC20Capped(_cap) {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function configAdmin(address _admin) external onlyDAO {
        admin = _admin;
        emit AdminUpdate(_admin);
    }

    function mint(address account, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {
        _burn(account, amount);
        return true;
    }
}
