// add triggers, ideally they can always run but do not always trigger stuff

(
~freeMorgan = Group.new(s, \addToHead);
~freeQuart = Group.new(s, \addToHead);
~freeEight = Group.new(s,\addToHead);
~freeSixt = Group.new(s, \addToHead);

a = [ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 ].collect({|val| val * 1;}).collect({|val| val + 40;});

Pdefn(\notes, Prand(a, inf));


Pdef(\morgan, Pbind(\instrument, \gatesampler, \midinote, Pdefn(\notes), \dur, inf, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\quart, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) - 7, \dur, inf, \amp, Phprand(0.8,0.4, inf), \group, ~freeQuart, \callback, Pfunc {~freeQuart.freeAll}, \out, ~peaveyBus));

Pdef(\eight, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) , \dur, inf, \amp, Phprand(0.8,0.4, inf), \group, ~freeEight, \callback, Pfunc {~freeSixt.freeAll}, \out, ~peaveyBus));

Pdef(\sixt, Pbind(\instrument, \gatesampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) + 12 , \dur, inf, \amp, Phprand(0.8,0.4, inf), \group, ~freeSixt, \callback, Pfunc {~freeSixt.freeAll}, \out, ~peaveyBus));

~morganPat= Pdef(\morgan).asStream;

~quart = Pdef(\quart).asStream;
~eight = Pdef(\eight).asStream;
~sixt = Pdef(\sixt).asStream;

)

(
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
}).play;

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
}).play;

// Respond to that reply

OSCdef(\tLowPlay, {
	|msg|
	"trigger this shit".postln;
	~morganPat.next(()).play;
}, '/tLow'); // <-- this has to match your cmdNam
OSCdef(\tquart, {
	|msg|
	"quart".postln;
	~quart.next(()).play;
}, '/quart'); // <-- this has to match your cmdNam
OSCdef(\teight, {
	|msg|
	"eight".postln;
	~eight.next(()).play;
}, '/eight'); // <-- this has to match your cmdNam
OSCdef(\tsixt, {
	|msg|
	"sixt".postln;
	~sixt.next(()).play;
}, '/sixt'); // <-- this has to match your cmdNam
)