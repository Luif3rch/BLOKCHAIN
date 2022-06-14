// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract crux_token is ERC20, Ownable {

  mapping(address => bool) private liquidityPool;
  mapping(address => bool) private whitelistTax;
  mapping(address => uint256) private lastTrade;

  uint8 private sellTax;
  uint8 private buyTax;
  uint8 private transferTax;
  uint8 private tradeCooldown;
  address private rewardsPool;


  event changeTax(uint8 _sellTax, uint8 _buyTax, uint8 _transferTax);
  event changeCooldown(uint8 tradeCooldown);
  event changeLiquidityPoolStatus(address lpAddress, bool status);
  event changeWhitelistTax(address _address, bool status);
  event changeRewardsPool(address rewardsPool);

  constructor() ERC20("CryptoMines Reborn", "CRUXLS") {
    _mint(msg.sender, 5000000 * 1 ether);
    sellTax = 0;
    buyTax = 0;
    transferTax = 0;
    tradeCooldown = 60;
  }

  function setTaxes(uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) external onlyOwner {
    sellTax = _sellTax;
    buyTax = _buyTax;
    transferTax = _transferTax;
    emit changeTax(_sellTax,_buyTax,_transferTax);
  }



  function getTaxes() external pure returns (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) {
    return (_sellTax, _buyTax, _transferTax);
  }



  function setCooldownForTrades(uint8 _tradeCooldown) external onlyOwner {
    tradeCooldown = _tradeCooldown;
    emit changeCooldown(_tradeCooldown);
  }




  function setLiquidityPoolStatus(address _lpAddress, bool _status) external onlyOwner {
    liquidityPool[_lpAddress] = _status;
    emit changeLiquidityPoolStatus(_lpAddress, _status);
  }



  function setWhitelist(address _address, bool _status) external onlyOwner {
    whitelistTax[_address] = _status;
    emit changeWhitelistTax(_address, _status);
  }



  function setRewardsPool(address _rewardsPool) external onlyOwner {
    rewardsPool = _rewardsPool;
    emit changeRewardsPool(_rewardsPool);
  }

  

  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    uint256 taxAmount;
    if(liquidityPool[sender] == true) {
      //It's an LP Pair and it's a buy
      taxAmount = (amount * buyTax) / 100;
    } else if(liquidityPool[receiver] == true) {      
      //It's an LP Pair and it's a sell
      taxAmount = (amount * sellTax) / 100;

      require(lastTrade[sender] < (block.timestamp - tradeCooldown), string("No consecutive sells allowed. Please wait."));
      lastTrade[sender] = block.timestamp;

    } else if(whitelistTax[sender] || whitelistTax[receiver] || sender == rewardsPool || receiver == rewardsPool) {
      taxAmount = 0;
    } else {
      taxAmount = (amount * transferTax) / 100;
    }
    
    if(taxAmount > 0) {
      super._transfer(sender, rewardsPool, taxAmount);
    }    
    super._transfer(sender, receiver, amount - taxAmount);
  }

  function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
    require(_to != address(this), string("No transfers to contract allowed."));    
    super._beforeTokenTransfer(_from, _to, _amount);
  }

}