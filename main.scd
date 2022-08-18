(
s.freeAll;
s = Server.local;
s.options.numOutputBusChannels_(4);
s.options.numInputBusChannels_(4);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));

~cleanup = {ServerBoot.removeAll;
	ServerQuit.removeAll;
	ServerTree.removeAll;
	CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);

~cleanup.();

// globals
~path = PathName(thisProcess.nowExecutingPath).parentPath ++ "samples/";

// handle busses
s.newBusAllocators;
~peavyBus = Bus.audio(s,1);
~rbus = Bus.audio(s,1);

~peavyOut = 3;
~peavyIn = {SoundIn.ar(3)};
~drumsIn = {SoundIn.ar(1)};

// init midi
MIDIClient.init;
MIDIIn.connectAll;

MIDIIn.doControlAction(1, 1, 64, 127); // spoof a cc, useful for using numpad

MIDIdef.cc(\amp, {|val, num| [val,num].postln;}, 64); // could be permanent, if necessary



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

	}).add;

	SynthDef(\peavey, {
		arg in=0, mix=1, out=0;
		var sig, wet;
		sig = In.ar(in,1);
		Out.ar(~peavyOut, sig);
		sig = ~peavyIn;
		Out.ar(out,sig);

	}).add;

	s.sync;

	// add groups
	~makeNodes = {
		~srcgroup = Group.new;
		// note -> peavy should be dynamically routable to out/reverb/other maybe with pan?
		~ggroup = Group.after(~srcgroup);
		~g = Synth(\peavey, [\in, ~peavyBus, \out, ~rbus ]);
		~rgroup = Group.after(~srcgroup);
		~r = Synth(\reverb, [\in, ~rbus, \out, 0], ~rgroup);
	};

	// redo groups when hitting cmd .
	ServerTree.add(~makeNodes);
	ServerTree.run;

})
)