// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Project {
    struct Properties {
        uint id;
        uint goal;
        uint deadline;
        string title;
        address creator;
        string metaurl;
    }

    struct Contribution {
        uint amount;
        address contributor;
    }

    address public fundingHub;

    mapping(address => uint) public contributors;
    mapping(uint => Contribution) public contributions;

    uint public totalFunding;
    uint public contributionsCount;
    uint public contributorsCount;

    Properties public properties;

    event LogContributionReceived(
        address projectAddress,
        address contributor,
        uint amount
    );
    event LogPayoutInitiated(
        address projectAddress,
        address owner,
        uint totalPayout
    );
    event LogRefundIssued(
        address projectAddress,
        address contributor,
        uint refundAmount
    );
    event LogFundingGoalReached(
        address projectAddress,
        uint totalFunding,
        uint totalContributions
    );
    event LogFundingFailed(
        address projectAddress,
        uint totalFunding,
        uint totalContributions
    );

    event LogFailure(string message);

    modifier onlyFundingHub() {
        require(
            fundingHub == msg.sender,
            "Not FundingHub"
        );
        _;
    }

    modifier onlyFunded() {
        require(totalFunding >= properties.goal, "not funded");
        _;
    }

    constructor(
        uint _projectId,
        uint _fundingGoal,
        uint _deadline,
        string memory _title,
        address _creator,
        string memory _metaUrl
    ) {
        // Check to see the funding goal is greater than 0
        require(
            _fundingGoal > 0,
            "goal less than 0"
        );

        // Check to see the deadline is in the future
        require(
            block.number < _deadline,
            "less than current block"
        );

        // Check to see that a creator (payout) address is valid
        require(
            _creator != address(0),
            "invalid creator address"
        );

        fundingHub = msg.sender;

        // initialize properties struct
        properties = Properties({
            id: _projectId,
            goal: _fundingGoal,
            deadline: _deadline,
            title: _title,
            creator: _creator,
            metaurl: _metaUrl
        });

        totalFunding = 0;
        contributionsCount = 0;
        contributorsCount = 0;
    }

    /**
     * Project values are indexed in return value:
     * [0] -> Project.properties.id
     * [1] -> Project.properties.title
     * [2] -> Project.properties.goal
     * [3] -> Project.properties.deadline
     * [4] -> Project.properties.creator
     * [5] -> Project.totalFunding
     * [6] -> Project.contributionsCount
     * [7] -> Project.contributorsCount
     * [8] -> Project.fundingHub
     * [9] -> Project (address)
     * [9] -> Project.properties.metaurl
     */
    function getProject()
        public
        view
        returns (
            uint,
            string memory,
            uint,
            uint,
            address,
            uint,
            uint,
            uint,
            address,
            address,
            string memory
        )
    {
        return (
            properties.id,
            properties.title,
            properties.goal,
            properties.deadline,
            properties.creator,
            totalFunding,
            contributionsCount,
            contributorsCount,
            fundingHub,
            address(this),
            properties.metaurl
        );
    }

    /**
     * Retrieve indiviual contribution information
     * [0] -> Contribution.amount
     * [1] -> Contribution.contributor
     */
    function getContribution(uint _id) public view returns (uint, address) {
        Contribution memory c = contributions[_id];
        return (c.amount, c.contributor);
    }

    /**
     * This is the function called when the FundingHub receives a contribution.
     * If the contribution was sent after the deadline of the project passed,
     * or the full amount has been reached, the function must return the value
     * to the originator of the transaction.
     * If the full funding amount has been reached, the function must call payout.
     * [0] -> contribution was made
     */
    function fund(
        address _contributor
    ) public payable returns (bool successful) {
        // Check amount is greater than 0
        require(
            msg.value > 0,
            "less than 0 wei"
        );

        // Check funding only comes thru fundingHub
        require(
            msg.sender == fundingHub,
            "not FundingHub contract"
        );

        // 1. Check that the project dealine has not passed
        if (block.number > properties.deadline) {
            emit LogFundingFailed(
                address(this),
                totalFunding,
                contributionsCount
            );
            if (!payable(_contributor).send(msg.value)) {
                emit LogFailure(
                    "Project deadline has passed, problem returning contribution"
                );
                revert();
            }
            return false;
        }

        // 2. Check that funding goal has not already been met
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );
            if (!payable(_contributor).send(msg.value)) {
                emit LogFailure(
                    "Project deadline has passed, problem returning contribution"
                );
                revert();
            }
            payout();
            return false;
        }

        // determine if this is a new contributor
        uint prevContributionBalance = contributors[_contributor];

        // Add contribution to contributions map
        Contribution memory c = contributions[contributionsCount];
        c.contributor = _contributor;
        c.amount = msg.value;

        // Update contributor's balance
        contributors[_contributor] += msg.value;

        totalFunding += msg.value;
        contributionsCount++;

        // Check if contributor is new and if so increase count
        if (prevContributionBalance == 0) {
            contributorsCount++;
        }

        emit LogContributionReceived(address(this), _contributor, msg.value);

        // Check again to see whether the last contribution met the fundingGoal
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );
            payout();
        }

        return true;
    }

    /**
     * If funding goal has been met, transfer fund to project creator
     * [0] -> payout was successful
     */
    function payout() public payable onlyFunded returns (bool successful) {
        uint amount = totalFunding;

        // prevent re-entrancy
        totalFunding = 0;

        if (payable(properties.creator).send(amount)) {
            return true;
        } else {
            totalFunding = amount;
            return false;
        }
    }

    /**
     * If the deadline is passed and the goal was not reached, allow contributors to withdraw their contributions.
     * This is slightly different that the final project requirements, see README for details
     * [0] -> refund was successful
     */
    function refund() public payable returns (bool successful) {
        // Check that the project dealine has passed
        require(
            block.number > properties.deadline,
            "past deadline"
        );

        // Check that funding goal has not already been met
        require(
            totalFunding < properties.goal,
            "project has met goal"
        );

        uint amount = contributors[msg.sender];

        //prevent re-entrancy attack
        contributors[msg.sender] = 0;

        if (payable(msg.sender).send(amount)) {
            emit LogRefundIssued(address(this), msg.sender, amount);
            return true;
        } else {
            contributors[msg.sender] = amount;
            emit LogFailure("Refund did not send successfully");
            return false;
        }
    }

    function kill() public onlyFundingHub {
        selfdestruct(payable(fundingHub));
    }

    //===== External Functions =====//
    fallback() external payable {
        return;
    }

    receive() external payable {
        return;
    }
}
