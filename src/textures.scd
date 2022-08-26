// karplus pad
~karplusPad = Synth(\karplusL, [\midinote, 48, \bufnum, ~samples[1][1][1], \length, 80000, \out, ~rbus]);

~karplusPad.set(\out, ~lMaxBus);
~karplusPad.set(\gate, 0);

// normal looper
~looperPad = Synth(\looper, [\midinote, 60, \bufnum, ~samples[1][1][0], \length, 80000, \out, 0]);

~looper.set(\out, ~peaveyBus);
~looperPad.set(\out, ~lMaxBus);
~looper.set(\out, ~shifterBus);

Limit