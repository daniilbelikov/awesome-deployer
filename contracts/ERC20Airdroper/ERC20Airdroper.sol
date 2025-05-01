//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IUtilityContract.sol";

contract ERC20Airdroper is IUtilityContract, Ownable {
    IERC20 public token;
    uint256 public amount;
    address public treasure;
    bool private initialized;

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NotEnoughApprovedTojens();
    error TransferFailed();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    constructor() Ownable(msg.sender) {}

    function initialize(bytes memory _initData) external notInitialized returns (bool) {
        (address _tokenAddress, uint256 _airdropAmount, address _treasure, address _owner) = abi.decode(_initData, (address, uint256, address, address));

        token = IERC20(_tokenAddress);
        amount = _airdropAmount;
        treasure = _treasure;

        Ownable.transferOwnership(_owner);
        initialized = true;
        
        return true;
    }

    function getInitData(address _tokenAddress, uint256 _airdropAmount, address _treasure, address _owner) external pure returns (bytes memory) {
        return abi.encode(_tokenAddress, _airdropAmount, _treasure, _owner);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length == amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasure, address(this)) >= amount, NotEnoughApprovedTojens());

        for (uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(treasure, receivers[i], amounts[i]), TransferFailed());
        }
    }

}