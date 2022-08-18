(
// globals
~path = PathName(thisProcess.nowExecutingPath).parentPath ++ "samples/";

// handle busses
s.newBusAllocators;
~rbus = Bus.audio(s,1);

// init midi
MIDIClient.init;
MIDIIn.connectAll;

MIDIIn.doControlAction(1, 1, 64, 127); // spoof a cc, useful for using numpad

MIDIdef.cc(\amp, {|val, num| [val,num].postln;}, 64)


// boot routine

s.waitForBoot({

	// read buffers

	// add synth defs
	SynthDef(\reverb, {
		arg in=0, mix=1, out=0;
		var sig, wet;
		sig = In.ar(in,1);
		sig = FreeVerb.ar(sig, mix: mix, room: 0.999, damp: 0.999);
		sig = LPF.ar(sig, 2000);
		Out.ar(out,sig);

	}).add

	s.sync;

	// add groups
	~srcgroup = Group.new;
	~rgroup = Group.after(~srcgroup);
	~r = Synth(\reverb, [\in, ~rbus, \out, 0], ~rgroup);

})
)