//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IFreeWorldElectionRegistry.sol";
import "./FreeWorld.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FreeWorldElectionRegistry is IFreeWorldElectionRegistry,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CHILD_CONTRACT = keccak256("CHILD_CONTRACT");
    uint256 private _nextTokenId = 1;

    mapping(uint256 => FWOToken) private _tokens;
    FreeWorld private _fwc;

    constructor(address initialOwner) ERC721("Free World Election Registry", "FWO") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function parent() external view returns (address payable) {
        return payable(_fwc);
    }

    function setParent(address payable parentAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _fwc = FreeWorld(parentAddress);
        _grantRole(MANAGER_ROLE, parentAddress);
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev It creates an election using a signed message with all the data needed. only MANAGER_ROLE can call this function.
     *
     * @notice The cost of creating an election is `(MIN_MINT / 3) FWC`. The parent contract must check this.
     * @notice The `msg.sender` must be from a registered and verified user. this verification is done in the parent contract.
     * @notice The user can only have 1 election at a time. In the future when entities are implemented, they could have multiple elections.
     * @notice This will mint an NFT Owner Token (FWO) to the user.
     * @notice This will emit an `ElectionCreated` event.
     *
     * @param data The bytes array containing the JSON.
     * @param signature The signature of the JSON.
     * @param uri The URI of the JSON.
     *
     * @return The cost (FWC) of deploying the election and TokenId of the NFT Owner Token (FWO).
     */
    function create(bytes calldata data, bytes calldata signature, string memory uri) external onlyRole(MANAGER_ROLE) returns (uint256, uint256){
        FWODetails memory details = verify(data, signature);
        address userAddress = tx.origin;

        uint256 tokenId = _nextTokenId++;
        _safeMint(userAddress, tokenId);
        _setTokenURI(tokenId, uri);

        uint256 cost = _getDeployCost(details);

        FWOToken storage token = _tokens[tokenId];
        token.details = details;
        token.status = FWOStatus.CREATED;
        token.contractAddress = address(0);
        token.cost = cost;

        emit FWOCreated(userAddress, tokenId);
        return (cost, tokenId);
    }

    /**
     * @dev It updates an election using a signed message with all the data needed.
     *
     * @notice The cost of updating an election is `(MIN_MINT / 6) FWC` FWC tokens.
     * @notice The FWO must be owned by the msg.sender.
     * @notice The election must not be deployed.
     * @notice The entire JSON will be replaced with the new one. Therefore all the fields must be present.
     * @notice The FWO will be burned and minted again to the msg.sender.
     *
     * @param currentTokenId of the NFT Owner Token (FWO) to be updated.
     * @param data The bytes array containing the JSON.
     * @param signature The signature of the JSON.
     * @param uri The URI of the JSON.
     *
     * @return The new cost (FWC) and TokenId of deploying the election.
     */
    function update(uint256 currentTokenId, bytes calldata data, bytes calldata signature, string memory uri) external onlyRole(MANAGER_ROLE) returns (uint256, uint256){
        if (_tokens[currentTokenId].status != FWOStatus.CREATED) {revert FWOInvalidStatus(currentTokenId);}

        FWODetails memory details = verify(data, signature);
        _tokens[currentTokenId].status = FWOStatus.REMOVED;
        _burn(currentTokenId);

        uint256 tokenId = _nextTokenId++;
        _safeMint(tx.origin, tokenId);
        _setTokenURI(tokenId, uri);

        uint256 cost = _getDeployCost(details);

        FWOToken storage token = _tokens[tokenId];
        token.details = details;
        token.status = FWOStatus.CREATED;
        token.contractAddress = address(0);
        token.cost = cost;

        emit FWOUpdated(msg.sender, tokenId);
        return (cost, tokenId);
    }

    /**
     * @dev It removes an election.
     *
     * @notice The cost of removing an election is `(MIN_MINT / 12) FWC`.
     * @notice The FWO must be owned by the msg.sender.
     * @notice The election must not be deployed.
     * @notice This will emit an `ElectionRemoved` event.
     * @notice This will burn the NFT Owner Token from the user.
     *
     * @param tokenId of the NFT Owner Token (FWO).
     */
    function remove(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        if (_tokens[tokenId].status != FWOStatus.CREATED) {revert FWOInvalidStatus(tokenId);}

        _tokens[tokenId].status = FWOStatus.REMOVED;
        _burn(tokenId);

        emit FWORemoved(msg.sender, tokenId);
    }

    /**
     * @dev It deploys an election.
     *
     * @notice The FWO must be owned by the msg.sender.
     * @notice The election must be in the future.
     * @notice The cost of deploying an election was already computed when the election was created/updated.
     * @notice This will lock the NFT Owner Token (FWO) to the user.
     * @notice The signed message must be a JSON string containing the link to the election data.
     * @notice The data in the link will contain all the context of the election.
     * @notice This will be the entry point for the AI model to fetch the data.
     * @notice This will emit an `ElectionDeployed` event.
     *
     * @param tokenId of the NFT Owner Token (FWO).
     *
     * @return The address of the deployed election contract.
     */
    function deploy(uint256 tokenId) external onlyRole(MANAGER_ROLE) returns (address){
        FWOToken memory token = _tokens[tokenId];
        if (token.status != FWOStatus.CREATED) {revert FWOInvalidStatus(tokenId);}

        // TODO: Deploy the voting module contract.
        // grant CHILD_CONTRACT role to the deployed contract.
        // assign the contract address to the token.
        // transfer the projected cost of the process to the contract.
        // Trigger the CI/CD process to deploy the AI model.
        // Trigger the CI/CD process to deploy the CRON for the COMPLETED status.

        token.status = FWOStatus.DEPLOYED;

        emit FWODeployed(msg.sender, tokenId);
        return token.contractAddress;
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev It returns the address of the deployed election contract.
     *
     * @param tokenId of the NFT Owner Token (FWO).
     *
     * @return The address of the deployed election contract.
     */
    function getElection(uint256 tokenId) external view returns (address){
        ownerOf(tokenId);

        if (_tokens[tokenId].status != FWOStatus.DEPLOYED) { revert FWONotDeployed(tokenId); }
        return _tokens[tokenId].contractAddress;
    }

    /**
     * @dev It verifies the data and signature.
     *
     * @param data The bytes array containing the JSON.
     * @param signature The signature of the JSON.
     *
     * @return The URI of the JSON.
     */
    function verify(bytes calldata data, bytes calldata signature) public view returns (FWODetails memory){
        _isValidSignature(data, signature);
        _isValidData(data);

        // TODO: Generate the Election Struct
        return FWODetails(
            block.timestamp,
            block.timestamp,
            FWOScope.NATIONAL,
            FWOType.CUSTODIAL,
            20_000_000,
            FWOUnit.COUNTRY,
            0,
            FWOMintProcess.MINT_AND_LOCK,
            FWOMintType.ARTISTIC
        );
    }

// ---------------------------------------------------------------------------------------------------------------------
    function _isValidSignature(bytes calldata data, bytes calldata signature) internal pure returns (bool){
        if (data.length == 0 || signature.length == 0) {revert FWOInvalidSignature();}
        // TODO: verify the signature.
        return true;
    }

    /**
     * @dev It verifies the data.
     *
     * @notice The signed message must be a JSON string containing the following fields:
        * - `name`: The name of the election.
        * - `description`: The description of the election.
        * - `start`: The start date of the election.
        * - `end`: The end date of the election.
        * - `scope`: The scope of the election. eg. `local`, `regional`, `national`, `international`.
        * - `type`: The type of the election. eg. `presidential`, `parliamentary`, `regional`, `local`, `referendum`, `other`.
        * - `magnitude`: The number of people involved in the election.
        * - `Unit`: The geopolitical unit of the election. eg. `country`, `region`, `province`, `state`, `city`, `other`.
        * - `UnitId`: The id of the geopolitical unit of the election. eg. `countryId`, `regionId`, `provinceId`, `stateId`, `cityId`, `otherId`.
        * - `mintProcess`: The mint process of the election. eg. `mint`, `mintAndBurn`, `mintAndLock`.
        * - `mintType`: The mint type of the election. eg. `fixed`, `dynamic`, `simple`, `artistic`, ...
     * @notice The election must be in the future.
     * @notice The `start` date min diff from now will depend on the `type`, `scope`, and `magnitude` of the election.
     * @notice The `end` date min diff from `start` will depend on the `type`, `scope`, and `magnitude` of the election.
     * @notice The type of the election must be `other` if the `Unit` is `other`.
     * @notice The `UnitId` must be empty if the `Unit` is `other`.
     *
     * @param data The bytes array containing the JSON.
     *
     * @return True if the data is valid.
     */
    function _isValidData(bytes calldata data) internal pure returns (bool){
        if(data.length == 0) {revert FWOInvalidData();}
        // TODO: Verify data structure and values.
        return true;
    }

    /**
     * @dev It returns the cost of deploying an election.
     *
     * @notice The cost of deploying an election is computed using Chainlink Functions considering the following parameters:
        * - `type`
        * - `scope`
        * - `mintType`
        * - `magnitude`
        * - `UnitId`
     *
     *
     * @param details The details of the election.
     *
     * @return The cost of creating an election.
     */
    function _getDeployCost(FWODetails memory details) internal view returns (uint256){
        // TODO: Compute the cost of deploying an election. The cost will be computed using Chainlink Functions.

        // Compute using Chainlink Functions + Data Feed
        // (fee + gas) of each contract deployment + (fee + gas) of the AI model MINT + (fee + gas) of the CRON
        // ((fee + gas) of a register eligible voter + (fee + gas) of a vote) * magnitude
        // Subtotal * 1.1 (10% for the treasury)
        // Subtotal * 1.1 (10% for the burn)
        // Subtotal * 1.1 (10% for the infrastructure)

        // Its important to deploy in a cheapest chain. eg. Polygon, BSC, Avalanche, ...
        uint maxFee = 0.00082208 ether; // ~ 2 USD.
//        uint minFee = 0.00010091 ether; // ~ 0.25 USD.
        uint avgFee = 0.00030755 ether; // ~ 0.75 USD. Register (MINT) | Vote (MINT) | AI Model Signature (INFRASTRUCTURE)

        uint mainContracts = 1 + 1 + 1; // Election + AI Model + CRON
        uint N = 1; // Number of "boxes". Each box will represent a node or leaf in the tree of the election scope. N = 0 if the election is not a tree. eg. `institutional`, `custodial`.
        uint votingContracts = 1 + N ; // Main + children
        uint voters = details.magnitude; // Some voters could pay their own fees. Others will be paid by the election. That's why this is a parameter.
        uint voterActions = 1 + 1 + 1; // Register + Vote + AI Model signature.

        uint subtotal = maxFee * (mainContracts + votingContracts);
        subtotal += voters * voterActions * avgFee;
        uint ethTotal = subtotal * 13 / 10; // 30% for the treasury, burn, and infrastructure.

        return (ethTotal / 1 ether);
    }

    function tokenDetails(uint256 tokenId) external view onlyRole(MANAGER_ROLE) returns (FWOToken memory){
        return _tokens[tokenId];
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @dev Transfer is disabled for ongoing elections. (override ERC721)
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        FWOToken memory token = _tokens[tokenId];
        if (token.status != FWOStatus.CREATED && token.status != FWOStatus.COMPLETED) {
            revert FWOCantTransferInProgressElection(tokenId);
        }

        if(!_fwc.users().isVerified(to)) { revert FWOCantTransferToUnverifiedUser(to); }
        super.transferFrom(from, to, tokenId);

        if(token.status == FWOStatus.CREATED) {
            _fwc.electionTransferred(tokenId, from, to);
        }
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

// ---------------------------------------------------------------------------------------------------------------------
    function withdraw(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    receive() external payable {}
}