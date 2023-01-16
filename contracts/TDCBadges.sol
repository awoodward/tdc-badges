// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Source: https://github.com/chiru-labs/ERC721A
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
// Source: https://docs.opengsn.org/contracts/#install-opengsn-contracts
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface ITDCCollectibles {
    function safeMint(address to) external;
}

interface ITDCCoins {
    function mint(address to, uint256 amount) external;
}

contract TDCBadges is
    BaseRelayRecipient, ERC721A,
    Ownable,
    AccessControlEnumerable
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

    constructor() ERC721A("TDC Badges", "TDCBadge") {
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
        // mint 1 token
        _safeMint(to, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
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

 
    function mintBadges(address to, uint quantity) public onlyMinter 
    {
        require(quantity > 0, "Incorrect number of badges.");

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
        //return super.supportsInterface(interfaceID);
        // Updated for ERC721A V4.x
        return ERC721A.supportsInterface(interfaceID);
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
    ) public override(ERC721A) onceOnly(tokenId) {
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
        uint256 tokenId
    ) public override(ERC721A) onceOnly(tokenId) {
        super.transferFrom(from, to, tokenId);
        _tokenTransferred[tokenId] = true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A) onceOnly(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
        _tokenTransferred[tokenId] = true;
    }

    // Tokens can only be redeemed once
    // Call Coins contract when redeeming
    function redeemToken(address from, uint256 tokenId)
        public
        notRedeemed(tokenId)
    {
        require(
            coinsContractAddr != address(0x0),
            "Coins contract address not set."
        );
        // burn the token
        _burn(tokenId);
        // Send coins to the redeemer
        ITDCCoins(coinsContractAddr).mint(from, coinsPerToken);

        _tokenRedeemed[tokenId] = true;
    }
}
