// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Project.sol";

contract ProjectFactory is Ownable {
    uint public numOfProjects;

    mapping(uint => address) public projects;
    mapping(uint256 => ProjectItem) private idToProject;

    struct ProjectItem {
        string title;
        uint256 goal;
        uint256 deadline;
        address payable creator;
        uint256 totalFunding;
        uint256 contributionsCount;
        uint256 contributorsCount;
        address payable fundingHub;
        address payable projectAddress;
        string metaUrl;
    }

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
        string memory _title,
        string memory _metaUrl
    ) public payable returns (Project projectAddress) {
        require(_fundingGoal >= 0, "less than 0");
        require(block.number < _deadline, "less than current block");

        Project p = new Project(
            numOfProjects,
            _fundingGoal,
            _deadline,
            _title,
            msg.sender,
            _metaUrl
        );
        projects[numOfProjects] = address(p);

        addStress(address(p));

        emit ProjectCreated(numOfProjects, _title, address(p), owner());
        numOfProjects++;
        return p;
    }

    function addStress(address p) private {
        Project newProject = Project(payable(address(p)));

        uint pId;
        string memory pTitle;
        uint pGoal;
        uint pDeadline;
        address pCreator;
        string memory pMetaUrl;

        (
            pId,
            pTitle,
            pGoal,
            pDeadline,
            pCreator,
            ,
            ,
            ,
            ,
            ,
            pMetaUrl
        ) = newProject.getProject();

        idToProject[numOfProjects] = ProjectItem(
            pTitle,
            pGoal,
            pDeadline,
            payable(pCreator),
            0,
            0,
            0,
            payable(address(this)),
            payable(address(p)),
            pMetaUrl
        );
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
        require(msg.value > 0, "less than 0 wei");

        Project deployedProject = Project(_projectAddress);

        // Check that there is actually a Project contract at that address
        require(
            deployedProject.fundingHub() != address(0),
            "address not found"
        );

        // Check that fund call was successful
        if (deployedProject.fund{value: msg.value}(msg.sender)) {
            emit ContributionSent(_projectAddress, msg.sender, msg.value);
            updateProjectItem(_projectAddress);
            return true;
        } else {
            emit Failure("Contribution did not send successfully");
            return false;
        }
    }

    function fetchProjectItems() public view returns (ProjectItem[] memory) {
        uint256 itemCount = numOfProjects;
        uint256 currentIndex = 0;

        ProjectItem[] memory items = new ProjectItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i;
            ProjectItem storage currentItem = idToProject[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function updateProjectItem(address projectAddress) private {
        Project newProject = Project(payable(address(projectAddress)));

        uint pId;
        uint pTotalFunding;
        uint pContributionsCount;
        uint pContributorsCount;

        (
            pId,
            ,
            ,
            ,
            ,
            pTotalFunding,
            pContributionsCount,
            pContributorsCount,
            ,
            ,

        ) = newProject.getProject();

        idToProject[pId].totalFunding = pTotalFunding;
        idToProject[pId].contributionsCount = pContributionsCount;
        idToProject[pId].contributorsCount = pContributorsCount;
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
