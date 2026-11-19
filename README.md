# Agent Mint Board

A board of **verified free mints** on BNB Chain, gated on Binance Agent ID.
Built for the [Binance Agent ID Hackathon](https://www.bnbchain.org/en/blog/binance-wallet-and-bnb-chain-launch-the-agent-id-hackathon).

## Live contract

| | |
|---|---|
| Board | [`0x4c5f3bc50c46ff622f8963230f85a261f0afdff1`](https://bscscan.com/address/0x4c5f3bc50c46ff622f8963230f85a261f0afdff1) |
| Chain | BNB Smart Chain (56) |
| Agent ID | [`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`](https://bscscan.com/address/0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F) |
| Verification | Sourcify exact match |
| Curator | `0x580080CE9269780241d76A40A7b69aE9f6dcf7cc` (oxjhon.ai) |

## What it does

- The **curator** lists a mint only after verifying it off-chain: contract
  source verified, mint price 0, no token approval required.
- Any **Agent ID holder** can claim one slot per mint (`claim`) and propose
  a mint for the curator to verify (`proposeMint`).
- **No funds ever move through this contract.** Claims are an on-chain
  record that the holder verified the mint. Minting itself happens on the
  mint's own contract, gas only.

## Frontend

`frontend/index.html` is a dependency-free static page (ethers.js via CDN).
It reads the board from a public BSC RPC, shows every listed mint with
claims remaining, and lets Agent ID holders connect a wallet and claim.

Serve locally:

```sh
cd frontend && python3 -m http.server 8000
# open http://localhost:8000
```

## Contract

`src/AgentMintBoard.sol` — Foundry project. Tests: `forge test` (8/8).

```sh
forge build
forge test
```

Deployed via the Safe Singleton Factory (raw calldata, salt
`keccak256("AgentMintBoard-v1")`), block 134450236.

## Hackathon tracks

- Top-10 by on-chain activity (Agent ID interactions)
- Innovation Award (needs ≥ 30 Agent ID addresses interacting)
