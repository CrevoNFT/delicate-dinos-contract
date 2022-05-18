Contract Core Logic

- whitelist sale allows for multiple mints
- "auction" as time-tiered public sale


Contract Deployment
  - verification script
  - manage Polygon mainnet deployer account

Contract interaction scripts
  - fund with link

  - minting mode
    - whitelist
    - public sale
    - drop mint (kickoff with lottery - on-chain with favoured whitelist)
      -  => setWwhitelistedTokenIds script
      -  read transfer events from opensea, sort by highest price, call contract with those

  - generate artwork
    - for all minted tokenIds that don't have it
  
  - distribute DNOUP so Dino holders can upgrade
  
  - open/close upgrade season
  
  - post-impact drop
    - n most affected dinos get 1 asteroid each

  - unlock nameUpdate
  