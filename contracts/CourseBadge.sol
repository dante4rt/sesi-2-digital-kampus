// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title CourseBadge
 * @dev Multi-token untuk berbagai badges dan certificates
 * Token types:
 * - Course completion certificates (non-fungible)
 * - Event attendance badges (fungible)
 * - Achievement medals (limited supply)
 * - Workshop participation tokens
 */
contract CourseBadge is ERC1155, AccessControl, ERC1155Pausable, ERC1155Supply {
    // Role definitions
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Token ID ranges untuk organization
    uint256 public constant CERTIFICATE_BASE = 1000;
    uint256 public constant EVENT_BADGE_BASE = 2000;
    uint256 public constant ACHIEVEMENT_BASE = 3000;
    uint256 public constant WORKSHOP_BASE = 4000;

    // Token metadata structure
    struct TokenInfo {
        string name;
        string category;
        uint256 maxSupply;
        bool isTransferable;
        uint256 validUntil; // 0 = no expiry
        address issuer;
    }

    // TODO: Add mappings
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => string) private _tokenURIs;

    // Track student achievements
    mapping(address => uint256[]) public studentBadges;
    mapping(uint256 => mapping(address => uint256)) public earnedAt; // Timestamp
    mapping(uint256 => mapping(address => string))
        public certificateAdditionalData;

    // Counter untuk generate unique IDs
    uint256 private _certificateCounter;
    uint256 private _eventCounter;
    uint256 private _achievementCounter;
    uint256 private _workshopCounter;

    // Events
    event CertificateTypeCreated(uint256 indexed tokenId, string name);
    event EventBadgeTypeCreated(uint256 indexed tokenId, string name);
    event BadgeIssued(
        address indexed student,
        uint256 indexed tokenId,
        uint256 amount
    );

    constructor() ERC1155("") {
        // TODO: Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Create new certificate type
     * Use case: Mata kuliah baru atau program baru
     */
    function createCertificateType(
        string memory name,
        uint256 maxSupply,
        string memory uriCertificate
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        // TODO: Create new certificate type
        // 1. Generate ID: CERTIFICATE_BASE + _certificateCounter++
        // 2. Store token info
        // 3. Set URI
        // 4. Return token ID
        require(maxSupply > 0, "Max supply must be greater than 0");
        require(bytes(name).length > 0, "Name cannot be empty");

        uint256 tokenId = CERTIFICATE_BASE + _certificateCounter++;

        tokenInfo[tokenId] = TokenInfo({
            name: name,
            category: "certificate",
            maxSupply: maxSupply,
            isTransferable: false,
            validUntil: 0,
            issuer: msg.sender
        });

        _tokenURIs[tokenId] = uriCertificate;

        emit CertificateTypeCreated(tokenId, name);
        return tokenId;
    }

    /**
     * @dev Issue certificate to student
     * Use case: Student lulus mata kuliah
     */
    function issueCertificate(
        address student,
        uint256 certificateType,
        string memory additionalData
    ) public onlyRole(MINTER_ROLE) {
        // TODO: Mint certificate
        // 1. Verify certificate type exists
        // 2. Check max supply not exceeded
        // 3. Mint 1 token to student
        // 4. Record timestamp
        // 5. Add to student's badge list
        require(student != address(0), "Invalid student address");
        require(
            tokenInfo[certificateType].maxSupply > 0,
            "Invalid certificate type"
        );
        require(
            keccak256(abi.encodePacked(tokenInfo[certificateType].category)) ==
                keccak256("certificate"),
            "Not a certificate type"
        );
        require(
            totalSupply(certificateType) < tokenInfo[certificateType].maxSupply,
            "Max supply exceeded"
        );
        require(
            balanceOf(student, certificateType) == 0,
            "Student already has this certificate"
        );

        _mint(student, certificateType, 1, "");

        earnedAt[certificateType][student] = block.timestamp;
        studentBadges[student].push(certificateType);
        certificateAdditionalData[certificateType][student] = additionalData;

        emit BadgeIssued(student, certificateType, 1);
    }

    /**
     * @dev Batch mint event badges
     * Use case: Attendance badges untuk peserta event
     */
    function mintEventBadges(
        address[] memory attendees,
        uint256 eventId,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        // TODO: Batch mint to multiple addresses
        // Use loop to mint to each attendee
        // Record participation
        require(attendees.length > 0, "No attendees provided");
        require(tokenInfo[eventId].maxSupply > 0, "Invalid event badge type");
        require(
            keccak256(abi.encodePacked(tokenInfo[eventId].category)) ==
                keccak256("event_badge"),
            "Not an event badge type"
        );
        require(amount > 0, "Amount must be greater than 0");

        for (uint256 i = 0; i < attendees.length; i++) {
            address attendee = attendees[i];
            require(attendee != address(0), "Invalid attendee address");

            if (balanceOf(attendee, eventId) == 0) {
                _mint(attendee, eventId, amount, "");
                earnedAt[eventId][attendee] = block.timestamp;
                studentBadges[attendee].push(eventId);

                emit BadgeIssued(attendee, eventId, amount);
            }
        }
    }

    /**
     * @dev Set metadata URI untuk token
     */
    function setTokenURI(
        uint256 tokenId,
        string memory newuri
    ) public onlyRole(URI_SETTER_ROLE) {
        // TODO: Store custom URI per token
        require(bytes(newuri).length > 0, "URI cannot be empty");
        require(tokenInfo[tokenId].maxSupply > 0, "Token ID does not exist");

        _tokenURIs[tokenId] = newuri;

        emit URI(newuri, tokenId);
    }

    /**
     * @dev Get all badges owned by student
     */
    function getStudentBadges(
        address student
    ) public view returns (uint256[] memory) {
        // TODO: Return array of token IDs owned by student
        require(student != address(0), "Invalid student address");
        require(
            studentBadges[student].length > 0,
            "No badges found for student"
        );

        return studentBadges[student];
    }

    /**
     * @dev Verify badge ownership dengan expiry check
     */
    function verifyBadge(
        address student,
        uint256 tokenId
    ) public view returns (bool isValid, uint256 earnedTimestamp) {
        // TODO: Check ownership and validity
        // 1. Check balance > 0
        // 2. Check not expired
        // 3. Return status and when earned
        require(student != address(0), "Invalid student address");
        require(tokenInfo[tokenId].maxSupply > 0, "Token ID does not exist");

        if (balanceOf(student, tokenId) == 0) {
            return (false, 0);
        }

        uint256 earned = earnedAt[tokenId][student];
        bool notExpired = tokenInfo[tokenId].validUntil == 0 ||
            tokenInfo[tokenId].validUntil > block.timestamp;

        return (earned > 0 && notExpired, earned);
    }

    /**
     * @dev Pause all transfers
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Override transfer to check transferability and pause
     */
    /**
        function _beforeTokenTransfer(
            address operator,
            address from,
            address to,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
            // TODO: Check transferability for each token
            // for (uint i = 0; i < ids.length; i++) {
            //     if (from != address(0) && to != address(0)) { // Not mint or burn
            //         require(tokenInfo[ids[i]].isTransferable, "Token not transferable");
            //     }
            // }

            super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        }
      */

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply, ERC1155Pausable) {
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    tokenInfo[ids[i]].isTransferable,
                    "Token not transferable"
                );
            }
        }

        super._update(from, to, ids, values);
    }

    /**
     * @dev Override to return custom URI per token
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // TODO: Return stored URI for token
        // return _tokenURIs[tokenId];
        require(tokenInfo[tokenId].maxSupply > 0, "Token ID does not exist");

        string memory tokenURI = _tokenURIs[tokenId];
        return bytes(tokenURI).length > 0 ? tokenURI : super.uri(tokenId);
    }

    /**
     * @dev Check interface support
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Achievement System Functions

    /**
     * @dev Grant achievement badge
     * Use case: Dean's list, competition winner, etc
     */
    function grantAchievement(
        address student,
        string memory achievementName,
        uint256 rarity // 1 = common, 2 = rare, 3 = legendary
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        // TODO: Create unique achievement NFT
        // Generate achievement ID
        // Set limited supply based on rarity
        // Mint to deserving student
        require(student != address(0), "Invalid student address");
        require(rarity >= 1 && rarity <= 3, "Rarity must be between 1 and 3");
        require(
            bytes(achievementName).length > 0,
            "Achievement name cannot be empty"
        );

        uint256 tokenId = ACHIEVEMENT_BASE + _achievementCounter++;
        uint256 maxSupply = rarity == 1 ? 1000 : (rarity == 2 ? 100 : 10);

        tokenInfo[tokenId] = TokenInfo({
            name: achievementName,
            category: "achievement",
            maxSupply: maxSupply,
            isTransferable: false,
            validUntil: 0,
            issuer: msg.sender
        });

        _mint(student, tokenId, 1, "");

        earnedAt[tokenId][student] = block.timestamp;
        studentBadges[student].push(tokenId);

        emit BadgeIssued(student, tokenId, 1);
        return tokenId;
    }

    /**
     * @dev Create workshop series dengan multiple sessions
     */
    function createWorkshopSeries(
        string memory seriesName,
        uint256 totalSessions
    ) public onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        // TODO: Create multiple related tokens
        // Return array of token IDs for each session
        require(
            bytes(seriesName).length > 0,
            "Workshop series name cannot be empty"
        );
        require(totalSessions > 0, "Total sessions must be greater than 0");

        uint256[] memory sessionIds = new uint256[](totalSessions);

        for (uint256 i = 0; i < totalSessions; i++) {
            uint256 tokenId = WORKSHOP_BASE + _workshopCounter++;
            tokenInfo[tokenId] = TokenInfo({
                name: string(
                    abi.encodePacked(seriesName, " - Session ", i + 1)
                ),
                category: "workshop",
                maxSupply: 100, // Customizable
                isTransferable: true,
                validUntil: 0,
                issuer: msg.sender
            });

            sessionIds[i] = tokenId;
        }

        return sessionIds;
    }

    function burnExpired(uint256 tokenId) public {
        require(
            tokenInfo[tokenId].validUntil < block.timestamp,
            "Token not expired"
        );

        _burn(msg.sender, tokenId, 1);
    }

    function isExpired(uint256 tokenId) public view returns (bool) {
        return tokenInfo[tokenId].validUntil < block.timestamp;
    }

    function createEventBadgeType(
        string memory name,
        uint256 maxSupply,
        string memory uriEventBadge,
        bool isTransferable
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        require(maxSupply > 0, "Max supply must be greater than 0");
        require(bytes(name).length > 0, "Name cannot be empty");

        uint256 tokenId = EVENT_BADGE_BASE + _eventCounter++;

        tokenInfo[tokenId] = TokenInfo({
            name: name,
            category: "event_badge",
            maxSupply: maxSupply,
            isTransferable: isTransferable,
            validUntil: 0,
            issuer: msg.sender
        });

        _tokenURIs[tokenId] = uriEventBadge;

        emit EventBadgeTypeCreated(tokenId, name);
        return tokenId;
    }

    function getTokenInfo(
        uint256 tokenId
    ) public view returns (TokenInfo memory) {
        require(tokenInfo[tokenId].maxSupply > 0, "Token ID does not exist");

        return tokenInfo[tokenId];
    }

    function hasBadge(
        address student,
        uint256 tokenId
    ) public view returns (bool) {
        return balanceOf(student, tokenId) > 0;
    }

    function getCertificateAdditionalData(
        uint256 certificateType,
        address student
    ) public view returns (string memory) {
        return certificateAdditionalData[certificateType][student];
    }
}
