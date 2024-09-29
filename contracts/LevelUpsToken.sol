// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LevelUpsToken is ERC20
{
    mapping(address => Player) public players;

    event PlayerCreated(address indexed player);
    event TokensClaimed(address indexed player, uint256 rewardAmount);
    event LevelUpgraded(address indexed player, uint256 newLevel);

    modifier PlayerMustExist(address _player)
    {
        Player memory player = players[_player];
        require(player.level > 0 && player.lastTokenClaim != 0, "Player doesn't exist!");
        _;
    }

    struct Player
    {
        uint256 level;
        uint256 lastTokenClaim;
    }

    constructor()
    ERC20("GamifiedToken", "GFT")
    {
    }

    function getLevelCost(uint256 _level) public pure returns(uint256)
    {
        return ((_level - 1) * 10) ** 2;
    }

    function getLevelReward(uint256 _level) public pure returns(uint256)
    {
        return ((_level - 1) * 5) ** 2;
    }

    function getTokenRewardPerHour() public view PlayerMustExist(msg.sender) returns(uint256)
    {
        return players[msg.sender].level * 5;
    }

    function getPlayerLevel(address _player) public view PlayerMustExist(_player) returns(uint256) 
    {
        return players[_player].level;
    }

    function affordLevelUp() public view PlayerMustExist(msg.sender) returns(bool)
    {
        return balanceOf(msg.sender) >= getLevelCost(players[msg.sender].level + 1);
    }

    function createPlayer() public
    {
        require(players[msg.sender].level == 0, "Player already exists!");

        players[msg.sender] = Player(1, block.timestamp);
        _mint(msg.sender, 175);

        emit PlayerCreated(msg.sender);
    }

    function claimTokens() public PlayerMustExist(msg.sender) returns(uint256)
    {
        Player storage player = players[msg.sender];
        
        uint256 elapsedSeconds = block.timestamp - player.lastTokenClaim;

        require(elapsedSeconds >= 1 hours, "At least 1 hour must elapse until you can claim your tokens!");
        
        player.lastTokenClaim = block.timestamp;
        
        uint256 rewardTokens = (elapsedSeconds * getTokenRewardPerHour()) / 1 hours;
        _mint(msg.sender, rewardTokens);

        emit TokensClaimed(msg.sender, rewardTokens);

        return rewardTokens;
    }

    function levelUp() public PlayerMustExist(msg.sender)
    {
        require(affordLevelUp(), "You can't afford level up at the moment!");
        
        uint256 newLevel = ++players[msg.sender].level;

        _burn(msg.sender, getLevelCost(newLevel));
        _mint(msg.sender, getLevelReward(newLevel));

        emit LevelUpgraded(msg.sender, newLevel);
    }
}