// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFreeWorld {
    event FWCTokensMinted(uint256 amount);

    /**
     * @dev The total supply of the token is now capped at 3 trillion tokens.
     */
    error FWCMaxSupplyCapped();

    /**
     * @dev The total supply of the token cannot exceed 3 trillion tokens.
     * @param amount The amount of tokens to mint.
     */
    error FWCMintExceedsMaxSupply(uint256 amount);

    /**
     * @dev The price paid for minting is not enough.
     */
    error FWCMintPriceNotMet(uint256 amount);

    /**
     * @dev The amount of tokens to mint is less than the minimum.
     */
    error FWCMinSupplyPerMintNotMet(uint256 amount);

    /**
     * @dev The amount of tokens to mint is more than the maximum.
     */
    error FWCMaxSupplyPerMintExceeded(uint256 amount);


    function mintTo(address to, uint256 amount) external payable;
    function mint(uint256 amount) external payable;
}
