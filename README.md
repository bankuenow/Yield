# Stacking Rewards Optimizer

A Clarity smart contract that enables users to optimize their Stacking rewards through automated management and compounding features.

## Features

- Stake STX tokens with customizable parameters
- Auto-compound rewards option for maximizing returns
- Flexible reward claiming system
- Built-in reward calculation based on stake amount and duration
- Safety mechanisms to protect user funds

## Contract Functions

### Read-Only Functions

1. `get-user-stake (user principal)`
   - Returns the current stake information for a given user
   - Includes amount, start block, end block, and auto-compound settings

2. `get-user-rewards (user principal)`
   - Returns the reward information for a given user
   - Shows pending rewards, total claimed, and last claim block

3. `calculate-rewards (amount uint) (blocks uint)`
   - Calculates potential rewards based on amount and duration
   - Uses a simplified 10% APY model

### Public Functions

1. `stake-tokens (amount uint) (auto-compound bool)`
   - Stakes STX tokens into the contract
   - Parameters:
     - `amount`: Amount of STX to stake (minimum 50,000)
     - `auto-compound`: Boolean flag for automatic reward compounding

2. `claim-rewards ()`
   - Claims pending rewards
   - Auto-compounds if enabled, otherwise transfers to user

3. `unstake ()`
   - Withdraws staked tokens after staking period ends
   - Automatically claims pending rewards

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized operation
- `ERR-INSUFFICIENT-BALANCE (u101)`: Insufficient balance for operation
- `ERR-NO-ACTIVE-STAKE (u102)`: No active stake found
- `ERR-STAKE-IN-PROGRESS (u103)`: Cannot perform operation while stake is active
- `ERR-BELOW-MINIMUM (u104)`: Stake amount below minimum requirement

## Usage Example

```clarity
;; Stake 100,000 STX with auto-compound enabled
(contract-call? .stacking-optimizer stake-tokens u100000 true)

;; Check current stake
(contract-call? .stacking-optimizer get-user-stake tx-sender)

;; Claim rewards
(contract-call? .stacking-optimizer claim-rewards)

;; Unstake after period ends
(contract-call? .stacking-optimizer unstake)
```

## Security Considerations

1. The contract implements minimum staking amounts to prevent dust attacks
2. All state-changing functions include appropriate checks and balances
3. Mathematical operations are designed to prevent overflow
4. Staking periods are enforced to maintain system stability

## Development and Testing

To deploy and test this contract:

1. Install the Clarinet CLI tool
2. Clone the repository
3. Run `clarinet test` to execute test suite
4. Deploy to testnet for integration testing

## Contributing

Contributions are welcome! Please submit pull requests with:
- Detailed description of changes
- Updated tests
- Documentation updates

