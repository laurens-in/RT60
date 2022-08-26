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
})
)

{In.kr(~midiSbutton[0]).scope * SinOsc.ar()}.play
~midiSbutton.postln

MIDIdef.cc(\test, {|val,num| [num,val].postln;});


MIDIdef.freeAll;