pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract GuildBank is Ownable {
    using SafeMath for uint256;

    ERC20 public approvedToken; // approved token contract reference

    event Deposit(uint256 amount);
    event Withdrawal(address indexed receiver, uint256 amount);

    constructor(address approvedTokenAddress) public {
        approvedToken = ERC20(approvedTokenAddress);
    }

    function deposit(uint256 amount) public onlyOwner returns (bool) {
        emit Deposit(amount);
        return approvedToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address receiver, uint256 shares, uint256 totalShares) public onlyOwner returns (bool) {
        uint256 amount = approvedToken.balanceOf(address(this)).mul(shares).div(totalShares);
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }
}