# Dutch Action With NFT Lending
This repository contains the smart contracts source code and NFT Lending mechanism for Dauth Action. The repository uses foundry as development environment for compilation, testing and deployment tasks.

## Setup

The repository uses Chainlink oracle to obtain NFT floor prices, and Chainlink oracle only provides NFT quotes for the Goerli testnet

Follow the next steps to setup the repository:

- Create an environment file named `.env` and fill the next environment variables

```
# Add the Goerli testnet's RPC URL to your local environment
GOERLI_RPC_RUL=""
```

## Life Cycle

Follow the next steps can assist in comprehending this repository by reviewing the function

```
# To participate in the Dutch auction, obtaining SToken through collateralization is required beforehand
Step 1: CollateralPool.collateralize()

# The Auctioneer calls setAuction to start the Dutch auction
Step 2: DutchAuction.setAuction()

# The collateral provider can proceed to bid after the Dutch auction has started
Step 3: DutchAuction.bid()

# The auctioneer must give the collateral provider the auction item and refund after the Dutch auction has ended
Step 4: DutchAuction.claimAuctionItem() -> PunkWarriorErc721.transferAuctionItem()

# The SToken obtained from the auction house can be exchanged for ETH
Step 5: DutchAuction.withdraw()

# If the collateral providers no longer need to participate in the Dutch auction, they can redeem their own NFT
Step 6: CollateralPool.redeem()
```
