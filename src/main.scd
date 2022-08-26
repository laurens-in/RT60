(
s.freeAll;
s = Server.local;
s.options.numOutputBusChannels_(4);
s.options.numInputBusChannels_(4);
s.options.sampleRate_(41000);
s.options.memSize_(2.pow(21));
 s.latency = 0.0005;

~cleanup = {ServerBoot.removeAll;
	ServerQuit.removeAll;
	ServerTree.removeAll;
	CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);


~cleanup.();

// globals
~keys = Dictionary[
\7 -> 79,
\8 -> 80,
\9 -> 81,
\minus -> 82,
\4 -> 83,
\5 -> 84,
\6 -> 85,
\plus -> 86,
\1 -> 87,
\2 -> 88,
\3 -> 89,
\0 -> 90,
\dot -> 91,
\times -> 63,
\div -> 106];

// this is very dumb but it works
~samples = [[[],[]],[[],[],[]]];
~path = PathName(PathName(thisProcess.nowExecutingPath).parentPath ++ "../audio/");



// handle busses
s.newBusAllocators;
~peaveyBus = Bus.audio(s,1);
~rbus = Bus.audio(s,1);
~shifterBus = Bus.audio(s,1);
~lMaxBus = Bus.audio(s,1);
~karplusBus = Bus.audio(s,1);
~triggerBus = Bus.control(s,1);
~pitchBus = Bus.control(s,1);
~midiFaders = Array.fill(8, {Bus.control(s,1)});
~midiKnobs = Array.fill(8, {Bus.control(s,1)});
~midiSbutton = Array.fill(8, {Bus.control(s,1)});

~peaveyOut = 2;
~morganIn = 3;
~mainOut= 0;

// create gui
t = StaticText.new().align_(\center).font = Font("Fira Code", 85);
t.string = "READY";

w = Window.new("Keystrokes").background_(Color.grey).layout_(
    VLayout(
		HLayout( t )
    )
);

w.view.keyDownAction = {
	arg view, char, modifiers, unicode, keycode, key;
	w.view.background_(Color.white);
	MIDIIn.doControlAction(1, 1, 64, 127);
	t.string = keycode;
};
w.view.keyUpAction = {
	arg view, char, modifiers, unicode, keycode, key;
	w.view.background_(Color.grey);
	t.string = "";
};
w.front;

// init midi
MIDIClient.init;
MIDIIn.connectAll;

MIDIIn.doControlAction(1, 1, 64, 127); // spoof a cc, useful for using numpad


// boot routine

s.waitForBoot({

	// read buffers
	// not so happy with this, i would prefer to index with numbers
	var subfolders;
	subfolders = ~path.entries;
	subfolders.do({
		arg dir, index;
		var subsubfolders;
		subsubfolders = dir.entries;
		subsubfolders.do({
			arg dirS, indexS;
			var bufArray;
			dirS.entries.postln;
			bufArray = dirS.entries.collect({
				arg file;
				file.postln;
				Buffer.readChannel(s, file.fullPath);
			});
			~samples[index][indexS] = bufArray;
		});
	});

	~samples.postln;


	s.sync;

	// instrument synth defs

	SynthDef.new(\midisampler, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate;
		rate = (midinote-43).midiratio;
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[1][1]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		sig = sig * Env.perc(0, (dur + 0.1), curve: -0.5)
.kr(doneAction: Done.freeSelf);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\tSampler, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate, trig, rand;
		// rate = (midinote-43).midiratio;
		trig = Dust.kr(1);
		rate = TRand.kr(0.5, 1.6,trig);
		rand = TIRand(0,9,trig);
		buf = TChoose.kr(trig, TChoose.kr(trig, TChoose.kr(trig, ~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * EnvGen.kr(Env.perc(0, (dur + 0.1), curve: -0.5), gate: trig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

		SynthDef.new(\tSamplerOpen, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate, trig, rand;
		trig = In.kr(~triggerBus, 1);
		rate = (TChoose.kr(trig, [40, 38, 36, 43, 45, 47]) - 43).midiratio;
		rand = TIRand(0,9,trig);
		buf = TChoose.kr(trig, TChoose.kr(trig, ~samples[1]));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * EnvGen.kr(Env.perc(0, (dur + 0.1), curve: -0.5), gate: trig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

		SynthDef.new(\tSamplerPad, {
		arg trigIn=0, amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate, trig, rand;
		trig = KeyState.kr(trigIn, 0, 1, 0);
		// rate = TRand.kr(0.5, 2.6,trig);
		rate = (midinote - 43).midiratio;
		rand = TIRand(0,9,trig);
		buf = TChoose.kr(trig,  ~samples[1][0]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * EnvGen.kr(Env.asr(0.01,1,0.25), gate: trig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;


	SynthDef.new(\ring, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5;
		var sig, buf, rate;
		rate = (midinote-43).midiratio;
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[1][0]);
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
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[1][1]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		local = LocalIn.ar(1);
		sig = LPF.ar((0.975 * DelayC.ar(local, 10, (In.kr(~midiFaders[5]).linexp(0,1,1,500) + In.kr(~midiKnobs[5]).linlin(0,1,0,30)) / (2 * midinote.midicps))) + sig, 4000);
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
		Out.ar(out, (sigA + sigX + sigY)!2)
	}).add;

		SynthDef(\karplusL, {
		arg out=0, bufnum=0, length=10000, midinote=40, vol=1, devo=0, ratio = 1, gate=1;
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
		// sig = LPF.ar((0.95 * DelayC.ar(local, 0.2, (MouseX.kr(1,2) * ratio) / (2 * midinote.midicps))) + sig, 4000);
		sig = LPF.ar((0.975 * DelayC.ar(local, 10, (In.kr(~midiFaders[5]).linexp(0,1,1,50) + In.kr(~midiKnobs[5]).linlin(0,1,0,2)) / (2 * midinote.midicps))) + sig, 4000);
		LocalOut.ar(sig);
		sig = EnvGen.kr(Env.asr, gate, doneAction: Done.freeSelf) * sig;
		Out.ar(out, (sig))
	}).add;

	// add synth defs for FX
	SynthDef(\reverb, {
		arg in=0, mix=1, out=0;
		var sig, wet;
		sig = In.ar(in,1);
		sig = Pan2.ar(sig, LFDNoise1.kr(0.2, 0.25));
		sig = FreeVerb2.ar(sig[0], sig[1], mix: In.kr(~midiFaders[6]), room: 0.99, damp: 0.5);
		// sig = [LPF.ar(sig[0], LFDNoise1.kr(0.05, 500, 1500)), LPF.ar(sig[1],LFDNoise1.kr(0.05, 500, 1500))];
		Out.ar(out,Limiter.ar(sig * In.kr(~midiFaders[7]),1,0.001));

	}).add;

	SynthDef(\peavey, {
		arg in=0, mix=1, out=0;
		var sig, sog, wet;
		sig = In.ar(in,1);
		Out.ar(~peaveyOut, sig);
		sog = SoundIn.ar(2, 1);
		Out.ar(out,sog);

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
		// chain = PV_LocalMax(chain, MouseX.kr(0, 10));
		chain = PV_MagShift(chain, MouseX.kr(1,0.5));
		// chain = PV_BinScramble(chain, MouseY.kr , 0.1, 1.0 );
		Out.ar(out, IFFT(chain));
	}).add;

	s.sync;

	// add groups
	~makeNodes = {
		~srcgroup = Group.new;
		~rgroup = Group.after(~srcgroup);
		~r = Synth(\reverb, [\in, ~rbus, \mix, 0.2, \out, 0], ~rgroup);
		// note -> peavy should be dynamically routable to out/reverb/other maybe with pan?
		~sgroup = Group.after(~srcgroup);
		~s = Synth(\shifter, [\in, ~shifterBus, \out, ~rbus], ~sgroup);
		~l = Synth(\locMax, [\in, ~lMaxBus, \out, ~rbus], ~sgroup);


		~ggroup = Group.after(~srcgroup);
		~g = Synth(\peavey, [\in, ~peaveyBus, \out, ~rbus], ~ggroup);
		// outputs here can be dynamically set during part changes -> ~g.set(\out, 0) etc.
	};

	// redo groups when hitting cmd .
	ServerTree.add(~makeNodes);
	ServerTree.run;

})
)

x = Synth(\tSampler, [\out, ~peaveyBus]);
x = Synth(\tSamplerOpen, [\out, ~peaveyBus]);
x.free;

~tSamplerr = {
	var trigg er, freq, hasFreq;
	trigger = FFT(LocalBuf(128), SoundIn.ar(3));
	trigger = PV_BrickWall(trigger, -0.85);
	trigger = Onsets.kr(trigger, 0.95, \rcomplex);
	Out.kr(~triggerBus, trigger);
}.play;

60.midicps


(instrument: \midisampler, midinote: 45, amp: 1, dur: 10, out: ~lMaxBus).play;
(midinote: 40, amp: 1).play;
(
Pdef(\p, Pbind(\instrument, \midisampler, \midinote, Pwhite(34, 45.2, inf) , \dur, Pwhite(5.3, 9.5, inf) , \amp, 0.8, \out, ~peaveyBus)).play;
)

Pdef(\f, Pbind(\instrument, \karplus, \midinote, Pshuf([36,38,40,43,47,52], inf) + 36, \dur, 0.2, \amp, Phprand(0.8,0.4, inf), \factor, 20, \out, ~rbus)).play;
Pdef(\e, Pbind(\instrument, \karplus, \midinote, Pshuf([36,38,40,43,47,52], inf) + -20, \dur, 0.5, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus)).play;

Pdef(\p).asStream.next(()).play;
x = Pdef(\p).asStream;
x.next(()).play;
Pdef(\f).stop

MIDIdef.cc(\play, {|val, num| "play next".postln; Pdef(\e).asStream.next(()).play;}, 64);
MIDIdef.cc(\play, {|val, num| "play next".postln; (instrument: \midisampler, midinote: rrand(32,48) -12, amp: 0.8, dur: 10, out: 2).play;}, 64);