// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GrantsCubeNFT.sol";

contract GrantsCubeNFTFactory is AccessControl, Ownable {
    mapping(string => address) public deployedAddress;

    event GrantsCubeContractCreated(address grantscubenft);

    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");

    constructor(address owner) {
        transferOwnership(owner);
    }

    function createGrantsCubeNFTContract(
        string memory _name,
        string memory _symbol,
        address ownerOfToken
    )
        public
        isPermittedFactoryManager
        returns (address grantsCubeNFTContractAddress)
    {
        GrantsCubeNFT newGrantsCubeNft = new GrantsCubeNFT(
            _name,
            _symbol,
            ownerOfToken
        );

        grantsCubeNFTContractAddress = address(newGrantsCubeNft);
        deployedAddress[_name] = grantsCubeNFTContractAddress;
        emit GrantsCubeContractCreated(grantsCubeNFTContractAddress);
    }

    /// @dev modifier for the factory manager role
    modifier isPermittedFactoryManager() {
        require(hasRole(FACTORY_MANAGER, msg.sender), "Not factory manager");
        _;
    }

    /// @notice Adds a new Factory Manager
    /// @param _newFactoryManager the address of the person you are adding
    function addFactoryManager(address _newFactoryManager) public onlyOwner {
        grantRole(FACTORY_MANAGER, _newFactoryManager);
    }
}
