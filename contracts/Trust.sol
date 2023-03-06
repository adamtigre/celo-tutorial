// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Trust {
    struct Bond {
        uint256 id;
        string name;
        uint256 amount;
        address creator;
        address[2] parties;
        address[2] confirmations;
        bool signed;
        bool validated;
        bool completed;
    }
    uint256 ids;
    address payable immutable admin;
    uint256 adminFees;
    mapping(uint256 => Bond) bonds;

    event CreateBond(
        uint256 id,
        string name,
        address indexed party1,
        address indexed party2
    );

    constructor() {
        admin = payable(msg.sender);
    }

    /**
        * @dev Validation checks are performed on the input data to prevent invalid data to be stored
        * @notice Allows users to create a bond
        * @param _name Name of bond
        * @param _expectedAmount Amount the second party has to pay
        * @param _secondParty Address of the second party
     */
    function createBond(
        string calldata _name,
        uint256 _expectedAmount,
        address _secondParty
    ) public {
        require(_secondParty != address(0), "Invalid second party");
        require(_expectedAmount > 0, "Invalid amount");
        require(bytes(_name).length > 0, "Empty name");
        address[2] memory parties = [msg.sender, _secondParty];
        address[2] memory confirmations = [address(0), address(0)];
        uint256 amount = _expectedAmount * 1 ether; // amount is converted to ether
        bonds[ids] = Bond(
            ids,
            _name,
            amount,
            msg.sender,
            parties,
            confirmations,
            false,
            false,
            false
        );
        emit CreateBond(ids, _name, msg.sender, _secondParty);
        ids++;
    }

    /**
        * @dev Only second parties have access to sign their respective bonds
        * @notice Allows the second party to sign a bond
        * @param _bondId ID of the bond
     */
    function signBond(uint256 _bondId) public {
        Bond storage bond = bonds[_bondId];
        require(
            msg.sender == bond.parties[1],
            "Only second party can sign bond"
        );
        bond.signed = true;
    }

    /**
        * @dev Only the admin has access to validate bonds
        * @notice Allows the admin to validate a bond
        * @param _bondId ID of the bond
     */
    function validateBond(uint256 _bondId) public {
        Bond storage bond = bonds[_bondId];
        require(msg.sender == admin, "Only admin can validate bond");
        require(
            bond.signed == true,
            "Bond has not been signed by second party before it can be validated"
        );
        bond.validated = true;
    }

    /**
        * @dev Only the two parties involved in a bond can make confirmations
        * @notice Allows both parties of a bond to confirm their part of the deal
        * @param _bondId ID of the bond
     */
    function makeConfirmation(uint256 _bondId) public payable {
        Bond storage bond = bonds[_bondId];
        require(bond.signed == true, "Bond not signed yet");
        require(bond.validated = true, "Bond not validated yet");
        address creator = bond.parties[0];
        address secondParty = bond.parties[1];
        require(
            (msg.sender == creator) || (msg.sender == secondParty),
            "Only the two parties involved can make confirmations"
        );
        // First space of confirmation is reserved for bond creator
        // Second space of confirmation is reserved for second party
        if (msg.sender == creator) {
            // confirm that bond creator has send goods and receive funds
            bond.confirmations[0] = msg.sender;
        } else if (msg.sender == secondParty) {
            // confirm that goods is received and funds sent
            require(msg.value == bond.amount, "Please send the correct amount");
            bond.confirmations[1] = msg.sender;
        }
    }

    /**
        * @dev 90% of the bond's amount is sent to the bond creator and the remaining 10% stays in the smart contract as platform fees
        * @notice Allows the admin to confirm and close a bond
        * @notice Both parties have to first confirm their part of the deal
        * @param _bondId ID of the bond
     */
    function closeBond(uint256 _bondId) public {
        Bond storage bond = bonds[_bondId];
        require(payable(msg.sender) == admin, "Only admin can close bond");
        require(bond.validated == true, "Bond has not been validated yet");
        require(
            bond.confirmations[0] != address(0),
            "First party has not confirmed transaction"
        );
        require(
            bond.confirmations[1] != address(0),
            "Second party has not confirmed transaction"
        );
        require(bond.completed == false, "Bond is closed.");

        // First transfer funds to first party
        // 10% of funds is deducted for platform fee
        address payable firstParty = payable(bond.parties[0]);
        uint256 fund = (bond.amount * 90) / 100;
        adminFees += (bond.amount * 10) / 100; // reserve 10% for platform fee
        bond.completed = true;
        (bool success, ) = firstParty.call{value: fund}("");
        require(success, "Failed to send funds to second party");
        
    }

    // Get total balance stored in the contract
    function getContractBalance() public view returns (uint256) {
        require(msg.sender == admin, "Only admin can check balance");
        uint256 bal = address(this).balance;
        return bal;
    }

    // Get total fees reserved for platform
    function getTotalAdminFees() public view returns (uint256) {
        require(msg.sender == admin, "Only admin can check fees");
        return adminFees;
    }

    /**
        * @dev Only the admin can withdraw accumulated fees
        * @notice Withdraws accumulated fees in the smart contract
     */
    function withdrawAccumulatedFees() public returns (bool) {
        require(
            msg.sender == admin,
            "Only admin can withdraw accumulated fees"
        );
        uint256 bal = adminFees;
        adminFees = 0; // reset value before withdrawal
        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Transfer failed");
        return success;
    }

    // View details about a bond
    function viewBond(uint256 _bondId)
        public
        view
        returns (
            string memory name,
            uint256 amount,
            address creator,
            bool signed,
            bool validated,
            bool completed
        )
    {
        Bond memory bond = bonds[_bondId];
        name = bond.name;
        amount = bond.amount;
        creator = bond.creator;
        signed = bond.signed;
        validated = bond.validated;
        completed = bond.completed;
    }
}
