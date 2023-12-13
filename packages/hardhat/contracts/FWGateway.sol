// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './interfaces/IFWGateway.sol';

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract FWGateway is IFWGateway, FunctionsClient, AccessControl {
    using FunctionsRequest for FunctionsRequest.Request;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
    bytes32 private _donId; // DON ID for the Functions DON to which the requests are sent
    bytes32 private _gwId; // Gateway ID for the Functions Gateway to which the requests are sent

    bytes32 public s_lastRequestId;
    mapping(bytes32 => FWGatewayResponse) private unprocessed_responses;

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

// ---------------------------------------------------------------------------------------------------------------------
    modifier onlySource(bytes32 requestId) {
        if (unprocessed_responses[requestId].source != _msgSender()) {revert OnlySameSourceAllowed(requestId);}
        _;
    }
    /**
     * @notice Triggers an on-demand Functions request using remote encrypted secrets
     * @param source JavaScript source code
     * @param secretsLocation Location of secrets (only Location.Remote & Location.DONHosted are supported)
     * @param encryptedSecretsReference Reference pointing to encrypted secrets
     * @param args String arguments passed into the source code and accessible via the global variable `args`
     * @param bytesArgs Bytes arguments passed into the source code and accessible via the global variable `bytesArgs` as hex strings
     * @param subscriptionId Subscription ID used to pay for request (FunctionsConsumer contract address must first be added to the subscription)
     * @param callbackGasLimit Maximum amount of gas used to call the inherited `handleOracleFulfillment` method
     */
    function sendRequest(
        string calldata source,
        FunctionsRequest.Location secretsLocation,
        bytes calldata encryptedSecretsReference,
        string[] calldata args,
        bytes[] calldata bytesArgs,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) external onlyRole(CLIENT_ROLE){
        FunctionsRequest.Request memory req; // Struct API reference: https://docs.chain.link/chainlink-functions/api-reference/functions-request
        req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
        req.secretsLocation = secretsLocation;
        req.encryptedSecretsReference = encryptedSecretsReference;
        if (args.length > 0) {
            req.setArgs(args);
        }
        if (bytesArgs.length > 0) {
            req.setBytesArgs(bytesArgs);
        }

        // TODO: Figure out how to return the requestId without making the stack too deep.
        // This would allow to have a single gateway for multiple/different kind of clients.
        // Which could result into building a load balancer.
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, _donId);
        unprocessed_responses[s_lastRequestId].state = FWResponseState.Sent;
        unprocessed_responses[s_lastRequestId].source = _msgSender();
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        unprocessed_responses[requestId].state = err.length > 0 ? FWResponseState.Error : FWResponseState.Success;
        unprocessed_responses[requestId].data = response;
        unprocessed_responses[requestId].error = err;
    }

    /**
     * @dev Get the response data
     * @param requestId The request ID, returned by sendRequest()
     * @return response FWGatewayResponse
     */
    function getResponse(bytes32 requestId, bool remove) external onlySource(requestId) returns (FWGatewayResponse memory response) {
        response = unprocessed_responses[requestId];
        if (remove) {delete unprocessed_responses[requestId];}
    }
}