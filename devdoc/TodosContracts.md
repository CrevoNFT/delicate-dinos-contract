--------- MANUAL TESTS

Test how many favoured tokenIds can be set on mumbai

Test artwork placeholder and update (check before and after on opensea)

Test metadata update (check refresh on opensea)

Test metadata display when name missing (opensea)

-------- DEV

Upgrader Contract
  - upgrades teeth or skin, uses token -> the higher the value, the more expensive the upgrade

Impact Mechanics
  - impact distance: [1 .. 10]
  - low distance => thick skin protects you
  - high distance => large teeth protect you
  - calculate damage, update metadata, emit event with damage taken
