(
~numPad.do({|synth| synth.free;});
~numPad = Array.new(20);

~numPadScale = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 48;});
~keyOrder.do({arg val, index;
	~numPad.add(Synth(\tSamplerKarp, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \out, ~peaveyBus
	]);
)});
)

(
~numPad.do({|synth| synth.free;});
~numPad = Array.new(20);

~numPadScale = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 36;});
~keyOrder.do({arg val, index;
	~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \out, ~peaveyBus
	]);
)});
)

~numPad.do({|synth| synth.free;});





MIDIIn.smpte










