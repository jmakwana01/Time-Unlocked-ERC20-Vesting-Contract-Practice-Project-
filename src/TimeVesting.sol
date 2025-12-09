//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *@title TimeVesting
 *@dev Payer create a vesting schedule: deposits tokens for a beneficiary
 *      The beneficiary can withdraw up to (total * elapsedDays/durationDays)
 *      Unlock happens in daily chuncks (1 day = 86400 seconds ) after durationDays , all tokens are vested
 */

contract TimeVesting {
    using SafeERC20 for IERC20;

    struct Schedule {
        address token;          //ERC20 token address
        address payer;          //who deposited
        address beneficiary;    //who recieves tokens
        uint256 totalAmount;    //total token deposited
        uint256 start;          //vesting start timestamp
        uint256 durationDays;   //number of days(n)
        uint256 withdrawn;      //amount already withdrawn
        bool exists;            //schedule exists
    }

    //scheduleId=>Schedule 
    mapping(bytes32 => Schedule) public schedules;
    
    event ScheduleCreated(bytes32 indexed id, address indexed payer, address indexed beneficiery);
    event withdrawn(bytes32 indexed id, address indexed beneficiery,uint256 amount);
    event ScheduleCanceled(bytes32 indexed id, address indexed payer, uint256 refunded);


    error ScheduleNotFound();
    error NotBeneficiary();
    error NotPayer();
    error NothingToWithdraw();
    error ZeroAddress();
    error DurationZero();
    error InsufficientAllowance(uint256 allowed);




    function createScheduleAndDeposit(
        address token,
        address beneficiary,
        uint256 totalAmount,
        uint256 startTimeStamp,
        uint256 durationDays
    ) external returns (bytes32){
        if (token==address(0) || beneficiary ==address(0)) revert ZeroAddress();
        if (durationDays==0)revert DurationZero();
        if (totalAmount==0) revert NothingToWithdraw();
        uint256 start = startTimeStamp ==0?block.timestamp:startTimeStamp;

        bytes32 id = _scheduleId(msg.sender,beneficiary,token, start,durationDays,totalAmount);
        if (schedules[id].exists)revert("Schedule already exists");

        //transfer token in 
        IERC20 t = IERC20(token);
        uint256 allowance = t.allowance(msg.sender,address(this));
        if (allowance < totalAmount)revert InsufficientAllowance(allowance);
        t.safeTransferFrom(msg.sender,address(this),totalAmount);

        schedules[id]=Schedule({
            token:token,
            payer:msg.sender,
            beneficiary:beneficiary,
            totalAmount:totalAmount,
            start:start,
            durationDays:durationDays,
            withdrawn:0,
            exists:true
        });

        emit ScheduleCreated(id, msg.sender, beneficiary);
        return id;
    }

    function withdraw(bytes32 scheduleId)external {
        Schedule storage s = schedules[scheduleId];
        if (!s.exists)revert ScheduleNotFound();
        if (msg.sender != s.beneficiary)revert NotBeneficiary();

        uint256 vested = _vestedAmount(s);
        uint256 withdrawable = 0;
        if (vested  > s.withdrawn) withdrawable = vested-s.withdrawn;
        if (withdrawable  ==0)revert NothingToWithdraw();

        s.withdrawn += withdrawable;
        IERC20(s.token).safeTransfer(s.beneficiary,withdrawable);

        emit withdrawn(scheduleId,s.beneficiary,withdrawable);

    }
    function cancelSchedule(bytes32 scheduleId) external {
        Schedule storage s = schedules[scheduleId];
        if (!s.exists) revert ScheduleNotFound();
        if (msg.sender != s.payer) revert NotPayer();


        uint256 vested = _vestedAmount(s);
        uint256 remaining = 0;
        if (s.totalAmount > vested) {
        // unvested amount
        remaining = s.totalAmount - vested;
        }


        s.exists = false; // destroy schedule


        if (remaining > 0) {
        IERC20(s.token).safeTransfer(s.payer, remaining);
        }


        emit ScheduleCanceled(scheduleId, s.payer, remaining);
        }
    function _vestedAmount(Schedule memory s) internal view returns(uint256){
        if (block.timestamp < s.start) return 0;
        uint256 elapsed = block.timestamp - s.start;
        uint256 day = 86400;

        uint256 elapsedDays = elapsed/day;
        if (elapsedDays>=s.durationDays)return s.totalAmount;
        return (s.totalAmount * elapsedDays)/s.durationDays; 
    }

    

    function _scheduleId(
        address payer,
        address beneficiery,
        address token,
        uint256 start,
        uint256 durationDays,
        uint256 totalAmount
    )internal pure returns(bytes32){
        return keccak256(abi.encodePacked(payer,beneficiery,token,start,durationDays,totalAmount));
        
    }

}
