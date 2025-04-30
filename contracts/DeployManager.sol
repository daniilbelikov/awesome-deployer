//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IUtilityContract.sol";

contract DeployManager is Ownable {
    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    error ContractNotActive();
    error NotEnoughFunds();
    error ContractDoesNotRegistred();
    error InitializationFailed();

    event NewContractAdded(
        address _contractAddress,
        uint256 _fee,
        bool _isActive,
        uint256 _timeStamp
    );
    event ContractFeeUpdated(
        address _contractAddress,
        uint256 _oldFee,
        uint256 _newFee,
        uint256 _timestamp
    );
    event ContractStatusUpdated(
        address _contractAddress,
        bool _isActive,
        uint256 _timestamp
    );
    event NewDeployment(
        address _deployer,
        address _contractAddress,
        uint256 _fee,
        uint256 _timeStamp
    );

    struct ContractInfo {
        uint256 fee;
        bool isActive;
        uint256 registredAt;
    }

    constructor() Ownable(msg.sender) {}

    function deploy(address _utilityContract, bytes calldata _initData)
        external
        payable
        returns (address)
    {
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.isActive, ContractNotActive());
        require(msg.value >= info.fee, NotEnoughFunds());
        require(info.registredAt > 0, ContractDoesNotRegistred());

        address clone = Clones.clone(_utilityContract);
        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(clone);

        emit NewDeployment(msg.sender, clone, msg.value, block.timestamp);

        return clone;
    }

    function addNewContract(
        address _contractAddress,
        uint256 _fee,
        bool _isActive
    ) external onlyOwner {
        contractsData[_contractAddress] = ContractInfo({
            fee: _fee,
            isActive: _isActive,
            registredAt: block.timestamp
        });

        emit NewContractAdded(
            _contractAddress,
            _fee,
            _isActive,
            block.timestamp
        );
    }

    function updateFee(address _contractAddress, uint256 _newFee) external onlyOwner {
        require(contractsData[_contractAddress].registredAt > 0, ContractDoesNotRegistred()); 

        uint256 oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(
            _contractAddress,
            oldFee,
            _newFee,
            block.timestamp
        );
    }

    function deactivateContract(address _address) external onlyOwner {
        require(contractsData[_address].registredAt > 0, ContractDoesNotRegistred());
        
        contractsData[_address].isActive = false;

        emit ContractStatusUpdated(_address, false, block.timestamp);
    }

    function activateContract(address _address) external onlyOwner {
        require(contractsData[_address].registredAt > 0, ContractDoesNotRegistred());

        contractsData[_address].isActive = true;

        emit ContractStatusUpdated(_address, true, block.timestamp);
    }
}