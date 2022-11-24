// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GrantsCubeNFT is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
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
    Counters.Counter internal _tokenIdCounter;

    string internal _organization;
    bool internal _transferable;
    bool internal _mintable;

    string internal svgLogo;
    address internal _vault;

    mapping(uint256 => TokenOwnerInfo) internal _tokenOwnerInfo;
    mapping(uint256 => address) internal _mintedTo;

    //===== Events =====//

    event ToggleTransferable(bool transferable);
    event ToggleMintable(bool mintable);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory organization_,
        bool transferable_,
        bool mintable_,
        address ownerOfToken
    ) ERC721(name_, symbol_) {
        _organization = organization_;
        _transferable = transferable_;
        _mintable = mintable_;
        _vault = ownerOfToken;
    }

    //===== External Functions =====//
    fallback() external payable {
        return;
    }

    receive() external payable {
        return;
    }

    function burn(uint256 tokenId)
        public
        override(ERC721Burnable)
        exists(tokenId)
        onlyMinterOrTokenOwner(tokenId)
    {
        _burn(tokenId);
    }

    function setSvgLogo(string calldata _svgLogo) public onlyOwner {
        svgLogo = _svgLogo;
    }

    function toggleTransferable() external onlyOwner returns (bool) {
        if (_transferable) {
            _transferable = false;
        } else {
            _transferable = true;
        }
        emit ToggleTransferable(_transferable);
        return _transferable;
    }

    function toggleMintable() external onlyOwner returns (bool) {
        if (_mintable) {
            _mintable = false;
        } else {
            _mintable = true;
        }
        emit ToggleMintable(_mintable);
        return _mintable;
    }

    //===== Public Functions =====//

    function mint(address to, string calldata nickName) public payable {
        _mint(to, nickName);
    }

    function organization() public view returns (string memory) {
        return _organization;
    }

    function transferable() public view returns (bool) {
        return _transferable;
    }

    function mintable() public view returns (bool) {
        return _mintable;
    }

    function mintedTo(uint256 tokenId) public view returns (address) {
        return _mintedTo[tokenId];
    }

    function nickNameOf(uint256 tokenId) public view returns (string memory) {
        return _tokenOwnerInfo[tokenId].nickName;
    }

    function nextId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenDataOf(uint256 tokenId)
        public
        view
        returns (TokenData memory)
    {
        TokenData memory tokenData = TokenData(
            tokenId,
            ownerOf(tokenId),
            mintedTo(tokenId),
            nickNameOf(tokenId),
            organization(),
            name()
        );
        return tokenData;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        exists(tokenId)
        returns (string memory)
    {
        TokenURIParams memory params = TokenURIParams(
            tokenId,
            mintedTo(tokenId),
            nickNameOf(tokenId),
            organization(),
            name()
        );
        return constructTokenURI(params);
    }

    function withdraw() public {
        (bool release, ) = payable(_vault).call{value: address(this).balance}(
            ""
        );
        require(release);
    }

    // Added isTransferable only
    function approve(address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        isTransferable
    {
        address ownerOfToken = ownerOf(tokenId);
        require(to != ownerOfToken, "ERC721: approval to current owner");

        require(
            _msgSender() == ownerOfToken ||
                isApprovedForAll(ownerOfToken, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
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
            "ERC721: transfer caller is not owner nor approved"
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
            "ERC721: transfer caller is not owner nor approved"
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

    function constructTokenURI(TokenURIParams memory params)
        internal
        view
        returns (string memory)
    {
        string memory svg = Base64.encode(
            bytes(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1200 1600' width='1200' height='1600' style='background-color:white'>",
                    svgLogo,
                    "<text style='font: bold 100px sans-serif;' text-anchor='middle' alignment-baseline='central' x='600' y='1250'>",
                    params.nickName,
                    "</text>",
                    "</text>",
                    "<text style='font: bold 100px sans-serif;' text-anchor='middle' alignment-baseline='central' x='600' y='1450'>",
                    _organization,
                    "</text>",
                    "</svg>"
                )
            )
        );

        // prettier-ignore
        /* solhint-disable */
        string memory json = string(abi.encodePacked(
          '{ "id": ',
          Strings.toString(params.id),
          ', "nickName": "',
          params.nickName,
          '", "organization": "',
          params.organization,
          '", "tokenName": "',
          params.tokenName,
          '", "image": "data:image/svg+xml;base64,',
          svg,
          '" }'
        ));

        // prettier-ignore
        return string(abi.encodePacked('data:application/json;utf8,', json));
        /* solhint-enable */
    }

    //===== Modifiers =====//

    modifier isTransferable() {
        require(transferable() == true, "SoulBoundNFT: not transferable");
        _;
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "token doesn't exist or has been burnt");
        _;
    }

    modifier onlyMinterOrTokenOwner(uint256 tokenId) {
        require(_exists(tokenId), "token doesn't exist or has been burnt");
        require(_msgSender() == ownerOf(tokenId), "sender not owner");
        _;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) revert NotTransferrable();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
