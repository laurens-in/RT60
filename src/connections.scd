// goes down the node tree, lower nodes can't be connected to higher nodes
// local Max
~l.set(\out, 0);
~l.set(\out, ~peaveyBus);
~l.set(\out, ~rbus);

// shifter
~s.set(\out, 0);
~s.set(\out, ~peaveyBus);
~s.set(\out, ~rbus);

// guitar
~g.set(\out, 0);
~g.set(\out, ~rbus);

// reverb
~r.set(\out, 0)
