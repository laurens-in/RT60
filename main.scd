(
s.freeAll;
s = Server.local;
s.options.numOutputBusChannels_(4);
s.options.numInputBusChannels_(4);
s.options.sampleRate_(48000);
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
~peaveyBus = Bus.audio(s,1);
~rbus = Bus.audio(s,1);
~shifterBus = Bus.audio(s,1);
~lMaxBus = Bus.audio(s,1);
~karplusBus = Bus.audio(s,1);

~peaveyOut = 2;
~morganIn = 0;
~mainOut= 0;

// handle triggers
// not sure if this is a smart thing to do
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
	MIDIIn.doControlAction(1, 1, 64, 127);
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
	// not so happy with this, i would prefer to index with numbers
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

	s.sync;

	// instrument synth defs

	SynthDef.new(\midisampler, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate;
		rate = (midinote-43).midiratio;
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[\open_low]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		sig = sig * Env.perc(0, (dur + 0.1), curve: -0.5)
.kr(doneAction: Done.freeSelf);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;


	SynthDef.new(\ring, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate;
		rate = (midinote-43).midiratio;
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[\open_low]);
		sig = SinOsc.ar(midinote.midicps / 3) * PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		sig = sig * Env.perc(0, dur / 2 , curve: -5)
.kr(doneAction: Done.freeSelf);
		sig = sig * amp;
		Out.ar(out,sig!2);
	}).add;

	SynthDef.new(\karplus, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5, factor=1;
		var sig, buf, rate, local;
		rate = (midinote-43).midiratio;
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[\open_power]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		local = LocalIn.ar(1);
		sig = LPF.ar((0.99 * DelayN.ar(local, 0.2, factor / (2 * midinote.midicps))) + sig, 4000);
		LocalOut.ar(sig);
		sig = sig * Env.perc(0, dur + 0.2, curve: -0.5)
		.kr(doneAction: Done.freeSelf);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;


	SynthDef(\looper, {
		arg out=0, bufnum=0, length=100000, midinote=40, vol=1, devo=0;
		var rate, sigA, sigX, sigY, phasor1, phasor2, env1, env2, deviation, trig;
		rate = (midinote-43).midiratio;
		deviation = LFDNoise1.kr(devo) * (devo / 15);
		trig = EnvGen.kr(Env.perc(0, 2 * 20000 / SampleRate.ir, 1, 2));
		sigA = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * (rate + deviation));
		phasor1 = Phasor.ar(0, BufRateScale.kr(bufnum) * (1 / length) * (rate + deviation), 0, 2);
		env1 = Fold.ar(phasor1, 0, 1);
		phasor2 = Wrap.ar(phasor1 + 1, 0, 2);
		env2 = Fold.ar(phasor2, 0, 1);
		sigX = BufRd.ar(1, bufnum, MulAdd(phasor1, length, TRand.kr(20000, length, phasor1 - 0.01))) * env1;
		sigY = BufRd.ar(1, bufnum, MulAdd(phasor2, length, TRand.kr(20000, length, phasor2 - 0.01))) * env2;
		Out.ar(out, (sigA + sigX + sigY))
	}).add;

		SynthDef(\karplusL, {
		arg out=0, bufnum=0, length=10000, midinote=40, vol=1, devo=0, ratio = 1;
		var rate, sig, sigA, sigX, sigY, phasor1, phasor2, env1, env2, deviation, trig,local;
		rate = (midinote-43).midiratio;
		deviation = LFDNoise1.kr(devo) * (devo / 15);
		trig = EnvGen.kr(Env.perc(0, 2 * 20000 / SampleRate.ir, 1, 2));
		sigA = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * (rate + deviation));
		phasor1 = Phasor.ar(0, BufRateScale.kr(bufnum) * (1 / length) * (rate + deviation), 0, 2);
		env1 = Fold.ar(phasor1, 0, 1);
		phasor2 = Wrap.ar(phasor1 + 1, 0, 2);
		env2 = Fold.ar(phasor2, 0, 1);
		sigX = BufRd.ar(1, bufnum, MulAdd(phasor1, length, TRand.kr(20000, length, phasor1 - 0.01))) * env1;
		sigY = BufRd.ar(1, bufnum, MulAdd(phasor2, length, TRand.kr(20000, length, phasor2 - 0.01))) * env2;
		sig = sigA + sigX + sigY;
		local = LocalIn.ar(1);
		sig = LPF.ar((0.99 * DelayC.ar(local, 0.2, ratio / (2 * midinote.midicps))) + sig, 4000);
		LocalOut.ar(sig);
		Out.ar(out, (sig))
	}).add;

	// add synth defs for FX
	SynthDef(\reverb, {
		arg in=0, mix=1, out=0;
		var sig, wet;
		sig = In.ar(in,1);
		sig = Pan2.ar(sig, LFDNoise1.kr(0.2, 0.25));
		sig = FreeVerb2.ar(sig[0], sig[1], mix: mix, room: 0.99, damp: 0.5);
		sig = [LPF.ar(sig[0], LFDNoise1.kr(0.05, 500, 1500)), LPF.ar(sig[1],LFDNoise1.kr(0.05, 500, 1500))];
		Out.ar(out,sig);

	}).add;

	SynthDef(\peavey, {
		arg in=0, mix=1, out=0;
		var sig, sog, wet;
		sig = In.ar(in,1);
		Out.ar(~peaveyOut, sig);
		sog = SoundIn.ar(2, 1);
		Out.ar(out,sog!2);

	}).add;

	SynthDef.new(\shifter, {arg in = 0, amount = 0, out=0; var sig, chain;
		sig = In.ar(in,1);
		chain = FFT(LocalBuf(128), sig);
		chain = PV_BinShift(chain, MouseY.kr(1,10));
		chain = PV_MagAbove(chain, MouseX.kr(0, 10));
		Out.ar(out, IFFT(chain));

	}).add;

	SynthDef.new(\locMax, {arg in = 0, out=0; var sig, chain;
		sig = In.ar(in,1);
		chain = FFT(LocalBuf(1024), sig);
		chain = PV_LocalMax(chain, MouseX.kr(0, 50));
		chain = PV_BinScramble(chain, MouseY.kr , 0.1, 0.5 );
		Out.ar(out, IFFT(chain).dup);
	}).add;

	s.sync;

	// add groups
	~makeNodes = {
		~srcgroup = Group.new;
		~rgroup = Group.after(~srcgroup);
		~r = Synth(\reverb, [\in, ~rbus, \mix, 0.5, \out, 0], ~rgroup);
		// note -> peavy should be dynamically routable to out/reverb/other maybe with pan?
		~sgroup = Group.after(~srcgroup);
		~s = Synth(\shifter, [\in, ~shifterBus, \out, 0], ~sgroup);
		~l = Synth(\locMax, [\in, ~lMaxBus, \out, 0], ~sgroup);


		~ggroup = Group.after(~srcgroup);
		~g = Synth(\peavey, [\in, ~peaveyBus, \out, 0], ~ggroup);
		// outputs here can be dynamically set during part changes -> ~g.set(\out, 0) etc.
	};

	// redo groups when hitting cmd .
	ServerTree.add(~makeNodes);
	ServerTree.run;

})
)

