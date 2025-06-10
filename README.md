# BlockDev x Monad Web3 Workshop – Proyek Web3

This repository contains smart contract projects and learning resources for the BlockDevId x Monad Batch 3 (OFFLINE) developer workshop, held at Indodax Pondok Indah, Jakarta, June 2025.

## About

This is a hands-on learning folder for participants of the BlockDevId x Monad workshop series. The workshop covers Web3 fundamentals, smart contract development, frontend integration, deployment, DeFi, L2, privacy, and hackathon simulation.

**Key Features:**

- Solidity smart contracts for badges, certificates, student IDs, campus credits, and task management.
- Hardhat-based development, testing, and deployment.
- Example scripts for deploying and interacting with contracts.
- Gas usage and coverage reporting.

## Contracts

- `CourseBadge.sol`: Multi-token (ERC1155) for certificates, event badges, achievements, and workshops.
- `StudentID.sol`: On-chain student identity.
- `CampusCredit.sol`: Campus credit system.
- `TaskManager.sol`: Task/project management for students.

## Usage

Install dependencies:

```sh
npm install
```

Compile contracts:

```sh
npx hardhat compile
```

Run tests:

```sh
npx hardhat test
```

Deploy locally:

```sh
npx hardhat node
npx hardhat run scripts/deploy-taskmanager.ts --network hardhat
```

Deploy to Monad Testnet:

```sh
npx hardhat run scripts/deploy-taskmanager.ts --network monadTestnet
```

## Workshop Info

- 8 sessions: Web3, smart contracts, frontend, deployment, DeFi, L2, privacy/ZK/AI, hackathon.
- Free, curated, on-site, with mentoring and certification.
- Requirements: Laptop, Metamask, VS Code, basic JS/TS.
