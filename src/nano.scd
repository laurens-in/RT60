(
MIDIdef.freeAll;
(0..7).do({ |index|
	MIDIdef.cc("fader_%".format(index).asSymbol, {|val, num|
		~midiFaders[index].set(val.linlin(0, 127, 1, 2).log2);
	}, index).permanent_(true);
});
(16..23).do({ |index|
	MIDIdef.cc("knob_%".format(index).asSymbol, {|val, num|
		~midiKnobs[index%8].set(val.linlin(0, 127, 0, 1));
	}, index).permanent_(true);
});
(32..39).do({ |index|
	MIDIdef.cc("sbutton_%".format(index).asSymbol, {|val, num|
		var res;
		res = if(val==127, {1}, {0});
		~midiSbutton[index%8].set(res);
	}, index).permanent_(true);
});
(48..55).do({ |index|
	MIDIdef.cc("mbutton_%".format(index).asSymbol, {|val, num|
		var res;
		res = if(val==127, {1}, {0});
		~midiMbutton[index%8].set(res);
	}, index).permanent_(true);
});
(64..71).do({ |index|
	MIDIdef.cc("rbutton_%".format(index).asSymbol, {|val, num|
		var res;
		res = if(val==127, {1}, {0});
		~midiRbutton[index%8].set(res);
	}, index).permanent_(true);
});
(40..44).do({ |index|
	MIDIdef.cc("sbutton_%".format(index).asSymbol, {|val, num|
		var res;
		res = if(val==127, {1}, {0});
		~midiTPbutton[index%8].set(res);
	}, index).permanent_(true);
});

MIDIdef.cc(\numPadMode, { |val|
	var normal, karplus;
	if (val==0, {
		~numPad.do({|synth| synth.free;});
		~numPad = Array.new(20);

		~numPadScale = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 48;});
		~keyOrder.do({arg val, index;
			~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \out, ~peaveyBus
			]);
		)});
	}, {
		~numPad.do({|synth| synth.free;});
		~numPad = Array.new(20);

		~numPadScale = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 48;});
		~keyOrder.do({arg val, index;
			~numPad.add(Synth(\tSamplerKarp, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \out, ~peaveyBus
			]);
		)});
	})
}, 32)
)