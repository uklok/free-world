//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFreeWorldRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FreeWorldRegistry is IFreeWorldRegistry, ERC721, Ownable {
    mapping(address => bool) private registered;
    mapping(address => bool) private verified;
    mapping(address => bool) private minted;

    uint256 private _nextTokenId;

    constructor(address initialOwner) ERC721("Free World Registry", "FWR") Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

// ---------------------------------------------------------------------------------------------------------------------
    modifier verifiedUser(address userAddress) {
        if(!verified[userAddress]) {
            revert NotVerifiedUser(userAddress);
        }

        _;
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev User Registration
     * @notice Anyone could register but only once.
     *
     * TODO: @notice The user must be able to provide a correlated verifiable address for verification.
     * TODO: @notice The user must be able to change the address used for verification only after 30 days of the last change.
     */
     // TODO: @param verifiableAddress The address used for verification.
    function register() external {
        address userAddress = tx.origin;
        if (registered[userAddress]) {
            revert AlreadyRegisteredUser(userAddress);
        }

        registered[userAddress] = true;
        emit UserRegistered(userAddress);
    }

    /**
     * @dev User Un-registration
     * @notice Anyone could unregister but only once.
     *
     */
    function unregister() external {
        address userAddress = tx.origin;
        if (!registered[userAddress]) {
            revert NotRegisteredUser(userAddress);
        }

        registered[userAddress] = false;
        emit UserUnregistered(userAddress);
    }


    /**
     * @dev User Verification
     *
     * @notice Everyone must be verified before it can perform any action.
     * TODO: @notice The verification process is done by making the user sign a message using the address already verified on another chain/contract (PoH, PolygonId, ...).
     *
     * @param verifiedAddress The address of the user already verified.
     */
    function verify(address verifiedAddress) external onlyOwner {
        // TODO: As a different address for verification could be used, the mapping should be changed to `address` the registered address.
        address to = verifiedAddress;

        if (!registered[to]) {
            revert NotRegisteredUser(to);
        }

        if (verified[to]) {
            revert AlreadyVerifiedUser(to);
        }

        verified[to] = true;
        emit UserVerified(to);

        _safeMint(to, _nextTokenId++);
        minted[to] = true;
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev User Verification
     *
     * @notice Everyone must be verified before it can perform any action.
     */
    function isRegistered(address userAddress) external view returns (bool) {
        return registered[userAddress];
    }

    function isVerified(address userAddress) external view returns (bool) {
        return verified[userAddress];
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev Transfer is disabled. (override ERC721)
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        if (from != address(0)) {
            revert TokenTransferNotAllowed(tokenId);
        }

        super.transferFrom(from, to, tokenId);
    }
}