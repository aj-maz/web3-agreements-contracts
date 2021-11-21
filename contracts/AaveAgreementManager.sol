pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./AaveAgreement.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IArbitrator.sol";

contract AaveAgreementManager {
    AaveAgreement[] public agreements;
    IArbitrator public arbitrator;
    address public asset;
    ILendingPool public aaveLendingPool;

    event AgreementCreated(uint256 agreementId);

    constructor(
        address _asset,
        address _arbitratorAddress,
        address _aaveLendingPoolAddress
    ) {
        arbitrator = IArbitrator(_arbitratorAddress);
        asset = _asset;
        aaveLendingPool = ILendingPool(_aaveLendingPoolAddress);
    }

    function createAgreement(
        address payable _employee,
        string memory _agreementURI,
        uint256 _prize
    ) public {
        AaveAgreement agreement = new AaveAgreement(
            _employee,
            _agreementURI,
            _prize,
            asset,
            block.timestamp + 3 minutes,
            arbitrator,
            aaveLendingPool
        );
        agreements.push(agreement);
        emit AgreementCreated(agreements.length - 1);
    }

    function handleDues() public {
        for(uint i = 0; i < agreements.length; i++) {
            agreements[i].dued();
        }
    }
}
