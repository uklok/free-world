// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IFreeWorld.sol";
import "./FreeWorldRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "hardhat/console.sol";

contract FreeWorld is IFreeWorld, ERC20, ERC20Burnable, AccessControl, ERC20Permit {
//    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MINT_PRICE = 0.00001 ether;
    uint256 public constant MAX_SUPPLY = 3_000_000_000 ether;
    uint256 public constant MIN_SUPPLY_PER_MINT = 300 ether;
    uint256 public constant MAX_SUPPLY_PER_MINT = 3_000_000 ether;
    uint256 private _totalMinted = 0;

    FreeWorldRegistry public immutable registry;

    constructor(address defaultAdmin, address _registry)
    ERC20("Free World", "FWC")
    ERC20Permit("Free World")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        registry = _registry != address(0) ? FreeWorldRegistry(_registry): new FreeWorldRegistry(address(this));
    }

    /**
     * @dev Returns the total minted tokens.
     */
    function totalMinted() public view virtual returns (uint256) {
        return _totalMinted;
    }

    /**
     * @dev Every time a user mints, 2/3 of the tokens are burned.
     *
     * @notice This process is irreversible.
     * @notice The goal is to reduce the total supply of the token over time. This will increase the value of the token.
     *
     * @param to The address of the user.
     * @param amount The amount of tokens to mint.
     */
    function mintTo(address to, uint256 amount) public payable {
        uint cost = amount * MINT_PRICE / 1 ether;

        if (_totalMinted == MAX_SUPPLY) {revert FWCMaxSupplyCapped();}
        if (_totalMinted + amount > MAX_SUPPLY) {revert FWCMintExceedsMaxSupply(MAX_SUPPLY - _totalMinted);}
        if (amount < MIN_SUPPLY_PER_MINT) {revert FWCMinSupplyPerMintNotMet(MIN_SUPPLY_PER_MINT);}
        if (amount > MAX_SUPPLY_PER_MINT) {revert FWCMaxSupplyPerMintExceeded(MAX_SUPPLY_PER_MINT);}
        if (msg.value != cost) {revert FWCMintPriceNotMet(cost - msg.value);}

        _mint(to, amount);

        _totalMinted += amount;
        _burn(to, amount * 2 / 3);
    }

    /**
     * @dev Mint tokens for the caller.
     *
     * @notice This function is a wrapper for the `mintTo` function.
     *
     * @param amount The amount of tokens to mint.
     */
    function mint(uint256 amount) public payable {
        mintTo(_msgSender(), amount);
    }
}
