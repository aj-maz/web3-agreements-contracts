pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./interfaces/IArbitrator.sol";
import "./interfaces/IArbitrable.sol";
import "./interfaces/IERC20.sol";

contract Agreement is IArbitrable {
    event ChangeStatus(Status status);

    IArbitrator public arbitrator;
    address public asset;

    address payable public employer;
    address payable public employee;
    string public agreementURI;
    uint256 public prize;

    enum Status {
        Initialized,
        Started,
        Dued,
        Finalized,
        Resolved,
        Reclaimed,
        Disputed
    }

    Status public status;

    uint256 public createdAt;
    uint256 public dueDate;
    uint256 public reclaimedAt;
    uint256 public constant reclaimationPeriod = 5 minutes;
    uint256 public constant arbitrationFeeDepositPeriod = 5 minutes;

    enum RulingOptions {
        RefusedToArbitrate,
        EmployerWins,
        EmployeeWins
    }
    uint256 constant numberOfRulingOptions = 2;

    constructor(
        address payable _employee,
        string memory _agreementURI,
        uint256 _prize,
        address _asset,
        uint256 _dueDate,
        IArbitrator _arbitrator
    ) {
        employer = payable(msg.sender);
        employee = _employee;
        arbitrator = _arbitrator;
        agreementURI = _agreementURI;
        createdAt = block.timestamp;
        status = Status.Initialized;
        asset = _asset;
        prize = _prize;
        dueDate = _dueDate;
    }

    modifier onlyEmployer() {
        require(msg.sender == employer, "Only employer can run ");
        _;
    }

    modifier onlyEmployee() {
        require(msg.sender == employee);
        _;
    }

    modifier onlyParticipants() {
        require(msg.sender == employer || msg.sender == employee);
        _;
    }

    function start() public {
        // find a token address

        IERC20 token = IERC20(asset);

        // require contract to have enough balance
        require(
            token.balanceOf(address(this)) >= prize,
            "You need to deposit the prize to the aave on behalf of this contract"
        );

        require(
            status == Status.Initialized,
            "Only initialized agreements are startable"
        );

        // change contract status
        status = Status.Started;

        // trigger an event
        emit ChangeStatus(Status.Started);
        // check whether contract is funded by enough aTokens or not
    }

    function dued() public {
        // TODO the gelato must be do it;
        require(
            status == Status.Started,
            "Only started agreements are dueable"
        );
        require(block.timestamp > dueDate, "Not still the due of agreement");
        status = Status.Dued;
        emit ChangeStatus(Status.Dued);
    }

    function finalize() public {
        // Employer can Always do it
        require(status == Status.Dued, "Only dued agreements are finalizable");
        require(
            msg.sender == employer ||
                block.timestamp > dueDate + reclaimationPeriod,
            "It's too soon to finalize the agreement"
        );
        // Check whether time has come
        payEmployee();
        // Check whether status is Started
        status = Status.Finalized;
        emit ChangeStatus(Status.Finalized);
    }

    function payEmployee() private {
        IERC20 token = IERC20(asset);

        token.transfer(employee, prize);
        employee.transfer(address(this).balance);
    }

    function reclaimPayment() private {
        IERC20 token = IERC20(asset);
        token.transfer(employer, prize);
        employer.transfer(address(this).balance);
    }

    function reclaim() public payable onlyEmployer {
        if (status == Status.Reclaimed) {
            require(
                block.timestamp >= arbitrationFeeDepositPeriod + reclaimedAt,
                "Employee still can pay the dispute fee."
            );
            reclaimPayment();
            status = Status.Resolved;
            emit ChangeStatus(Status.Resolved);
        } else {
            require(
                status == Status.Dued,
                "Only dued agreements are reclaimable."
            );
            require(
                block.timestamp > dueDate &&
                    block.timestamp < dueDate + reclaimationPeriod,
                "Dispute is only available in reclaimation period."
            );
            uint256 requiredAmount = arbitrator.arbitrationCost("");
            require(requiredAmount <= msg.value, "Insufficient balance");
            reclaimedAt = block.timestamp;
            status = Status.Reclaimed;
            emit ChangeStatus(Status.Reclaimed);
        }
    }

    function depositArbitrationFee() public payable onlyEmployee {
        require(
            status == Status.Reclaimed,
            "You can only deposit arbitration fee into disputed agreements."
        );
        require(
            reclaimedAt + arbitrationFeeDepositPeriod < block.timestamp,
            "Arbitration fee deposit period is finished"
        );
        uint256 requiredAmount = arbitrator.arbitrationCost("");
        require(requiredAmount <= msg.value, "Insufficient balance");
        arbitrator.createDispute{value: requiredAmount}(
            numberOfRulingOptions,
            ""
        );
        status = Status.Disputed;
        emit ChangeStatus(Status.Disputed);
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        require(msg.sender == address(arbitrator), "Only arbitrator can rule.");
        require(status == Status.Disputed, "Invalid Status.");
        require(_ruling < numberOfRulingOptions, "Invalid Ruling");

        status = Status.Resolved;
        if (_ruling == uint256(RulingOptions.EmployeeWins)) payEmployee();
        else if (_ruling == uint256(RulingOptions.EmployerWins))
            reclaimPayment();
        status = Status.Resolved;
        emit Ruling(arbitrator, _disputeID, _ruling);
        emit ChangeStatus(Status.Resolved);
    }

    function remainingTimeToReclaim() public view returns (uint256) {
        require(status == Status.Dued, "Invalid Status");
        return
            (block.timestamp - createdAt) > reclaimationPeriod
                ? 0
                : (createdAt + reclaimationPeriod - block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee()
        public
        view
        returns (uint256)
    {
        require(status == Status.Reclaimed, "Invalid Status");

        return
            (block.timestamp - reclaimedAt) > arbitrationFeeDepositPeriod
                ? 0
                : (reclaimedAt + arbitrationFeeDepositPeriod - block.timestamp);
    }
}
