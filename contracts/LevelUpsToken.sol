// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title LevelUpsToken Contract
/// @author Alexander Tikadze
/// @notice This contract implements a gamified ERC20 token where users can claim tokens and level up.
/// @dev The token is based on OpenZeppelin's ERC20 implementation with additional game mechanics.
contract LevelUpsToken is ERC20
{
    /// @notice Mapping to store player details by their address
    mapping(address => Player) public players;

    /// @notice Event triggered when a new player is created
    /// @param player Address of the new player
    event PlayerCreated(address indexed player);

    /// @notice Event triggered when a player claims tokens
    /// @param player Address of the player claiming tokens
    /// @param rewardAmount Amount of tokens claimed
    event TokensClaimed(address indexed player, uint256 rewardAmount);

    /// @notice Event triggered when a player levels up
    /// @param player Address of the player leveling up
    /// @param newLevel New level achieved by the player
    event LevelUpgraded(address indexed player, uint256 newLevel);

    /// @notice Modifier to ensure that a player exists
    /// @param _player Address of the player
    modifier PlayerMustExist(address _player)
    {
        Player memory player = players[_player];
        require(player.level > 0 && player.lastTokenClaim != 0, "Player doesn't exist!");
        _;
    }

    /// @notice Struct to represent a player in the game
    struct Player
    {
        /// @dev The player's current level
        uint256 level;
        
        /// @dev The timestamp of the last token claim
        uint256 lastTokenClaim;
    }

    /// @notice Constructor for initializing the ERC20 token with a name and symbol
    constructor()
    ERC20("LevelUpsToken", "LUT")
    {
    }
    
    /// @notice Calculate the cost required to level up
    /// @dev Uses an exponential formula based on the player's level
    /// @param _level The level for which to calculate the cost
    /// @return The cost in tokens to level up to the given level
    function getLevelCost(uint256 _level) public pure returns(uint256)
    {
        return ((_level - 1) * 10) ** 2;
    }

    /// @notice Calculate the reward given when leveling up
    /// @dev Uses an exponential formula based on the player's level
    /// @param _level The level for which to calculate the reward
    /// @return The reward in tokens for reaching the given level
    function getLevelReward(uint256 _level) public pure returns(uint256)
    {
        return ((_level - 1) * 5) ** 2;
    }

    /// @notice Calculate the tokens a player can claim per hour
    /// @dev The reward increases with the player's level
    /// @return The amount of tokens claimable per hour
    function getTokenRewardPerHour() public view PlayerMustExist(msg.sender) returns(uint256)
    {
        return players[msg.sender].level * 5;
    }

    /// @notice Get the current level of a player
    /// @param _player The address of the player to check
    /// @return The current level of the player
    function getPlayerLevel(address _player) public view PlayerMustExist(_player) returns(uint256) 
    {
        return players[_player].level;
    }

    /// @notice Check if a player can afford to level up
    /// @return true if the player can afford to level up, false otherwise
    function affordLevelUp() public view PlayerMustExist(msg.sender) returns(bool)
    {
        return balanceOf(msg.sender) >= getLevelCost(players[msg.sender].level + 1);
    }

    /// @notice Create a new player with initial tokens and level 1
    /// @dev This can only be done once per address
    function createPlayer() public
    {
        require(players[msg.sender].level == 0, "Player already exists!");

        players[msg.sender] = Player(1, block.timestamp);
        _mint(msg.sender, 175);

        emit PlayerCreated(msg.sender);
    }

    /// @notice Claim tokens based on the time elapsed since the last claim
    /// @dev The longer the time since the last claim, the more tokens are rewarded
    /// @return The amount of tokens claimed
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

    /// @notice Level up the player if they can afford it and reward them with tokens
    function levelUp() public PlayerMustExist(msg.sender)
    {
        require(affordLevelUp(), "You can't afford level up at the moment!");
        
        uint256 newLevel = ++players[msg.sender].level;

        _burn(msg.sender, getLevelCost(newLevel));
        _mint(msg.sender, getLevelReward(newLevel));

        emit LevelUpgraded(msg.sender, newLevel);
    }
}