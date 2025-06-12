// ignition/modules/TokenSuite.js
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TokenSuiteModule", (m) => {
    // Deploy ERC-20: CampusCredit
    const campusCredit = m.contract("CampusCredit");

    // Deploy ERC-721: StudentID
    const studentID = m.contract("StudentID");

    // Deploy ERC-1155: CourseBadge
    const courseBadge = m.contract("CourseBadge");

    // Optional: Setup initial configuration
    m.call(campusCredit, "registerMerchant", [
        "0x23686f799e7C1E8158208882bAD2BD90A5C59256",
        "Kafetaria Kampus"
    ]);

    return { campusCredit, studentID, courseBadge };
});