(
s.freeAll;
s = Server.local;
s.options.numOutputBusChannels_(4);
s.options.numInputBusChannels_(3);
s.options.sampleRate_(41000);
s.options.memSize_(2.pow(21));
s.latency = 0.05;

~cleanup = {ServerBoot.removeAll;
	ServerQuit.removeAll;
	ServerTree.removeAll;
	CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);


~cleanup.();

// globals
~keys = Dictionary[
	\0 -> 90,
	\dot -> 91,
	\1 -> 87,
	\2 -> 88,
	\3 -> 89,
	\4 -> 83,
	\5 -> 84,
	\6 -> 85,
	\plus -> 86,
	\7 -> 79,
	\8 -> 80,
	\9 -> 81,
	\minus -> 82,
	\div -> 106,
	\times -> 63,
];


~keyOrder = [
	\0,
	\dot,
	\1,
	\2,
	\3,
	\4,
	\5,
	\6,
	\plus,
	\7,
	\8,
	\9,
	\minus,
	\div,
	\times,
];

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
~inTrigBus = Bus.control(s,1);
~triggerQuart = Bus.control(s,1);
~triggerEight = Bus.control(s,1);
~triggerSixt = Bus.control(s,1);

~pitchBus = Bus.control(s,1);
~midiFaders = Array.fill(8, {Bus.control(s,1)});
~midiKnobs = Array.fill(8, {Bus.control(s,1)});
~midiSbutton = Array.fill(8, {Bus.control(s,1)});
~midiMbutton = Array.fill(8, {Bus.control(s,1)});
~midiRbutton = Array.fill(8, {Bus.control(s,1)});
~midiTPbutton = Array.fill(5, {Bus.control(s,1)});

~peaveyOut = 2;
~morganIn = 0;
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

MIDIdef.cc(\textureSwitch, { |val|
	var synth;
	val.postln;
	if (val==127, {~karplusText = Synth(\karplusL, [\midinote, 48, \bufnum, ~samples[1][1][1], \length, 80000, \out, ~peaveyBus]);}, {~karplusText.set(\gate, 0)});
}, 37);


// triggers

a = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 40;});

Pdefn(\notes, Prand(a, inf));


Pdef(\morgan, Pbind(\instrument, \gatesampler, \midinote, Pdefn(\notes), \dur, inf, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\quart, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) - 7, \dur, inf, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\eight, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) , \dur, inf, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\sixt, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) + 12 , \dur, inf, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

~morganPat= Pdef(\morgan).asStream;