60.midicps

SynthDef(\default, { |out, note=0, rate|
	Out.ar(out, Line.kr(0.3, 0, 0.5) * SinOsc.ar(rate * 60.midicps) )
}).add;

Event.makeDefaultSynthDef;
(instrument: \midisampler, midinote: 45, amp: 1, dur: 10, out: ~lMaxBus).play;
(midinote: 40, amp: 1).play;

(
Pdef(\p, Pbind(\instrument, \midisampler, \midinote, Pseq([Pwhite(43, 52, 1), 40, 40, 40], inf) + 12, \dur, 0.1, \amp, 1, \factor, Pwhite(1, 10, inf), \out, ~lMaxBus));
)

Pdef(\f, Pbind(\instrument, \karplus, \midinote, Pshuf([36,38,40,43,47,52], inf), \dur, 0.5, \amp, Phprand(0.8,0.4, inf), \out, 0)).play;
Pdef(\e, Pbind(\instrument, \karplus, \midinote, Pshuf([36,38,40,43,47,52], inf) + -20, \dur, 0.5, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus)).play;
Pdef(\p).stop;
Pdef(\e).stop;
Pdef(\f).stop;

DelayC

Pdef(\p).asStream.next(()).play;
x = Pdef(\p).asStream;
x.next(()).play;

MIDIdef.cc(\play, {|val, num| "play next".postln; Pdef(\e).asStream.next(()).play;}, 64);
MIDIdef.cc(\play, {|val, num| "play next".postln; (instrument: \midisampler, midinote: rrand(32,48) + 12, amp: 0.8, dur: 10, out: 2).play;}, 64);


x = Synth(\karplusL, [\bufnum, ~samples[\open_low].choose, \midinote, 80, \ratio, 100, \devo, 1, \out, ~peaveyBus]);
x.free;
x.set(\ratio, 8)

p.stop;

(
~tLow = {
	var trigger;
	// trigger = Coyote.kr(LPF.ar(SoundIn.ar(3),250), fastMul: 0.4, thresh: 0.2, minDur: 0.3);
	trigger = FFT(LocalBuf(128), SoundIn.ar(3));
	trigger = Onsets.kr(trigger, 0.5, \rcomplex);
	SendReply.kr(
		trigger,
		cmdName: '/tLow',
		values: [trigger],
		replyID: 1
	);
}.play;

// Respond to that reply
OSCdef(\tLowPlay, {
	|msg|
	msg.postln;
	x.next(()).play;
}, '/tLow'); // <-- this has to match your cmdName

~tHigh = {
	var trigger;
	trigger = Coyote.kr(HPF.ar(SoundIn.ar(3),2000), fastMul: 1, thresh: 0.2, minDur: 0.05);
	SendReply.kr(
		trigger,
		cmdName: '/tHigh',
		values: [trigger],
		replyID: 1
	);
}.play;

// Respond to that reply
OSCdef(\tHighPlay, {
	|msg|
	msg.postln;
	x.next(()).play;
}, '/tHigh'); // <-- this has to match your cmdName
)
