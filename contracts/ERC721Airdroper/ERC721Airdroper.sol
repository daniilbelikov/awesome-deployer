//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IUtilityContract.sol";

contract ERC721Airdroper is IUtilityContract, Ownable {
    IERC721 public token;
    address public treasure;
    bool private initialized;

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NeedToApprovedTokens();
    error TransferFailed();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    constructor() Ownable(msg.sender) {}

    function initialize(bytes memory _initData) external notInitialized returns (bool) {
        (address _tokenAddress, address _treasure, address _owner) = abi.decode(_initData, (address, address, address));

        token = IERC721(_tokenAddress);
        treasure = _treasure;

        Ownable.transferOwnership(_owner);
        initialized = true;
        
        return true;
    }

    function getInitData(address _tokenAddress, address _treasure, address _owner) external pure returns (bytes memory) {
        return abi.encode(_tokenAddress, _treasure, _owner);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata _tokenId) external onlyOwner {
        require(receivers.length == _tokenId.length && receivers.length == _tokenId.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasure, address(this)), NeedToApprovedTokens());

        for(uint256 i = 0; i < _tokenId.length; i++) {
            token.safeTransferFrom(treasure, receivers[i], _tokenId[i]);
        }
    }

}