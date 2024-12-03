// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract RentalAgreementManagement {
    using Counters for Counters.Counter;
    // record the agreement id
    Counters.Counter private _agreementIds;

    // unactive which is the default value of this enum means there is no data of current agreement
    enum AgreementStatus { Unactive, Active, Terminated }

    struct Agreement {
        // agreement's landlord, only landlord can terminate the agreement
        address landlord;
        address tenant;
        uint256 rentAmount;
        uint256 duration;
        uint256 startTime;
        AgreementStatus status;
        // to record the payment count for tenant
        uint256 paymentCount;
    }

    // agreements mapping, the key is index from 1 to uint256
    mapping(uint256 => Agreement) public agreements;
    // payment count and its payment timestamp of each agreement, agreementId => paymentCount => payment timestamp
    mapping(uint256 => mapping(uint256 => uint256)) public paymentHistory; 

    // log key actions like agreement creation, rent payments and termination
    event AgreementCreated(uint256 agreementId, address indexed landlord, address indexed tenant, uint256 rentAmount, uint256 duration);
    event RentPaid(uint256 agreementId, address indexed tenant, uint256 amount, uint256 timestamp);
    event AgreementTerminated(uint256 agreementId, address indexed landlord, bool durationEnd);

    // landlords can create agreements specifying tenant details, rent, and duration.    
    function createAgreement(address tenant, uint256 rentAmount, uint256 duration) public {
        _agreementIds.increment();
        uint256 newAgreementId = _agreementIds.current();

        agreements[newAgreementId] = Agreement({
            landlord: msg.sender,
            tenant: tenant,
            rentAmount: rentAmount,
            duration: duration,
            startTime: block.timestamp,
            status: AgreementStatus.Active,
            paymentCount: 0
        });

        // log
        emit AgreementCreated(newAgreementId, msg.sender, tenant, rentAmount, duration);
    }

    // allows the tenant to pay rent. The payment amount must match the rent amount specified in the agreement.
    // tenant can pay rent not only once.
    function payRent(uint256 agreementId) public payable {
        Agreement storage agreement = agreements[agreementId];

        require(agreement.status == AgreementStatus.Active, "Agreement is not active");
        require(msg.sender == agreement.tenant, "Only tenant can pay rent");
        require(msg.value == agreement.rentAmount, "Incorrect rent amount");

        // transfer the payment to landlord
        payable(agreement.landlord).transfer(msg.value);

        // increase payment count
        agreement.paymentCount++;
        // record payment history
        paymentHistory[agreementId][agreement.paymentCount] = block.timestamp;

        // log
        emit RentPaid(agreementId, msg.sender, msg.value, block.timestamp);
    }

    // allows the landlord to terminate the agreement. The agreement can be terminated anytime by the landlord as there maybe some violations
    function terminateAgreement(uint256 agreementId) public {
        Agreement storage agreement = agreements[agreementId];

        require(msg.sender == agreement.landlord, "Only landlord can terminate agreement");
        require(agreement.status == AgreementStatus.Active, "Agreement is already terminated");

        agreement.status = AgreementStatus.Terminated;

        // log the termination of agreement, especially whether the agreement is end or not
        bool durationEnd = block.timestamp >= agreement.startTime + agreement.duration;
        emit AgreementTerminated(agreementId, msg.sender, durationEnd);
    }

    // returns the status of the rental agreement (either "Active" or "Terminated").
    function getAgreementStatus(uint256 agreementId) public view returns (string memory) {

        Agreement storage agreement = agreements[agreementId];

        if (agreement.status == AgreementStatus.Active) {
            return "Active";
        } else if (agreement.status == AgreementStatus.Terminated) {
            return "Terminated";
        } else {
            return "Unknown";
        }
    }
}
