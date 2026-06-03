// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.0;

contract CrowdTank {
    // struct to store project details
    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
    }
    // projectId => project details
    mapping(uint => Project) public projects;
    // projectId => user => contribution amount/funding amount 
    mapping(uint => mapping(address => uint)) public contributions;

    // projectId => whether the id is used or not
    mapping(uint => bool) public isIdUsed;
    mapping(uint => bool) public projectFailureRecorded;
    uint public totalProjectsCreated;
    uint public successfulProjects;
    uint public failedProjects;

    address public admin;
    mapping(address => bool) public creators;


    // events
    event ProjectCreated(uint indexed projectId, address indexed creator, string name, string description, uint fundingGoal, uint deadline);
    event ProjectFunded(uint indexed projectId, address indexed contributor, uint amount);
    event FundsWithdrawn(uint indexed projectId, address indexed withdrawer, uint amount, string withdrawerType);
    // withdrawerType = "user" ,= "admin"
    constructor() {
    admin = msg.sender;
}
function addCreator(address _creator) external {
    require(msg.sender == admin, "Only admin can add creators");

    creators[_creator] = true;
}
function removeCreator(address _creator) external {
    require(msg.sender == admin, "Only admin can remove creators");

    creators[_creator] = false;
}
    // create project by a creator
    // external public internal private
    function createProject(string memory _name, string memory _description, uint _fundingGoal, uint _durationSeconds, uint _id) external {
        require(creators[msg.sender], "Only approved creators can create projects");
        require(!isIdUsed[_id], "Project Id is already used");
        isIdUsed[_id] = true;
        projects[_id] = Project({
        creator : msg.sender,
        name : _name,
        description : _description,
        fundingGoal : _fundingGoal,
        deadline : block.timestamp + _durationSeconds,
        amountRaised : 0,
        funded : false
        });
        totalProjectsCreated++;        
        emit ProjectCreated(_id, msg.sender, _name, _description, _fundingGoal, block.timestamp + _durationSeconds);
    }

    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project deadline is already passed");
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "Must send some value of ether");
        uint remainingAmount = project.fundingGoal - project.amountRaised;

uint acceptedAmount = msg.value;

if(msg.value > remainingAmount){
    acceptedAmount = remainingAmount;

    uint refundAmount = msg.value - remainingAmount;

    payable(msg.sender).transfer(refundAmount);
}

project.amountRaised += acceptedAmount;

contributions[_projectId][msg.sender] += acceptedAmount;

emit ProjectFunded(
    _projectId,
    msg.sender,
    acceptedAmount
);
        if (project.amountRaised >= project.fundingGoal) {
    project.funded = true;
    successfulProjects++;
}
    }

    function userWithdrawFinds(uint _projectId) external {
    Project storage project = projects[_projectId];

    require(
        block.timestamp < project.deadline,
        "Deadline already passed"
    );

    uint fundContributed = contributions[_projectId][msg.sender];

    require(
        fundContributed > 0,
        "No contribution found"
    );

    contributions[_projectId][msg.sender] = 0;

    project.amountRaised -= fundContributed;

    payable(msg.sender).transfer(fundContributed);
}

    function adminWithdrawFunds(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        uint totalFunding = project.amountRaised;
        require(project.funded, "Funding is not sufficient");
        require(project.creator == msg.sender, "Only project admin can withdraw");
        require(project.deadline <= block.timestamp, "Deadline for project is not reached");
        payable(msg.sender).transfer(totalFunding);
    }

    // this is example of a read-only function
    function getFundingPercentage(uint _projectId)
    external
    view
    returns(uint)
{
    Project storage project = projects[_projectId];

    return (project.amountRaised * 100) / project.fundingGoal;
}
function markProjectAsFailed(uint _projectId) external {
    Project storage project = projects[_projectId];

    require(
        block.timestamp > project.deadline,
        "Project deadline not reached"
    );

    require(
        project.amountRaised < project.fundingGoal,
        "Project was successfully funded"
    );
    require(
    !projectFailureRecorded[_projectId],
    "Already marked failed"
);

projectFailureRecorded[_projectId] = true;

    failedProjects++;
}

function getSuccessfulProjects() external view returns(uint){
    return successfulProjects;
}

function getFailedProjects() external view returns(uint){
    return failedProjects;
}
    function isIdUsedCall(uint _id)external view returns(bool){
        return isIdUsed[_id];
    }
}