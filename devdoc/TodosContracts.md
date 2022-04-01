--------- MANUAL TESTS

Test artwork placeholder and update (check before and after on opensea)

Test metadata update (check refresh on opensea)

Test metadata display when name missing (opensea)

-------- DEV

Improve random allocation of traits on mint

Upgrader Contract
  - upgrades teeth or skin

Impact Mechanics
  - impact distance: [1 .. 10]
  - low distance => thick skin protects you
  - high distance => large teeth protect you
  - calculate damage, update metadata, emit event with damage taken
