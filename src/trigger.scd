// add triggers, ideally they can always run but do not always trigger stuff
(
~tLow = {
	var trigger;
	trigger = FFT(LocalBuf(128), SoundIn.ar(~morganIn));
	trigger = Onsets.kr(trigger, 0.5, \rcomplex);
	SendReply.kr(
		trigger,
		cmdName: '/tLow',
		values: [trigger],
		replyID: 1
	);
}.play;
)

// Respond to that reply
(
OSCdef(\tLowPlay, {
	|msg|
	msg.postln;
	x.next(()).play;
}, '/tLow'); // <-- this has to match your cmdNam
)