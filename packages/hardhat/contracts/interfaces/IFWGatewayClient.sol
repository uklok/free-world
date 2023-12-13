// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFWGatewayClient {
    enum FWResponseState {Sent, Success, Error}

    struct FWGatewayResponse {
        address source;
        FWResponseState state;
        bytes data;
        bytes error;
    }
}
