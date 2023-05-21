// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TDCCollectibles is
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

    constructor() ERC721("TDC Collectibles", "TDCCollectibles") {
        // Initialize owner access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only addresses with admin role can perform this action"
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
        require(_exists(tokenId), "Collectible token does not exist");
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

    function mintCollectibles(address to, uint256 quantity) public onlyMinter {
        require(quantity > 0, "Incorrect number of collectibles.");
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

    function renounceOwnership() public view override onlyOwner {
        revert("Not allowed");
    }
}
