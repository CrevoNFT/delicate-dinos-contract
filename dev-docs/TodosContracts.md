--------- Opensea Integration
- URI suffix .json ?

- placeholder preview hash

- properties vs levels

--------- MANUAL TESTS

Test how many favoured tokenIds can be set on mumbai

Test artwork placeholder and update (check before and after on opensea)

Test metadata update (check refresh on opensea)

Test metadata display when name missing (opensea)

-------- DEV

setUpgraderContract() in collection contract

Upgrader Contract
  - upgrades teeth or skin, uses token -> the higher the value, the more expensive the upgrade

Impact Mechanics
  - impact distance: [1 .. 10]
  - shock damage: low distance => thick skin protects you
  - hunger damage: large teeth protect you
  - calculate damage, update metadata, emit event with damage taken
