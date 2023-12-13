// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './IFWGatewayClient.sol';

interface IFWGateway is IFWGatewayClient {
    /**
     * @dev Only the same source of the requestId is allowed to call the function
     */
    error OnlySameSourceAllowed(bytes32 requestId);

    function getResponse(bytes32 requestId, bool remove) external returns (FWGatewayResponse memory resp);
}
