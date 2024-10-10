// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title LevelUpsToken Contract
/// @author Alexander Tikadze
/// @notice This contract implements a gamified ERC20 token where users can claim tokens and level up.
/// @dev The token is based on OpenZeppelin's ERC20 implementation with additional game mechanics.
contract LevelUpsToken is ERC20
{
    /// @notice Minimum period to be elapsed for the tokens to be claimed
    uint256 constant tokensClaimMinTimeElapsed = 1 hours;

    /// @notice Initial amount of tokens given to a player upon creation
    uint256 constant initialTokens = 175;
    
    /// @notice Mapping to store player details by their address
    mapping(address => Player) public players;

    /// @notice Event triggered when a new player is created
    /// @param player Address of the new player
    /// @param timestamp Timestamp when the event emitted
    event PlayerCreated(address indexed player, uint256 timestamp);

    /// @notice Event triggered when a player claims tokens
    /// @param player Address of the player claiming tokens
    /// @param rewardAmount Amount of tokens claimed
    /// @param timestamp Timestamp when the event emitted
    event TokensClaimed(address indexed player, uint256 rewardAmount, uint256 timestamp);

    /// @notice Event triggered when a player levels up
    /// @param player Address of the player leveling up
    /// @param newLevel New level achieved by the player
    /// @param timestamp Timestamp when the event emitted
    event LevelUpgraded(address indexed player, uint256 newLevel, uint256 timestamp);

    /// @notice Custom error thrown when a player is not found by the given address
    error PlayerNotFound(address player);

    /// @notice Custom error thrown when attempting to create a player that already exists
    error PlayerAlreadyExists(address player);

    /// @notice Custom error thrown when attempting to level up, but the user can't afford it
    error CantAffordLevelUp();

    /// @notice Modifier to ensure that a player exists
    /// @param _player Address of the player
    modifier playerMustExist(address _player)
    {
        if (players[_player].level == 0)
            revert PlayerNotFound(_player);
            
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
    /// @return _cost The cost in tokens to level up to the given level
    function getLevelCost(uint256 _level) public pure returns(uint256 _cost)
    {
        _cost = ((_level - 1) * 10) ** 2;
    }

    /// @notice Calculate the reward given when leveling up
    /// @dev Uses an exponential formula based on the player's level
    /// @param _level The level for which to calculate the reward
    /// @return _reward The reward in tokens for reaching the given level
    function getLevelReward(uint256 _level) public pure returns(uint256 _reward)
    {
        _reward = ((_level - 1) * 5) ** 2;
    }

    /// @notice Calculate the tokens a player can claim per hour
    /// @dev The reward increases with the player's level
    /// @return _reward The amount of tokens claimable per hour
    function getTokenRewardPerHour() public view returns(uint256 _reward)
    {
        _reward = players[msg.sender].level * 5;
    }

    /// @notice Get the current level of a player
    /// @param _player The address of the player to check
    /// @return _level The current level of the player
    function getPlayerLevel(address _player) external view returns(uint256 _level)
    {
        _level = players[_player].level;
    }

    /// @notice Check if a player can afford to level up
    /// @return _canAfford true if the player can afford to level up, false otherwise
    function affordLevelUp() public view returns(bool _canAfford)
    {
        _canAfford = balanceOf(msg.sender) >= getLevelCost(players[msg.sender].level + 1);
    }

    /// @notice Create a new player with initial tokens and level 1
    /// @dev This can only be done once per address
    function createPlayer() external
    {
        if (players[msg.sender].level > 0)
            revert PlayerAlreadyExists(msg.sender);

        players[msg.sender] = Player(1, block.timestamp);
        _mint(msg.sender, initialTokens);

        emit PlayerCreated(msg.sender, block.timestamp);
    }

    /// @notice Claim tokens based on the time elapsed since the last claim
    /// @dev The longer the time since the last claim, the more tokens are rewarded
    /// @return _rewardTokens The amount of tokens claimed
    function claimTokens() external playerMustExist(msg.sender) returns(uint256 _rewardTokens)
    {
        Player storage _player = players[msg.sender];
        
        uint256 _elapsedSeconds = block.timestamp - _player.lastTokenClaim;

        require(_elapsedSeconds >= tokensClaimMinTimeElapsed, "At least 1 hour must elapse until you can claim your tokens!");
        
        _player.lastTokenClaim = block.timestamp;
        
        _rewardTokens = (_elapsedSeconds * getTokenRewardPerHour()) / tokensClaimMinTimeElapsed;
        _mint(msg.sender, _rewardTokens);

        emit TokensClaimed(msg.sender, _rewardTokens, block.timestamp);
    }

    /// @notice Level up the player if they can afford it and reward them with tokens
    function levelUp() external playerMustExist(msg.sender)
    {
        if (!affordLevelUp())
            revert CantAffordLevelUp();
        
        uint256 _newLevel = ++players[msg.sender].level;

        _burn(msg.sender, getLevelCost(_newLevel));
        _mint(msg.sender, getLevelReward(_newLevel));

        emit LevelUpgraded(msg.sender, _newLevel, block.timestamp);
    }
}