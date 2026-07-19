// preFX v0.1 - boilerplate pre-insert-fx - @sonoCircuit

PreFx {

	*initClass {

		var pfxParams, pfxSyn, pfxBus;

		// we require crone to be initialized first.
		// as we'll only call Crone class methods post boot this is somewhat redundant, but good practice I guess...?
		Class.initClassTree(Crone);

		// wait until sclang is up
		StartUp.add {

			// populate a params dictionary with synthDef args and default values
			pfxParams = Dictionary.newFrom([
				\drive, 0,
			 // \myArg, 0,
			 // \etc, 0.4,
			]);

			//// add osc functions > communicate from lua layer

			// called via mod post system hook > server has already booted and allocation is garanteed.
			// could be preplaced with CroneDef.add() if you're only adding a synthDef.
			OSCFunc.new({ |msg|

				// a very basic amplifier. replace with the real deal.
				// important: grab the sound directly from hardware busses via SoundIn.ar([0, 1])
				SynthDef.new(\basicAmp, {
					arg outBus, drive = 0;
					var in, snd, wet, gain, attn;

					drive = Lag.kr(drive);
					gain = drive.linlin(0, 1, 0, 32).dbamp;
					attn = drive.linlin(0, 1, 0, -18).dbamp;

					in = SoundIn.ar([0, 1]); // hardware in busses
					wet = (in * gain).tanh * attn;
					snd = XFade2.ar(in, wet, (drive * 2) - 1);

					Out.ar(outBus, snd);
				}).add;

				"preFX added".postln;
			}, "/prefx/init");

			// called via 'state' param to toggle preFX on/off
			OSCFunc.new({ |msg|
				var state = msg[1].asInteger;
				if (state == 1) {
					if (pfxSyn.isNil) {

						// failsafe: assign a default bus if nil > we'd expect 'set_bus' to be called before 'set_state' via params
						if (pfxBus.isNil) {pfxBus = Crone.context.in_b};

						// add pfxSyn synth
						// caveat: we expect the script engine to use context.xg as target, if not adapt Engine file.
						pfxSyn = Synth.new(\basicAmp,
							args: [\outBus, pfxBus] ++ pfxParams.getPairs, // pass the bus and current state of params
							target: Crone.context.ig, // target is context.ig, same as context.in_s (adc in)
							addAction: 'addToHead'    // add to the head of the input group
						);

						// set the adc level to 0 > no dry signal passed to context.in_b
						2.do({ |i| Crone.context.in_s[i].set(\level, 0) });
					};
				}{
					// free stuff
					pfxSyn.free;
					pfxSyn = nil;
					// reset adc level to unity
					2.do({ |i| Crone.context.in_s[i].set(\level, 1) });
				};
			}, "/prefx/set_state");

			// called via 'routing' param to set the output bus
			OSCFunc.new({ |msg|
				var bus = msg[1].asInteger;
				if (bus == 0) {
					pfxBus = Crone.context.in_b; // send to Crone's input bus
				}{
					pfxBus = Crone.context.out_b; // send to Crone's output bus > softcut
				};
				if (pfxSyn.notNil) { pfxSyn.set(\outBus, pfxBus) }; // set the bus directly if active
			}, "/prefx/set_bus");

			// called via params to set the param values > key (string) needs to match synthDef argument
			OSCFunc.new({ |msg|
				var key = msg[1].asSymbol;
				var val = msg[2].asFloat;
				if (pfxSyn.notNil) { pfxSyn.set(key, val) }; // set the value directly if active
				pfxParams[key] = val; // store all changes in our params dictionary
			}, "/prefx/set_param");

			// called via mod post cleanup hook > free/reset stuff when loading a new script
			OSCFunc.new({ |msg|
				// reset the adc level
				2.do({|i|
					Crone.context.in_s[i].set(\level, 1)
				});
				// free stuff
				pfxSyn.free;
				pfxSyn = nil;
				pfxBus = nil;
				"preFX removed".postln;
			}, "/prefx/free");

		}
	}
}
