// add triggers, ideally they can always run but do not always trigger stuff

(
Pdefn(\notes, Pwrand([Pwhite(38, 48, 1), Pwhite(68, 78,1)], [0.4, 0.6], inf));

Pdef(\morgan, Pbind(\instrument, \midisampler, \midinote, Pdefn(\notes) , \dur, Pwhite(0.1, 1.5,inf), \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));



Pdef(\quart, Pbind(\instrument, \midisampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) - 7, \dur, 1, \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\eight, Pbind(\instrument, \midisampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) , \dur, Pwhite(0.1, 0.2,inf), \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));

Pdef(\sixt, Pbind(\instrument, \midisampler, \midinote, Pseq([Pwhite(43,60,1), 40, 40, 40, 40, 40, 40], inf) + 12 , \dur, Pwhite(0.1, 0.2,inf), \amp, Phprand(0.8,0.4, inf), \out, ~peaveyBus));



~morganPat= Pdef(\morgan).asStream;

~quart = Pdef(\quart).asStream;
~eight = Pdef(\eight).asStream;
~sixt = Pdef(\sixt).asStream;

)

(
SynthDef(\triggerer, {
	var trigger;
	trigger = Gate.ar(SoundIn.ar(~morganIn), In.kr(~midiSbutton[3]));
	trigger = FFT(LocalBuf(128),trigger);
	trigger = Onsets.kr(trigger, In.kr(~midiFaders[3]).linlin(0,1,0,3), \rcomplex);
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