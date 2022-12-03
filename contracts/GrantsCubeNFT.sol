// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GrantsCubeNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    //===== Interfaces =====//

    struct TokenData {
        uint256 id;
        address owner;
        address mintedTo;
        string nickName;
        string organization;
        string tokenName;
    }

    struct TokenURIParams {
        uint256 id;
        address owner;
        string nickName;
        string organization;
        string tokenName;
    }

    struct TokenOwnerInfo {
        string nickName;
    }

    //===== State =====//
    Counters.Counter public _tokenIdCounter;

    string public _organization;
    bool internal _transferable;
    bool internal _mintable;

    string internal svgLogo;
    address internal _vault;

    mapping(uint256 => TokenOwnerInfo) internal _tokenOwnerInfo;
    mapping(uint256 => address) internal _mintedTo;

    //===== Events =====//
    error NotTransferrable();

    constructor(
        string memory name_,
        string memory symbol_,
        address ownerOfToken
    ) ERC721(name_, symbol_) {
        _organization = "GrantsCube";
        _transferable = false;
        _mintable = true;
        _vault = ownerOfToken;
    }

    //===== External Functions =====//
    fallback() external payable {
        return;
    }

    receive() external payable {
        return;
    }

    function setSvgLogo(string calldata _svgLogo) public onlyOwner {
        svgLogo = _svgLogo;
    }

    //===== Public Functions =====//

    function mint(address to, string calldata nickName) public payable {
        _mint(to, nickName);
    }

    function mintedTo(uint256 tokenId) public view returns (address) {
        return _mintedTo[tokenId];
    }

    function nickNameOf(uint256 tokenId) public view returns (string memory) {
        return _tokenOwnerInfo[tokenId].nickName;
    }

    function tokenDataOf(
        uint256 tokenId
    ) public view returns (TokenData memory) {
        TokenData memory tokenData = TokenData(
            tokenId,
            ownerOf(tokenId),
            mintedTo(tokenId),
            nickNameOf(tokenId),
            _organization,
            name()
        );
        return tokenData;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function withdraw() public {
        (bool release, ) = payable(_vault).call{value: address(this).balance}(
            ""
        );
        require(release);
    }

    // Added isTransferable only
    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) isTransferable {
        address ownerOfToken = ownerOf(tokenId);
        require(to != ownerOfToken, "approval to current owner");

        require(
            _msgSender() == ownerOfToken ||
                isApprovedForAll(ownerOfToken, _msgSender()),
            "caller is not owner"
        );

        _approve(to, tokenId);
    }

    // Added isTransferable only
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) isTransferable {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner"
        );

        _transfer(from, to, tokenId);
    }

    // Added isTransferable only
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) isTransferable {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    //===== Internal Functions =====//
    function _mint(address to, string memory nickName) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenOwnerInfo[tokenId].nickName = nickName;
        _mintedTo[tokenId] = to;
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    //===== Modifiers =====//

    modifier isTransferable() {
        require(_transferable == true, "not transferable");
        _;
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "doesn't exist or burnt");
        _;
    }

    modifier onlyMinterOrTokenOwner(uint256 tokenId) {
        require(_exists(tokenId), "doesn't exist or burnt");
        require(_msgSender() == ownerOf(tokenId), "sender not owner");
        _;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) revert NotTransferrable();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
