// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IFreeWorld.sol";
import {IFreeWorldUserRegistry} from "./interfaces/IFreeWorldUserRegistry.sol";
import {IFreeWorldElectionRegistry} from "./interfaces/IFreeWorldElectionRegistry.sol";
import "./FreeWorldUserRegistry.sol";
import "./FreeWorldElectionRegistry.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FreeWorld is IFreeWorld, ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant ELECTION_REGISTRY = keccak256("ELECTION_REGISTRY");
    bytes32 public constant USERS_REGISTRY = keccak256("USERS_REGISTRY");

    uint256 public constant MINT_PRICE = 0.00001 ether;
    uint256 public constant MAX_SUPPLY = 3_000_000_000 ether;
    uint256 public constant MIN_SUPPLY_PER_MINT = 300 ether;
    uint256 public constant MAX_SUPPLY_PER_MINT = 3_000_000 ether;
    uint256 private _totalMinted = 0;

    uint256 public constant CREATE_FWO_FEE = MIN_SUPPLY_PER_MINT / 3;
    uint256 public constant UPDATE_FWO_FEE = MIN_SUPPLY_PER_MINT / 6;
    uint256 public constant REMOVE_FWO_FEE = MIN_SUPPLY_PER_MINT / 12;

    FreeWorldUserRegistry public immutable users;
    FreeWorldElectionRegistry public immutable elections;

    mapping(address => uint256) public activeElections;
    address[] public deployedElections;

    constructor(address defaultAdmin, address _users, address _elections)
    ERC20("Free World", "FWC")
    ERC20Permit("Free World")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        users = _users != address(0) ? FreeWorldUserRegistry(_users) : new FreeWorldUserRegistry(address(this));
        elections = _elections != address(0) ? FreeWorldElectionRegistry(_elections) : new FreeWorldElectionRegistry(address(this));

        _grantRole(ELECTION_REGISTRY, address(elections));
    }
// ---------------------------------------------------------------------------------------------------------------------
    modifier verifiedUser() {
        address userAddress = _msgSender();
        if (!users.isVerified(userAddress)) {revert IFreeWorldUserRegistry.NotVerifiedUser(userAddress);}
        _;
    }

    modifier validElection(uint256 tokenId) {
        address userAddress = _msgSender();
        uint256 activeTokenId = activeElections[userAddress];

        if (elections.ownerOf(tokenId) != userAddress) { revert IFreeWorldElectionRegistry.FWOUnauthorizedUser(tokenId, userAddress); }
        if (activeTokenId == 0) { revert IFreeWorldElectionRegistry.FWONoActiveElection(); }
        if (activeTokenId != tokenId) { revert IFreeWorldElectionRegistry.FWOInvalidTokenId(tokenId); }

        _;
    }
// ---------------------------------------------------------------------------------------------------------------------
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
        if (msg.value != cost) {revert FWCMintPriceNotMet(msg.value);}

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

    function _mintWhenCostMet(uint256 amount) internal {
        uint256 creationCost = amount * MINT_PRICE / 1 ether;

        if (msg.value == creationCost) { mint(amount); }
    }

// ---------------------------------------------------------------------------------------------------------------------
    function verifyUser(address userAddress) public onlyRole(getRoleAdmin(USERS_REGISTRY)) {
        users.verify(userAddress);
    }

// ---------------------------------------------------------------------------------------------------------------------
    function createElection(bytes calldata data, bytes calldata signature, string memory uri) public payable verifiedUser returns (uint256, uint256) {
        address userAddress = _msgSender();
        uint256 activeTokenId = activeElections[userAddress];
        if (activeTokenId != 0) {
            IFreeWorldElectionRegistry.FWOToken memory token = elections.tokenDetails(activeTokenId);
            if (token.status == IFreeWorldElectionRegistry.FWOStatus.COMPLETED
                || token.status == IFreeWorldElectionRegistry.FWOStatus.REMOVED) {
                delete activeElections[userAddress];
            } else {
                revert IFreeWorldElectionRegistry.FWOActiveElectionAlreadyExists(activeTokenId);
            }
        }

        _mintWhenCostMet(MIN_SUPPLY_PER_MINT);
        transfer(address(elections), CREATE_FWO_FEE);

        (uint256 deploymentCost, uint256 tokenId) = elections.create(data, signature, uri);
        activeElections[userAddress] = tokenId;

        return (deploymentCost, tokenId);
    }

    function updateElection(uint256 currentTokenId, bytes calldata data, bytes calldata signature, string memory uri) public payable validElection(currentTokenId) returns (uint256, uint256) {
        _mintWhenCostMet(MIN_SUPPLY_PER_MINT);
        transfer(address(elections), UPDATE_FWO_FEE);

        (uint256 deploymentCost, uint256 tokenId) = elections.update(currentTokenId, data, signature, uri);
        activeElections[_msgSender()] = tokenId;

        return (deploymentCost, tokenId);
    }

    function removeElection(uint256 tokenId) public payable validElection(tokenId) {
        _mintWhenCostMet(MIN_SUPPLY_PER_MINT);
        transfer(address(elections), REMOVE_FWO_FEE);

        elections.remove(tokenId);
        delete activeElections[_msgSender()];
    }

    function deployElection(uint256 tokenId) public payable validElection(tokenId) returns (address) {
        IFreeWorldElectionRegistry.FWOToken memory token = elections.tokenDetails(tokenId);

        // TODO: Allow the user to mint only what it left to reach the cost of the election.
        // (cost - balance) > MIN_SUPPLY_PER_MINT ? (cost - balance) : MIN_SUPPLY_PER_MINT
        _mintWhenCostMet(token.cost * 3 * 1 ether);
        transfer(address(elections), token.cost);

        address electionAddress = elections.deploy(tokenId);
        deployedElections.push(electionAddress);

        return electionAddress;
    }

    /**
     * @dev Updates the active election local mapping.
     *
     * @notice This function is called by the `FreeWorldElectionRegistry` contract.
     *
     * @param tokenId FWO token of the election.
     * @param from The address of the previous owner.
     * @param to The address of the new owner.
     */
    function electionTransferred(uint256 tokenId, address from, address to) public onlyRole(ELECTION_REGISTRY) {
        IFreeWorldElectionRegistry.FWOToken memory token = elections.tokenDetails(tokenId);

        // Only active elections can be transferred.
        if (token.status == IFreeWorldElectionRegistry.FWOStatus.CREATED) {
            delete activeElections[from];
            activeElections[to] = tokenId;
        }
    }

    function getDeploymentCost(uint256 tokenId) public view validElection(tokenId) returns (uint256) {
        IFreeWorldElectionRegistry.FWOToken memory token = elections.tokenDetails(tokenId);
        return token.cost;
    }

}
