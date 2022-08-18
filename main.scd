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
~samples = ();
~path = PathName(PathName(thisProcess.nowExecutingPath).parentPath ++ "samples/");



// handle busses
s.newBusAllocators;
~peavyBus = Bus.audio(s,1);
~rbus = Bus.audio(s,1);

~peavyOut = 3;
~mainOut= 0;

~peavyIn = {SoundIn.ar(3)};
~drumsIn = {SoundIn.ar(1)};

// handle triggers
~triggers = Dictionary.new;
~triggers.add(\low -> {Coyote.kr(LPF.ar(~drumsIn, 100), fastMul: 0.5,thresh: 0.3, minDur: 0.1)});
~triggers.add(\high -> {Coyote.kr(HPF.ar(~drumsIn, 1000), fastMul: 0.9,thresh: 0.2, minDur: 0.1)});
~triggers.add(\mid -> {Coyote.kr(BPF.ar(~drumsIn, 500, 0.5), fastMul: 0.9,thresh: 0.2, minDur: 0.1)});

// create gui
t = StaticText.new().align_(\center).font = Font("Fira Code", 85);
t.string = "READY";

w = Window.new("Keystrokes").background_(Color.grey).layout_(
    VLayout(
		HLayout( t )
    )
).front;

w.view.keyDownAction = {
	arg view, char, modifiers, unicode, keycode, key;
	[char, keycode].postln;
	w.view.background_(Color.white);
	t.string = keycode;
};
w.view.keyUpAction = {
	arg view, char, modifiers, unicode, keycode, key;
	[char, keycode].postln;
	w.view.background_(Color.grey);
	t.string = "";
};
w.front;

// init midi
MIDIClient.init;
MIDIIn.connectAll;

MIDIIn.doControlAction(1, 1, 64, 127); // spoof a cc, useful for using numpad

MIDIdef.cc(\amp, {|val, num| [val,num].postln;}, 64); // could be permanent, if necessary



// boot routine

s.waitForBoot({

	// read buffers
	var subfolders;
	subfolders = ~path.entries;
	subfolders.do({
		arg dir;
		var bufArray;
		bufArray = dir.entries.collect({
			arg file;
			Buffer.readChannel(s, file.fullPath);
		});
		~samples[dir.folderName.asSymbol] = bufArray;
	});

	// instrument synth defs
	SynthDef(\looper, {
		arg out=0, bufnum=0, length=100000, note=40, vol=1, devo=0;
		var notePow, sigA, sigX, sigY, phasor1, phasor2, env1, env2, deviation, trig;
		notePow = note - 40;
		deviation = LFDNoise1.kr(devo);
		trig = EnvGen.kr(Env.perc(0, 2 * 20000 / SampleRate.ir, 1, 2));
		sigA = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * 1.059463.pow(notePow + deviation)) * trig;
		phasor1 = Phasor.ar(0, BufRateScale.kr(bufnum) * (1 / length) * 1.059463.pow(notePow + deviation), 0, 2);
		env1 = Fold.ar(phasor1, 0, 1);
		phasor2 = Wrap.ar(phasor1 + 1, 0, 2);
		env2 = Fold.ar(phasor2, 0, 1);
		sigX = BufRd.ar(1, bufnum, MulAdd(phasor1, length, TRand.kr(20000, length, phasor1 - 0.01))) * env1;
		sigY = BufRd.ar(1, bufnum, MulAdd(phasor2, length, TRand.kr(20000, length, phasor2 - 0.01))) * env2;
		Out.ar(out, sigA + sigX + sigY)
	}).add;


	// add synth defs for FX
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
		~g = Synth(\peavey, [\in, ~peavyBus, \out, ~rbus ], ~ggroup);
		~rgroup = Group.after(~srcgroup);
		~r = Synth(\reverb, [\in, ~rbus, \out, 0], ~rgroup);
	};

	// redo groups when hitting cmd .
	ServerTree.add(~makeNodes);
	ServerTree.run;

})
)