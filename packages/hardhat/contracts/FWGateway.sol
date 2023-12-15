// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './interfaces/IFWGateway.sol';
import {IFWGatewayClient} from './interfaces/IFWGatewayClient.sol';

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract FWGateway is IFWGateway, FunctionsClient, AccessControl {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
    bytes32 private _donId; // DON ID for the Functions DON to which the requests are sent

    mapping(uint64 subscriptionId => FWGRequest) private _requests; // Each subscription can only handle one kind of request
    mapping(bytes32 requestId => IFWGatewayClient.FWGResponse) private unprocessed_responses; // Responses that have not been processed yet

    constructor(address router, bytes32 initialDonId, address initialOwner) FunctionsClient(router) {
        _donId = initialDonId;
        _grantRole(DEFAULT_ADMIN_ROLE, address(0) == initialOwner ? _msgSender() : initialOwner);
    }

    /**
     * @dev Set the DON ID
     * @param newDonId New DON ID
     */
    function setDonId(bytes32 newDonId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _donId = newDonId;
    }

    /**
     * @dev Get the DON ID
     * @return DON ID
     */
    function donId() external view returns (bytes32) {
        return _donId;
    }

    function registerRequest(
        uint64 subscriptionId,
        FunctionsRequest.Location codeLocation,
        string calldata source,
        FunctionsRequest.Location secretsLocation,
        bytes calldata encryptedSecretsReference,
        uint32 callbackGasLimit,
        string calldata name
    ) external onlyRole(MANAGER_ROLE) {
        if(bytes(name).length == 0) {revert FWGRequestNameEmpty();}

        FWGRequest storage req = _requests[subscriptionId];
        req.name = name;
        req.callbackGasLimit = callbackGasLimit;

        // Only JavaScript is supported for now
        req.config.initializeRequest(codeLocation, FunctionsRequest.CodeLanguage.JavaScript, source);
        req.config.secretsLocation = secretsLocation;
        req.config.encryptedSecretsReference = encryptedSecretsReference;
    }

// ---------------------------------------------------------------------------------------------------------------------
    modifier onlySource(bytes32 requestId) {
        if (unprocessed_responses[requestId].source != _msgSender()) {revert FWGOnlySameSourceAllowed(requestId);}
        _;
    }

// ---------------------------------------------------------------------------------------------------------------------
    /**
     * @notice Triggers an on-demand Functions request using remote encrypted secrets
     * @param subscriptionId Subscription ID used to pay for request (FunctionsConsumer contract address must first be added to the subscription)
     * @param args String arguments passed into the source code and accessible via the global variable `args`
     * @param bytesArgs Bytes arguments passed into the source code and accessible via the global variable `bytesArgs` as hex strings
     * @param encryptedSecretsReference Reference pointing to encrypted secrets
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args,
        bytes[] calldata bytesArgs,
        bytes calldata encryptedSecretsReference
    ) external onlyRole(CLIENT_ROLE) returns (bytes32 requestId) {
        FWGRequest storage request = _requests[subscriptionId];
        if (bytes(request.name).length == 0) {revert FWGRequestNotRegistered(subscriptionId);}

        FunctionsRequest.Request memory req = request.config;
        req.encryptedSecretsReference = encryptedSecretsReference;

        if (args.length > 0) {
            req.setArgs(args);
        }
        if (bytesArgs.length > 0) {
            req.setBytesArgs(bytesArgs);
        }

        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, request.callbackGasLimit, _donId);
        unprocessed_responses[requestId].state = IFWGatewayClient.FWGResponseState.Sent;
        unprocessed_responses[requestId].source = _msgSender();
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        IFWGatewayClient.FWGResponse storage resp = unprocessed_responses[requestId];
        if (resp.state != IFWGatewayClient.FWGResponseState.Sent) {revert FWGRequestAlreadyFulfilled(requestId);}

        unprocessed_responses[requestId].state = err.length > 0 ? IFWGatewayClient.FWGResponseState.Error : IFWGatewayClient.FWGResponseState.Success;
        unprocessed_responses[requestId].data = response;
        unprocessed_responses[requestId].error = err;

        // TODO: Call the client's callback function.
         IFWGatewayClient(resp.source).callback(requestId);
    }

    /**
     * @dev Get the response data
     * @param requestId The request ID, returned by sendRequest()
     * @return response FWGResponse
     */
    function getResponse(bytes32 requestId, bool remove) external onlySource(requestId) returns (IFWGatewayClient.FWGResponse memory response) {
        response = unprocessed_responses[requestId];
        if (remove) {delete unprocessed_responses[requestId];}
    }
}