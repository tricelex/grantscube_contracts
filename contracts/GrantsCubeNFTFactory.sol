// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GrantsCubeNFT.sol";

contract GrantsCubeNFTFactory is AccessControl, Ownable {
    string[] grantsCubeSymbols;
    mapping(string => GrantsCubeNFT) grantsCube;
    mapping(string => address) public deployedAddress;

    GrantsCubeNFT[] public grantsCubeNFTs;

    event GrantsCubeContractCreated(address grantscubenft);

    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");

    constructor(address owner, address[] memory admins) {
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
            _setupRole(FACTORY_MANAGER, admins[i]);
        }
        transferOwnership(owner);
    }

    function createGrantsCubeNFTContract(
        string memory _name,
        string memory _symbol,
        string memory organization_,
        bool transferable_,
        bool mintable_,
        address ownerOfToken
    )
        public
        isPermittedFactoryManager
        returns (address grantsCubeNFTContractAddress)
    {
        GrantsCubeNFT newGrantsCubeNft = new GrantsCubeNFT(
            _name,
            _symbol,
            organization_,
            transferable_,
            mintable_,
            ownerOfToken
        );

        grantsCubeNFTContractAddress = address(newGrantsCubeNft);

        grantsCube[_symbol] = newGrantsCubeNft;
        grantsCubeNFTs.push(newGrantsCubeNft);

        grantsCubeSymbols.push(_symbol);

        deployedAddress[_name] = grantsCubeNFTContractAddress;

        emit GrantsCubeContractCreated(grantsCubeNFTContractAddress);
    }

    function getGrantsCubeNFTSymbolsArrayLength()
        public
        view
        returns (uint256)
    {
        return grantsCubeSymbols.length;
    }

    function getGrantsCubeNFTSymbolByIndex(uint256 _index)
        public
        view
        returns (string memory)
    {
        return grantsCubeSymbols[_index];
    }

    function getGrantsCubeNFTAddressBySymbol(string memory _symbol)
        public
        view
        returns (address)
    {
        return address(grantsCube[_symbol]);
    }

    function getDeployedGrantsCubeContracts()
        public
        view
        returns (GrantsCubeNFT[] memory grantsCubeNFTContractAddresses)
    {
        grantsCubeNFTContractAddresses = new GrantsCubeNFT[](
            grantsCubeNFTContractAddresses.length
        );
        uint256 count;

        for (uint256 i = 0; i < grantsCubeNFTContractAddresses.length; i++) {
            grantsCubeNFTContractAddresses[
                count
            ] = grantsCubeNFTContractAddresses[i];
            count++;
        }
    }

    /// @dev modifier for the factory manager role
    modifier isPermittedFactoryManager() {
        require(
            hasRole(FACTORY_MANAGER, msg.sender),
            "Not an approved factory manager"
        );
        _;
    }

    /// @notice Adds a new Factory Manager
    /// @param _newFactoryManager the address of the person you are adding
    function addFactoryManager(address _newFactoryManager) public onlyOwner {
        grantRole(FACTORY_MANAGER, _newFactoryManager);
    }
}
