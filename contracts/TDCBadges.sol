// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface ITDCCollectibles {
    function safeMint(address to) external;
}

interface ITDCCoins {
    function mint(address to, uint256 amount) external;
}

contract TDCBadges is
    ERC721,
    Ownable,
    AccessControlEnumerable,
    ERC721Enumerable
{
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseURIPrefix = "";

    // Opensea
    string public contractURI = "";

    address collectiblesContractAddr = address(0x0);
    address coinsContractAddr = address(0x0);

    uint256 public coinsPerToken = 1;

    // track number of times token is transferred
    mapping(uint256 => bool) _tokenTransferred;

    mapping(uint256 => bool) _tokenRedeemed;

    constructor() ERC721("TDC Badges", "TDCBadge") {
        // Initialize owner access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only addresses with admin role can perform this action."
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Only addresses with minter role can perform this action."
        );
        _;
    }

    modifier onceOnly(uint256 tokenId) {
        require(
            _tokenTransferred[tokenId] == false,
            "Badges can only be transferred once."
        );
        _;
    }

    modifier notRedeemed(uint256 tokenId) {
        require(
            _tokenTransferred[tokenId] == true,
            "Badge must be transferred before it can be redeemed."
        );
        require(_tokenRedeemed[tokenId] == false, "Badge is already redeemed.");
        _;
    }

    function setCollectiblesContractAddress(address addr) public onlyOwner {
        collectiblesContractAddr = addr;
    }

    function setCoinsContractAddress(address addr) public onlyOwner {
        coinsContractAddr = addr;
    }

    function setCoinsPerToken(uint256 coins) public onlyOwner {
        coinsPerToken = coins;
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function safeMint(address to) public onlyMinter {
        uint256 supply = totalSupply();

        // mint 1 token
        _safeMint(to, supply);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Badge token does not exist.");
        return
            bytes(_baseURIPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURIPrefix,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function mintBadges(address to, uint quantity) public onlyMinter {
        require(quantity > 0, "Incorrect number of badges.");
        uint256 supply = totalSupply();

        for (uint256 i = 1; i <= quantity; i++) {
            _safeMint(to, supply + i);
        }
    }

    function walletOfOwner(
        address address_
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(address_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(address_, i);
        }
        return tokenIds;
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        override(ERC721, AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Tokens can only be transferred once
    // Call Collectibles contract when transferring
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) onceOnly(tokenId) {
        require(
            collectiblesContractAddr != address(0x0),
            "Collectibles contract address not set."
        );
        super.transferFrom(from, to, tokenId);
        // Send a collectible to the sender
        ITDCCollectibles(collectiblesContractAddr).safeMint(from);
        _tokenTransferred[tokenId] = true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721) onceOnly(tokenId) {
        require(
            collectiblesContractAddr != address(0x0),
            "Collectibles contract address not set."
        );
        super.safeTransferFrom(from, to, tokenId, data);
        // Send a collectible to the sender
        ITDCCollectibles(collectiblesContractAddr).safeMint(from);
        _tokenTransferred[tokenId] = true;
    }

    // Tokens can only be redeemed once
    // Call Coins contract when redeeming
    function redeemToken(
        address from,
        uint256 tokenId
    ) public notRedeemed(tokenId) {
        require(
            coinsContractAddr != address(0x0),
            "Coins contract address not set."
        );
        require(from == ownerOf(tokenId), "Wallet is not owner of token");
        // burn the token
        _burn(tokenId);
        // Send coins to the redeemer
        ITDCCoins(coinsContractAddr).mint(from, coinsPerToken);

        _tokenRedeemed[tokenId] = true;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Not allowed");
    }
}
