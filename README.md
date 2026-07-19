# preFX

preFX is a mod template to add an effect to incoming audio and route it to either pre- or post-engine busses.

- pre-engine is routed to Crone's `context.in_b` bus
- post-engine is routed to Crone's `context.out_b` bus (which by default is sent to softcut inputs)

instructions and comments are found in the code.

_**IMPORTANT:**_ if a script's engine uses `SoundIn.ar` instead of `context.in_b` you'll need to modify the `Engine_xx.sc` file for preFX to work.
