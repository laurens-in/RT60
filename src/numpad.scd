(
~numPad.do({|synth| synth.free;});
~numPad = Array.new(20);

~numPadScale = ;
~keys.keys.array.do({arg val, index;
	~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, (index+52).nearestInScale(Scale.minor), \out, ~peaveyBus
	])
)});
)

~keys.size

// free
~numPad.do({|synth| synth.free;});

// set output
~numPa0d.do({|synth| synth.set(\out, ~lMaxBus);})
+






57.nearestInScale(Scale.minor).postln;
