~quart = Pdef(\quart).asStream;
~eight = Pdef(\eight).asStream;
~sixt = Pdef(\sixt).asStream;

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
		rate = (midinote-43).midiratio + In.kr(~midiFaders[1]).linlin(0,1,0,2) - In.kr(~midiKnobs[1]).linlin(0,1,0,0.5);
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, Select.kr(In.kr(~midiTPbutton[1]) + In.kr(~midiTPbutton[2]), Select.kr(In.kr(~midiTPbutton[0]).linlin(0,1,1,0),~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		sig = sig * Env.perc(0, (dur + 0.1), curve: -0.5)
		.kr(doneAction: Done.freeSelf);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\gatesampler, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5, gate=1;
		var sig, buf, rate;
		rate = (midinote-43).midiratio * In.kr(~midiFaders[1]).linlin(0,1,1,2) * In.kr(~midiKnobs[1]).linlin(0,1,1,0.5);
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, Select.kr(In.kr(~midiTPbutton[1]) + In.kr(~midiTPbutton[2]), Select.kr(In.kr(~midiTPbutton[0]).linlin(0,1,1,0),~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0);
		sig = sig * amp;
		sig = EnvGen.kr(Env.perc(attackTime: 0, releaseTime: In.kr(~midiKnobs[3]).linlin(0,1,0.1,3)), doneAction: Done.freeSelf) * sig;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\tSampler, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5, trig=0;
		var sig, buf, rate, rand;
		// rate = (midinote-43).midiratio;
		trig = InTrig.kr(~inTrigBus);
		rate = (midinote - 43).midiratio * In.kr(~midiFaders[1]).linlin(0,1,1,2) * In.kr(~midiKnobs[1]).linlin(0,1,1,0.5);
		rand = TIRand(0,9,trig);
		buf = TChoose.kr(trig, Select.kr(In.kr(~midiTPbutton[1]) + In.kr(~midiTPbutton[2]), Select.kr(In.kr(~midiTPbutton[0]).linlin(0,1,1,0),~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\tSamplerPad, {
		arg trigIn=0, amp=1, out=~peaveyBus, open=1, midinote=60, dur=5.5;
		var sig, buf, rate, trig, rand;
		trig = KeyState.kr(trigIn, 0, 1, 0);
		// rate = TRand.kr(0.5, 2.6,trig);
		rate = (midinote - 43).midiratio + In.kr(~midiFaders[1]).linlin(0,1,0,2) - In.kr(~midiKnobs[1]).linlin(0,1,0,0.5);
		buf = TChoose.kr(trig, Select.kr(In.kr(~midiTPbutton[1]) + In.kr(~midiTPbutton[2]), Select.kr(In.kr(~midiTPbutton[0]).linlin(0,1,1,0),~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * EnvGen.kr(Env.asr(0.01,1,0.25), gate: trig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\tSamplerKarp, {
		arg trigIn=0, amp=1, out=~peaveyBus, open=1, midinote=60, dur=5.5;
		var sig, buf, rate, trig, rand, local;
		trig = KeyState.kr(trigIn, 0, 1, 0);
		// rate = TRand.kr(0.5, 2.6,trig);
		rate = (midinote - 43).midiratio + In.kr(~midiFaders[1]).linlin(0,1,0,2) - In.kr(~midiKnobs[1]).linlin(0,1,0,0.5);
		buf = TChoose.kr(trig, Select.kr(In.kr(~midiTPbutton[1]) + In.kr(~midiTPbutton[2]), Select.kr(In.kr(~midiTPbutton[0]).linlin(0,1,1,0),~samples)));
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, trigger: trig);
		sig = sig * EnvGen.kr(Env.asr(0.01,1,0.25), gate: trig);
		local = LocalIn.ar(1);
		sig = LPF.ar((0.95 * DelayC.ar(local, 10, (In.kr(~midiFaders[5]).linexp(0,1,1,50) + In.kr(~midiKnobs[5]).linlin(0,1,0,2.5)) / (2 * midinote.midicps))) + sig, 1000);
		LocalOut.ar(sig);
		sig = sig * amp;
		Out.ar(out,sig);
	}).add;

	SynthDef.new(\karplus, {
		arg amp=1, out=0, open=1, midinote=60, dur=5.5, factor=1;
		var sig, buf, rate, local;
		rate = (midinote-43).midiratio + In.kr(~midiFaders[1]).linlin(0,1,0,2) - In.kr(~midiKnobs[1]).linlin(0,1,0,0.5);
		buf = Select.kr((Rand(0,9) + Rand(0,3)) % 10, ~samples[1][1]);
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, startPos: 100, loop: 0, doneAction: Done.freeSelf);
		local = LocalIn.ar(1);
		sig = LPF.ar((0.99 * DelayC.ar(local, 10, (In.kr(~midiFaders[5]).linexp(0,1,1,50) + In.kr(~midiKnobs[5]).linlin(0,1,0,2.5)) / (2 * midinote.midicps))) + sig, 4000);
		LocalOut.ar(sig);
		sig = sig * Env.perc(0, dur + 0.2, curve: -0.05)
		.kr(doneAction: Done.freeSelf);
		sig = sig * amp * 0.5;
		Out.ar(out,sig);
	}).add;

	// not sure if i need this, but will keep it around
	SynthDef(\looper, {
		arg out=0, bufnum=0, length=100000, midinote=40, vol=1, devo=0, gate=1;
		var rate, sig, sigA, sigX, sigY, phasor1, phasor2, env1, env2, deviation, trig;
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
		sig = EnvGen.kr(Env.asr, gate, doneAction: Done.freeSelf) * (sigA + sigX + sigY);
		Out.ar(out, (sig))
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
		sig = LPF.ar((0.975 * DelayC.ar(local, 10, (In.kr(~midiFaders[5]).linexp(0,1,1,50) + In.kr(~midiKnobs[5]).linlin(0,1,0,2)) / (2 * midinote.midicps))) + sig, 4000);
		LocalOut.ar(sig);
		sig = EnvGen.kr(Env.asr, gate, doneAction: Done.freeSelf) * sig;
		Out.ar(out, (sig))
	}).add;

	// add synth defs for FX
	SynthDef(\reverb, {
		arg in=0, mix=1, out=0;
		var sig, wet;
		sig = In.ar(in,1) * In.kr(~midiFaders[6]);
		sig = Pan2.ar(sig, LFDNoise1.kr(0.2, 0.25));
		sig = FreeVerb2.ar(sig[0], sig[1], mix: In.kr(~midiKnobs[6]), room: 0.8, damp: 0.5);
		Out.ar(out,Limiter.ar(sig * (In.kr(~midiFaders[7]))));

	}).add;

	SynthDef(\peavey, {
		arg in=0, mix=1, out=0;
		var sig, sog, wet;
		sig = In.ar(in,1);
		Out.ar(~peaveyOut, sig);
		sog = SoundIn.ar(2, 1);
		Out.ar(out,sog);

	}).add;

	SynthDef.new(\locMax, {arg in = 0, out=0; var sig, chain, trig;
		sig = In.ar(in,1);
		chain = FFT(LocalBuf(1024), sig);
		trig = Onsets.kr(chain, 0.1, \wphase);
		// chain = PV_LocalMax(chain, MouseX.kr(0, 10));
		chain = PV_MagShift(chain, In.kr(~midiKnobs[4]).linlin(0,1,1,0.1));
		chain = PV_BinScramble(chain,In.kr(~midiFaders[4]),1,trig);
		Out.ar(out, IFFT(chain));
	}).add;

	SynthDef(\triggerer, {
		var trigger;
		trigger = Gate.ar(SoundIn.ar(~morganIn), In.kr(~midiSbutton[3]));
		trigger = FFT(LocalBuf(64),trigger);
		trigger = Onsets.kr(trigger, In.kr(~midiFaders[3]).linlin(0,1,3,0), \rcomplex);
		SendReply.kr(
			trigger,
			cmdName: '/tLow',
			values: [trigger],
			replyID: 1
		);
		Out.kr(~triggerBus, trigger);
	}).add;

	SynthDef(\beatTracker, {
		var chain, quart, eight, sixt, tempo;
		chain = FFT(LocalBuf(512), SoundIn.ar(~morganIn));
		#quart, eight, sixt, tempo = BeatTrack.kr(chain, 0);
		quart = quart * In.kr(~midiSbutton[2]);
		eight = eight * In.kr(~midiMbutton[2]);
		sixt = sixt * In.kr(~midiRbutton[2]);
		SendReply.kr(
			quart,
			cmdName: '/quart',
			values: [quart],
			replyID: 2
		);
		Out.kr(~triggerQuart, quart);
		SendReply.kr(
			eight,
			cmdName: '/eight',
			values: [eight],
			replyID: 3
		);
		Out.kr(~triggerEight, eight);
		SendReply.kr(
			sixt,
			cmdName: '/sixt',
			values: [sixt],
			replyID: 4
		);
		Out.kr(~triggerSixt, sixt);
	}).add;

	s.sync;


	// add groups
	~makeNodes = {
		~srcgroup = Group.new;
		~rgroup = Group.after(~srcgroup);
		~r = Synth(\reverb, [\in, ~rbus, \mix, 0.2, \out, 0], ~rgroup);
		// note -> peavy should be dynamically routable to out/reverb/other maybe with pan?
		~sgroup = Group.after(~srcgroup);
		~l = Synth(\locMax, [\in, ~lMaxBus, \out, ~rbus], ~sgroup);


		~ggroup = Group.after(~srcgroup);
		~g = Synth(\peavey, [\in, ~peaveyBus, \out, ~lMaxBus], ~ggroup);
		// outputs here can be dynamically set during part changes -> ~g.set(\out, 0) etc.

		~triggerGroup = Group.after(~srcgroup);
		~tMorg = Synth(\triggerer, target: ~triggerGroup);
		~tBeat = Synth(\beatTracker, target: ~triggerGroup);
		~numPadGroup = Group.new;
	};

	// redo groups when hitting cmd .
	ServerTree.add(~makeNodes);
	ServerTree.run;

	s.sync;

	~numPad = Array.new(20);
	~numPadScale = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 48;});

	~keyOrder.do({arg val, index;
		~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \target, ~numPadGroup, \out, ~peaveyBus
	]);)});

	MIDIdef.cc(\numPadMode, { |val|
		if (val==0, {
			~numPad.do({|synth| synth.free;});
			~numPad = Array.new(20);

			~keyOrder.do({arg val, index;
				~numPad.add(Synth(\tSamplerPad, [\trigIn, ~keys[val], \midinote, ~numPadScale[index],\target, ~numPadGroup, \out, ~peaveyBus
				]);
			)});
		}, {
			~numPad.do({|synth| synth.free;});
			~numPad = Array.new(20);

			~keyOrder.do({arg val, index;
				~numPad.add(Synth(\tSamplerKarp, [\trigIn, ~keys[val], \midinote, ~numPadScale[index], \target, ~numPadGroup, \out, ~lMaxBus
				]);
			)});
		})
}, 33);});

MIDIIn.doControlAction(num: 33, val:0);

)