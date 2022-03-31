# Hybrid Setup

Based on chainlink's hardhat starter kit.

Using hardhat for deployment, tasks, contract sizer, contract verification.

Using foundry for easier testing, Mocks setup, evm cheat codes etc.

```yarn test``` copies all hardhat contracts into foundry and runs the foundry tests

# View Contracts Size

```
yarn run hardhat size-contracts
```

# Linting

This will [lint](https://stackoverflow.com/questions/8503559/what-is-linting) your smart contracts.  

```
yarn lint:fix
```

