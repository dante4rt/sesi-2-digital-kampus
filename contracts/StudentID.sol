// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StudentID
 * @dev NFT-based student identity card
 * Features:
 * - Auto-expiry after 4 years
 * - Renewable untuk active students
 * - Contains student metadata
 * - Non-transferable (soulbound)
 */
contract StudentID is
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ERC721Pausable,
    Ownable
{
    uint256 private _nextTokenId;

    struct StudentData {
        string nim;
        string name;
        string major;
        uint256 enrollmentYear;
        uint256 expiryDate;
        bool isActive;
        uint8 semester;
    }

    // TODO: Add mappings
    mapping(uint256 => StudentData) public studentData;
    mapping(string => uint256) public nimToTokenId; // Prevent duplicate NIM
    mapping(address => uint256) public addressToTokenId; // One ID per address

    // Events
    event StudentIDIssued(
        uint256 indexed tokenId,
        string nim,
        address student,
        uint256 expiryDate
    );
    event StudentIDRenewed(uint256 indexed tokenId, uint256 newExpiryDate);
    event StudentStatusUpdated(uint256 indexed tokenId, bool isActive);
    event ExpiredIDBurned(uint256 indexed tokenId);

    constructor() ERC721("Student Identity Card", "SID") Ownable(msg.sender) {}

    /**
     * @dev Issue new student ID
     * Use case: New student enrollment
     */
    function issueStudentID(
        address to,
        string memory nim,
        string memory name,
        string memory major,
        string memory uri
    ) public onlyOwner {
        // TODO: Implement ID issuance
        // Hints:
        // 1. Check NIM tidak duplicate (use nimToTokenId)
        // 2. Check address belum punya ID (use addressToTokenId)
        // 3. Calculate expiry (4 years from now)
        // 4. Mint NFT
        // 5. Set token URI (foto + metadata)
        // 6. Store student data
        // 7. Update mappings
        // 8. Emit event
        require(bytes(nim).length > 0, "NIM cannot be empty");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(major).length > 0, "Major cannot be empty");
        require(to != address(0), "Cannot issue to zero address");
        require(nimToTokenId[nim] == 0, "NIM already exists");
        require(addressToTokenId[to] == 0, "Address already has an ID");

        uint256 tokenId = _nextTokenId++;
        uint256 expiryDate = block.timestamp + 4 * 365 days; // 4 years

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        studentData[tokenId] = StudentData({
            nim: nim,
            name: name,
            major: major,
            enrollmentYear: block.timestamp / 365 days,
            expiryDate: expiryDate,
            isActive: true,
            semester: 1
        });

        nimToTokenId[nim] = tokenId;
        addressToTokenId[to] = tokenId;

        emit StudentIDIssued(tokenId, nim, to, expiryDate);
    }

    /**
     * @dev Renew student ID untuk semester baru
     */
    function renewStudentID(uint256 tokenId) public onlyOwner {
        // TODO: Extend expiry date
        // Check token exists
        // Check student is active
        // Add 6 months to expiry
        // Update semester
        // Emit renewal event
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(studentData[tokenId].isActive, "Student is not active");
        require(!isExpired(tokenId), "Cannot renew expired ID");

        studentData[tokenId].expiryDate += (6 * 30 days);
        studentData[tokenId].semester += 1;

        emit StudentIDRenewed(tokenId, studentData[tokenId].expiryDate);
    }

    /**
     * @dev Update student status (active/inactive)
     * Use case: Cuti, DO, atau lulus
     */
    function updateStudentStatus(
        uint256 tokenId,
        bool isActive
    ) public onlyOwner {
        // TODO: Update active status
        // If inactive, maybe reduce privileges
        require(_nextTokenId >= tokenId, "Token does not exist");

        studentData[tokenId].isActive = isActive;

        if (!isActive) {
            burnExpired(tokenId);
        }

        emit StudentStatusUpdated(tokenId, isActive);
    }

    /**
     * @dev Burn expired IDs
     * Use case: Cleanup expired cards
     */
    function burnExpired(uint256 tokenId) public {
        // TODO: Allow anyone to burn if expired
        // Check token exists
        // Check if expired (block.timestamp > expiryDate)
        // Burn token
        // Clean up mappings
        // Emit event
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(
            isExpired(tokenId) || !studentData[tokenId].isActive,
            "ID is not expired or inactive"
        );

        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "Only token owner or contract owner can burn"
        );

        string memory nim = studentData[tokenId].nim;
        address tokenOwner = ownerOf(tokenId);

        delete nimToTokenId[nim];
        delete addressToTokenId[tokenOwner];
        delete studentData[tokenId];

        _burn(tokenId);

        emit ExpiredIDBurned(tokenId);
    }

    /**
     * @dev Check if ID is expired
     */
    function isExpired(uint256 tokenId) public view returns (bool) {
        // TODO: Return true if expired
        require(_nextTokenId >= tokenId, "Token does not exist");

        return studentData[tokenId].expiryDate < block.timestamp;
    }

    /**
     * @dev Get student info by NIM
     */
    function getStudentByNIM(
        string memory nim
    )
        public
        view
        returns (address owner, uint256 tokenId, StudentData memory data)
    {
        // TODO: Lookup student by NIM
        require(bytes(nim).length > 0, "NIM cannot be empty");
        tokenId = nimToTokenId[nim];

        require(tokenId != 0, "NIM not found");
        owner = ownerOf(tokenId);
        data = studentData[tokenId];

        return (owner, tokenId, data);
    }

    /**
     * @dev Override transfer functions to make non-transferable
     */
    /**
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        // TODO: Make soulbound (non-transferable)
        // Only allow minting (from == address(0)) and burning (to == address(0))
        // require(from == address(0) || to == address(0), "SID is non-transferable");
        // super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
     */

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Pausable) returns (address) {
        address from = _ownerOf(tokenId);

        if (from != address(0) && to != address(0)) {
            revert("SID is non-transferable");
        }

        return super._update(to, tokenId, auth);
    }

    // Override functions required untuk multiple inheritance
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);

        // TODO: Clean up student data when burning
        delete studentData[tokenId];
        delete nimToTokenId[studentData[tokenId].nim];
        delete addressToTokenId[ownerOf(tokenId)];
    }

    function isValidID(uint256 tokenId) public view returns (bool) {
        if (_ownerOf(tokenId) == address(0)) return false;

        StudentData memory data = studentData[tokenId];
        return data.isActive && !isExpired(tokenId);
    }
}
