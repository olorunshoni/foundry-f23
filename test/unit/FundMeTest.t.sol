//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        //console.log(fundMe.i_owner());
        // console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFieldVersionIsAcurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, version);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    /*
please note that, the immediate code above and the commented code does thesame thing

    function testFailFundWithoutEnoughETH() external {
        fundMe.fund();
    }
*/
    function testFundUpdatesFundedDataFunded() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddFundToArrayOfFunders() public funded {
        // vm.prank(USER);

        address currentFunder = fundMe.getFunder(0);
        console.log("currentFunders: %s USER: %s", currentFunder, USER);
        assertEq(currentFunder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    // function testOwnerAddress() public {
    //     address ownerAddress = fundMe.getOwner();
    //     console.log("owner address", ownerAddress);
    // }

    function testWithdrawWithASingleFunder() public {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        console.log("Starting OFB", startingFundMeBalance);
        console.log("Starting FMB", startingFundMeBalance);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; //79228162514264337593543950335
        uint256 startingFundMeBalance = address(fundMe).balance; //900000000000000000
        // console.log("startingOwnerBalance", startingOwnerBalance);
        // console.log("startingFundMeBalance", startingFundMeBalance);

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // console.log(
        //     "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        // );
        // console.log(
        //     "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        // );
        // uint256 endingOwnerBalance = fundMe.getOwner().balance;//79228162515164337593543950335
        // uint256 endingFundMeBalance = address(fundMe).balance;//0
        // console.log("endingFundMeBalance", endingFundMeBalance);
        // console.log("endingOwnerBalance", endingOwnerBalance);

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
