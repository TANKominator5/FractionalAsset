# FractionalAsset
# 🎨 Fractional Asset - Solidity Smart Contract

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.20-blue.svg)](https://soliditylang.org/)

## Overview

This project provides a Solidity smart contract, `FractionalAsset.sol`, that allows for the fractionalization of a single ERC-721 (NFT) token into fungible ERC-20 tokens. This enables shared ownership of high-value digital assets, making them more accessible and liquid.

The contract securely holds the original NFT in escrow and mints a predetermined number of ERC-20 "share" tokens. These shares can be traded on any decentralized exchange. The contract also includes a simple on-chain governance mechanism for shareholders to vote on proposals, such as setting a sale price for the underlying asset.

## How It Works: The Lifecycle

1.  **Deployment**: The contract is deployed with the parameters of the NFT to be fractionalized, including the original NFT's contract address, its token ID, and the details for the new fractional ERC-20 tokens (name, symbol, total supply). The deployer becomes the `owner`.
2.  **Asset Locking**: The `owner` must first `approve()` the `FractionalAsset` contract to manage their NFT. Then, they call the `lockNft()` function, which transfers the NFT into the smart contract for secure custody.
3.  **Distribution & Trading**: The `owner` now holds the entire supply of the newly created ERC-20 share tokens. They can distribute them via a sale, airdrop, or any other method. These shares are now freely tradable.
4.  **Governance**: Any shareholder can create proposals. Shareholders can then vote on these proposals with a weight proportional to the number of shares they own.
5.  **Sale & Redemption**: If a proposal to sell the asset passes and a sale is finalized off-chain, the `owner` calls `finalizeSale()` and sends the full ETH proceeds into the contract. This makes the contract "redeemable."
6.  **Claiming Proceeds**: Any shareholder can now call the `redeemShares()` function. This will burn their share tokens and transfer them their proportional cut of the ETH from the sale.

---

## Deployed Contract Address

*   **Contract:** `FractionalAsset`
*   **Address:** `0x77Fc9aA27EF12d64462792F0b363175B94d25c8D`
*   **Network:** **[Please specify the network here, e.g., Sepolia Testnet, Polygon Mainnet, etc.]**
*   **Explorer Link:** **[Add a link to the contract on a block explorer like Etherscan, e.g., `https://sepolia.etherscan.io/address/0x77Fc9aA27EF12d64462792F0b363175B94d25c8D`]**

---

## Getting Started for Developers

This project is built using the Hardhat development environment.

### Prerequisites

*   Node.js (v16 or later)
*   Yarn or npm
*   Git

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone [YOUR_REPOSITORY_URL]
    cd [YOUR_PROJECT_DIRECTORY]
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Create a `.env` file:**
    Create a copy of `.env.example` and name it `.env`. Populate it with your own private key and provider URLs.
    ```
    # .env
    SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_INFURA_KEY"
    PRIVATE_KEY="YOUR_METAMASK_PRIVATE_KEY"
    ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
    ```

### Running Tests

To ensure everything is working correctly, run the test suite:
```bash
npx hardhat test
