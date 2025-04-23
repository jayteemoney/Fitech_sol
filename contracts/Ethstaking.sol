// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthStaking is Ownable {
    IERC20 public fitechToken; // Fitech token contract
    uint256 public rewardRate = 10; // 10 FIT tokens per ETH per staking period
    uint256 public stakingPeriod = 30 days; // Staking duration

    struct Stake {
        uint256 amount; // Staked ETH amount
        uint256 timestamp; // When staking began
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address _fitechToken, address initialOwner) Ownable(initialOwner) {
        fitechToken = IERC20(_fitechToken);
    }

    // Stake ETH
    function stake() external payable {
        require(msg.value > 0, "Must stake some ETH");
        require(stakes[msg.sender].amount == 0, "Already staking");

        stakes[msg.sender] = Stake(msg.value, block.timestamp);
        emit Staked(msg.sender, msg.value, block.timestamp);
    }

    // Unstake ETH and claim rewards
    function unstake() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        require(block.timestamp >= userStake.timestamp + stakingPeriod, "Staking period not over");

        uint256 reward = calculateReward(msg.sender);
        uint256 stakedAmount = userStake.amount;

        // Reset stake
        delete stakes[msg.sender];
        rewards[msg.sender] += reward;

        // Transfer ETH back to user
        (bool sent, ) = payable(msg.sender).call{value: stakedAmount}("");
        require(sent, "Failed to send ETH");

        emit Unstaked(msg.sender, stakedAmount, reward);
    }

    // Claim accumulated rewards
    function claimRewards() external {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        require(fitechToken.transfer(msg.sender, reward), "Reward transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    // Calculate reward based on staked amount
    function calculateReward(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        if (userStake.amount == 0) return 0;
        return (userStake.amount * rewardRate) / 1 ether; // Reward in FIT tokens
    }

    // Fund contract with FIT tokens for rewards (owner only)
    function fundRewards(uint256 amount) external onlyOwner {
        require(fitechToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }
}