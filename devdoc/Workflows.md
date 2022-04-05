=============== Deployment

Hardhat Deploy Scripts
  - DelicateDinosMetadata
  - DelicateDinosUpgrade
  - DinoUpToken
  - DelicateDinos

Fund DelicateDinos with LINK


----------
startPublicSale()
fee 0.01 MATIC = 10000000000000000

---------- 


=============== Minting

WEB UI
  - Mint Page has a form: 
    - name
    - mint button
      - (disabled if would revert)
        - not whitelisted
        - not enough matic to pay
        - ...
    - warning
      - if not whitelisted 
      - if not enough matic to pay
      - ...

  - Claiming: My Own Page 
    - any claim-bearing token is displayed accordingly (tokenIdCanClaim(tokenId))
    - button to perform the claim
      - disabled if not enough gas

----- Whitelist / PublicSale

ONCHAIN :
- mintDino(), mintDino(), ...

OFFCHAIN : 
- read mint events (transfer from 0 address), read ArtworkSet() events => diff set needs artwork
- for all tokenIds in diff set, **create metadata**
    - read contract traits
      - create artwork accordingly
      - upload artwork to IPFS => get newBaseUri (artwork directory uri)  

ONCHAIN : 
- for all tokenIds in diff set
  - updateArtwork(tokenId, newBaseUri)


============== Upgrade

- owner can change any trait, even the name
- only teeth / skin will affect dino's resistance to impact

Pay with DNOG Token

ONCHAIN
- metadata is updated


============= IMPACT

- impact events are emitted (how much the health was affected)

- retrieve all, sort by max, take first n
  - drop 1 asteroid to each
  - holders of dinos have them automatically

- the remaining asteroids are for whitelist / public sale