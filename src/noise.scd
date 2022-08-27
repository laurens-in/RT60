(
SynthDef(\noiseMachine, {
	var sig, trig=1;
	trig = Impulse.kr(MouseY.kr(0.01,15));
	sig = BPF.ar(in: WhiteNoise.ar(), freq: MouseX.kr(0, 8000), rq: MouseY.kr(1.0, 0.0001), mul: 1.0, add: 0.0);
	sig = DelayL.ar(sig, 3, TRand.kr(0.05, 5, Dust.kr(3)));
	sig = EnvGen.kr(Env.perc(0.01, 0.1), trig) * sig;
	Out.ar(~rbus, sig);
}).play;
)