// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Project.sol";

contract ProjectFactory is Ownable {
    uint public numOfProjects;

    mapping(uint => address) public projects;

    //===== Events =====//

    event Failure(string message);
    event ProjectCreated(uint id, string title, address addr, address creator);
    event ContributionSent(
        address projectAddress,
        address contributor,
        uint amount
    );

    //===== Modifiers =====//
    constructor() {
        numOfProjects = 0;
        transferOwnership(msg.sender);
    }

    /**
     * Create a new Project contract
     * [0] -> new Project contract address
     */
    function createProject(
        uint _fundingGoal,
        uint _deadline,
        string memory _title
    ) public payable returns (Project projectAddress) {
        require(
            _fundingGoal >= 0,
            "Project funding goal must be greater than 0"
        );
        require(
            block.number < _deadline,
            "Project deadline must be greater than the current block"
        );

        Project p = new Project(_fundingGoal, _deadline, _title, msg.sender);
        projects[numOfProjects] = address(p);
        emit ProjectCreated(numOfProjects, _title, address(p), msg.sender);
        numOfProjects++;
        return p;
    }

    /**
     * Allow senders to contribute to a Project by it's address. Calls the fund() function in the Project
     * contract and passes on all value attached to this function call
     * [0] -> contribution was sent
     */
    function contribute(
        address payable _projectAddress
    ) public payable returns (bool successful) {
        // Check amount sent is greater than 0
        require(msg.value > 0, "Contributions must be greater than 0 wei");

        Project deployedProject = Project(_projectAddress);

        // Check that there is actually a Project contract at that address
        require(
            deployedProject.fundingHub() != address(0),
            "Project contract not found at address"
        );

        // Check that fund call was successful
        if (deployedProject.fund{value: msg.value}(msg.sender)) {
            emit ContributionSent(_projectAddress, msg.sender, msg.value);
            return true;
        } else {
            emit Failure("Contribution did not send successfully");
            return false;
        }
    }

    function kill() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    //===== External Functions =====//
    fallback() external payable {
        return;
    }

    receive() external payable {
        return;
    }
}
