// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFreeWorldElectionRegistry {
    enum FWOScope {LOCAL, REGIONAL, NATIONAL, INTERNATIONAL}
    enum FWOType {CUSTODIAL, NON_CUSTODIAL, OTHER}
    enum FWOUnit {COUNTRY, REGION, PROVINCE, STATE, CITY, OTHER}
    enum FWOMintProcess {MINT, MINT_AND_BURN, MINT_AND_LOCK}
    enum FWOMintType {FIXED, DYNAMIC, SIMPLE, ARTISTIC, OTHER}

    enum FWOStatus {CREATED, DEPLOYED, COMPLETED, REMOVED}

    struct FWODetails {
        uint256 start;
        uint256 end;
        FWOScope scope;
        FWOType electionType;
        uint256 magnitude;
        FWOUnit Unit;
        uint256 UnitId;
        FWOMintProcess mintProcess;
        FWOMintType mintType;
    }

    struct FWOToken {
        FWODetails details;
        FWOStatus status;
        uint256 cost; // FWC
        address contractAddress; // if 0x0 then it is not deployed
    }

    event FWOCreated(address indexed user, uint tokenId);
    event FWOUpdated(address indexed user, uint tokenId);
    event FWORemoved(address indexed user, uint tokenId);
    event FWODeployed(address indexed user, uint tokenId);

    /**
     * @dev Indicates a `user` sent an invalid `signature` for the `data`.
     */
    error FWOInvalidSignature();

    /**
     * @dev Indicates the `FWO Token` is not in a valid status for the action. eg. trying to update a deployed token.
     */
    error FWOInvalidStatus(uint256 tokenId);

    error FWOInvalidData();

    error FWOInvalidOwner(uint256 tokenId);

    error FWONotDeployed(uint256 tokenId);

    error FWOUnknownTokenId(uint256 tokenId);

    error FWOUnauthorizedUser(uint256 tokenId, address user);

    error FWONoActiveElection();

    error FWOInvalidTokenId(uint256 tokenId);

    error FWOActiveElectionAlreadyExists(uint256 tokenId);

    error FWOCantTransferInProgressElection(uint256 tokenId);

    error FWOCantTransferToUnverifiedUser(address user);

    function create(bytes calldata data, bytes calldata signature, string memory uri) external returns (uint256, uint256);

    function update(uint256 tokenId, bytes calldata data, bytes calldata signature, string memory uri) external returns (uint256, uint256);

    function remove(uint256 tokenId) external;

    function deploy(uint256 tokenId) external returns (address);

    function verify(bytes calldata data, bytes calldata signature) external view returns (FWODetails calldata);

    function getElection(uint256 tokenId) external view returns (address);
}
