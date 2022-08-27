// karplus pad
~karplusPad = Synth(\karplusL, [\midinote, 48, \bufnum, ~samples[1][1][1], \length, 80000, \out, ~peaveyBus]);
~karplusPad.set(\gate, 0);
~karplusPad.set(\out, ~lMaxBus);

// normal looper
~looperPad = Synth(\looper, [\midinote, 60, \bufnum, ~samples[1][1][0], \length, 80000, \out, ~rbus]);
~looperPad.set(\gate, 0);

~looper.set(\out, ~peaveyBus);
~looperPad.set(\out, ~lMaxBus);
~looper.set(\out, ~shifterBus);