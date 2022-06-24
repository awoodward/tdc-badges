// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Source: https://github.com/chiru-labs/ERC721A
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
// Source: https://docs.opengsn.org/contracts/#install-opengsn-contracts
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract TDCCollectibles is
    BaseRelayRecipient,
    ERC721A,
    Ownable,
    AccessControlEnumerable
{
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseURIPrefix = "";

    // Opensea
    string public contractURI = "";

    constructor() ERC721A("TDC Collectibles", "TDCCollectibles") {
        // Initialize owner access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // GSN
    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address addr) public onlyOwner {
        _setTrustedForwarder(addr);
    }

    function _msgSender()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (address sender)
    {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
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
        _safeMint(to, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
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

        _safeMint(to, quantity);
    }

    function walletOfOwner(address address_)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        if (_balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory _tokens = new uint256[](_balance);
            uint256 _index;

            uint256 tokensCount = totalSupply();

            for (uint256 i = 0; i < tokensCount; i++) {
                if (address_ == ownerOf(i)) {
                    _tokens[_index] = i;
                    _index++;
                }
            }

            return _tokens;
        }
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721A, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }
}
