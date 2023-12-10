// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFreeWorldUserRegistry {
    event UserRegistered(address indexed user);
    event UserUnregistered(address indexed user);
    event UserVerified(address indexed user);

    /**
     * @dev Indicates a `tokenId` whose `owner` is trying to transfer.
     */
    error TokenTransferNotAllowed(uint256 tokenId);

    /**
     * @dev Indicates a `user` who is trying to register but it's already registered.
     */
    error AlreadyRegisteredUser(address user);

    /**
     * @dev Indicates a `user` who is trying to unregister or verify but it's not registered.
     */
    error NotRegisteredUser(address user);

    /**
     * @dev Indicates a `user` who is trying to mint but it's not verified.
     */
    error NotVerifiedUser(address user);

    /**
     * @dev Indicates a `user` who is trying to verify but it's already verified.
     */
    error AlreadyVerifiedUser(address user);


    function register() external; // only each user can register itself
    function unregister() external; // only each user can unregister itself
    function verify(address user) external; // only the related authority can verify a user (e.g. a government, a bank, etc.). In this case, the authority is the parent contract.

    function isRegistered(address user) external view returns (bool);
    function isVerified(address user) external view returns (bool);
}
