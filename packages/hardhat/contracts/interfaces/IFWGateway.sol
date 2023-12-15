// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IFWGatewayClient} from './IFWGatewayClient.sol';
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

interface IFWGateway {
    struct FWGRequest {
        string name;
        uint32 callbackGasLimit;
        FunctionsRequest.Request config;
    }

    /**
     * @dev Can't register a request with an empty name
     */
    error FWGRequestNameEmpty();

    /**
     * @dev Only the same source of the requestId is allowed to call the function
     */
    error FWGOnlySameSourceAllowed(bytes32 requestId);

    /**
     * @dev Only a registered subscriptionId is allowed to call the function
     */
    error FWGRequestNotRegistered(uint64 subscriptionId);

    /**
     * @dev Can't fulfill a request that has already been fulfilled
     */
    error FWGRequestAlreadyFulfilled(bytes32 requestId);

    /**
     * @dev Send a request to the Functions DON
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args,
        bytes[] calldata bytesArgs,
        bytes calldata encryptedSecretsReference
    ) external returns (bytes32 requestId);

    function getResponse(bytes32 requestId, bool remove) external returns (IFWGatewayClient.FWGResponse memory resp);
}
