# Contracts Deployment

Hardhat Deploy Scripts
libs
  - DelicateDinosMetadata
  - DelicateDinosUpgrade
  
  - DelicateDinosRandomness
  - DinoUpToken
  - DelicateDinosRaffle
  - DelicateDinos(randomnessProv, upToken,raffle)
  - DelicateDinosRaffle.initMaster(delicateDinos)

Fund DelicateDinos with LINK

# Minting Controls

In the contracts repo, run

- `yarn close-minting --contract ...`
- `yarn open-whitelist --contract ...(address)... --fee ...(MATIC amount)...`
- `yarn open-public-sale --contract ...(address)... --fee ...(MATIC amount)...`
- `yarn drop-dinos --contract ...`
- `yarn open-drop-claim --contract ...`

# Prepare Whitelisted Minting

CONTRACTS (so that Dinos Contract knows who is whitelisted and allows mintWhitelisted() to be called)
- update `whitelist/whitelist.json`
- run `yarn open-whitelist`
  
FRONTEND (so that mint page recognizes whitelisted addresses and provides a proof on calling contract.mintWhitelisted()):
- update `src/whitelist/whitelist.json`
- redeploy frontend

# Minting WEB UI

## Mint Page has a form: 
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

## Public Sale has a form:
- name
- mint button
  - (disabled if would revert)
    - not enough matic to pay
- warning
  - if not enough matic to pay
  
## Claiming: My Own Page 
- any claim-bearing token is displayed accordingly (tokenIdCanClaim(tokenId))
- button to perform the claim
  - disabled if not enough gas

# ARTWORK updates on Whitelist / PublicSale / Claim Dropped

## On-Chain 
- mintDino(), mintDino(), ...

## Off-Chain 
- read mint events (transfer from 0 address), read ArtworkSet() events => diff set needs artwork
- for all tokenIds in diff set, **create metadata**
    - read contract traits
      - create artwork accordingly
      - upload artwork to IPFS => get newBaseUri (artwork directory uri)  

## On-Chain
- for all tokenIds in diff set
  - updateArtwork(tokenId, newBaseUri)
  
TODO: write script for this ^ ^ ^


# Upgrade Dino: WEB UI

## Traits (pre-impact)
- owner can change any trait
- only teeth / skin will affect dino's resistance to impact

Pay with DNOUP Token

`dnoUpTokenContract.approve(dinosContract.address, dnoUpTokenAmount);`
`dinosContract.upgradeTraits(tokenId, teethLengthDelta, skinThicknessDelta, dnoUpTokenAmount);`

## Name (post-impact)
- only once possible, after impact (bonus feature)

`dinosContract.setName("FunkyName77")`


# Impact

## Simulation for Dinos
`yarn go-impact`
- metadata is updated
- artwork remains the same
- impact events `DinoDamaged(uint8)` are emitted by Dinos Contract (how much the fossil value was affected)

- now, each dino's name can be updated (bonus feature)

## Asteroids Drop
- retrieve all DinoDamaged() events, sort by max, take first n
  - drop 1 asteroid to each
  - holders of dinos obtain them automatically without claiming
    - we call the mint method in the asteroids contract for each dino holder individually (script)

- the remaining asteroids are for whitelist / public sale