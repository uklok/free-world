// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFWGatewayClient {
    enum FWGResponseState {Sent, Success, Error}

    struct FWGResponse {
        uint64 subscriptionId;
        address source;
        FWGResponseState state;
        bytes data;
        bytes error;
    }

    function callback(bytes32 requestId) external;
}
