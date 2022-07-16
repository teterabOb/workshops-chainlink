// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//Programa
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Staking {

    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    
    mapping(address => uint256) public s_balances;    
    mapping(address => uint256) public s_userRewardPerTokenPaid;    
    mapping(address => uint256) public s_rewards;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account){
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount){        
        require(amount > 0, "Amount debe ser mayor que cero");
        _;
    }

    constructor(address stakingToken, address rewardToken){
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }    
    function earned(address account) public view returns(uint256){        
        uint256 currentBalance = s_balances[account];        
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 totalEarned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return totalEarned;

    }
    function rewardPerToken() public view returns(uint256){
        if(s_totalSupply == 0){
            return s_rewardPerTokenStored;
        }

        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    function stake(uint256 amount) updateReward(msg.sender) moreThanZero(amount) external {
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;        
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stake: Fallo la tx");        
    }

    function withdraw(uint256 amount) updateReward(msg.sender) moreThanZero(amount) external{
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        require(success, "Withdraw: Fallo la tx");
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        bool success = s_rewardToken.transfer(msg.sender, reward);
        require(success, "ClaimReward: No hay reward para reclamar!");
    }


}