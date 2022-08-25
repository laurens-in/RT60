(
~numPad = Array.new(20);
~keys.keys.array.scramble.do({arg val, index;
	~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, (index+50).nearestInScale(Scale.minor), \out, 0])
)});
)

// free
~numPad.do({|synth| synth.free;});

// set output
~numPad.do({|synth| synth.set(\out, ~peaveyBus);});