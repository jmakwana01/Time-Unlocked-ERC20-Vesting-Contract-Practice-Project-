# Time-Unlocked ERC20 Vesting Contract (Practice Project)

This project is a **practice implementation** of a simple ERC20 vesting mechanism using **Foundry** and **OpenZeppelin**. The goal is to build confidence in writing, testing, and understanding Solidity smart contracts.

## 📌 What This Project Is About

This project implements a **time‑based token vesting contract** where:

* A **payer** deposits a fixed amount of ERC20 tokens into a vesting schedule.
* A **beneficiary** can withdraw the tokens gradually.
* The vesting unlocks **1/n of the tokens per day**, over **n days**.

This means:

* When the schedule starts, nothing is available immediately.
* After each full day, an additional portion becomes withdrawable.
* After `n` days, the beneficiary can withdraw the full amount.
* The payer can also cancel the vesting before completion and recover unvested tokens.

## 🛠️ What You’ll Practice

This project is built as a **hands-on learning exercise**, helping you practice:

* Writing Solidity smart contracts
* Using OpenZeppelin libraries (`IERC20`, `SafeERC20`)
* Understanding vesting logic and state handling
* Building and running tests with Foundry (`forge test`)
* Using cheatcodes like `vm.warp` to simulate time
* Working with project structure (`src/`, `test/`, `script/`)

## 📂 Project Structure

```
vesting-foundry/
├── src/
│   ├── TimeVesting.sol
│   └── TestToken.sol
├── test/
│   └── TimeVesting.t.sol
├── script/
│   └── Deploy.s.sol
├── remappings.txt
└── foundry.toml
```

## 🚀 Getting Started

```bash
forge init vesting-foundry
cd vesting-foundry
forge install OpenZeppelin/openzeppelin-contracts
forge test -vv
```

## 🎯 Goal

The purpose of this project is **not** to create a production‑ready contract. It is meant for:

* practice,
* building confidence,
* understanding how vesting logic works,
* and learning how to structure a Foundry project.

This is a great foundation for more advanced vesting systems and upgradeable patterns later.

---# Time-Unlocked-ERC20-Vesting-Contract-Practice-Project-
