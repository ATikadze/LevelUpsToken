# Level Ups Token


##### About: 

LevelUpsToken is an ERC20 token contract with a gamified system for players. Each user starts at level 1 and can claim tokens over time, with rewards growing as they level up. The contract uses an exponential formula for both the cost of leveling up and the rewards earned, making progression more challenging and rewarding as players advance.

Players claim tokens based on the time elapsed since their last claim, and they need to spend tokens to reach higher levels. As players level up, they receive token rewards, with the cost of each new level increasing. This dynamic encourages players to manage their tokens strategically while staying engaged over time.

Built on OpenZeppelin's ERC20 implementation, the contract adds custom game mechanics for handling player creation, token claiming, and level progression. The system promotes long-term participation with escalating rewards as players continue to level up.

 #### Testing:

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
```
