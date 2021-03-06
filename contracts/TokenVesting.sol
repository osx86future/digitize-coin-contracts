pragma solidity ^0.4.18;

import "./utils/SafeMath.sol";
import "./interfaces/CutdownToken.sol";

// ----------------------------------------------------------------------------
// TokenVesting for 'Digitize Coin' project based on:
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/TokenVesting.sol
//
// Radek Ostrowski / http://startonchain.com / https://digitizecoin.com
// ----------------------------------------------------------------------------

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TokenVesting {
  using SafeMath for uint256;

  event Released(uint256 amount);

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  mapping (address => uint256) public released;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliffInDays duration in days of the cliff in which tokens will begin to vest
   * @param _durationInDays duration in days of the period in which the tokens will vest
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliffInDays, uint256 _durationInDays) public {
    require(_beneficiary != address(0));
    require(_cliffInDays <= _durationInDays);

    beneficiary = _beneficiary;
    duration = _durationInDays * 1 days;
    cliff = _start.add(_cliffInDays * 1 days);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(CutdownToken _token) public {
    uint256 unreleased = releasableAmount(_token);
    require(unreleased > 0);
    released[_token] = released[_token].add(unreleased);
    _token.transfer(beneficiary, unreleased);
    Released(unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(CutdownToken _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(CutdownToken _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}
