// goes down the node tree, lower nodes can't be connected to higher nodes
// guitar
~g.set(\out, ~mainOut);
~g.set(\out, ~rbus);
~g.set(\out, ~lMaxBus);
~g.set(\out, ~shifterBus);

// local Max
~l.set(\out, ~mainOut);
~l.set(\out, ~peaveyBus);
~l.set(\out, ~rbus);

// shifter
~s.set(\out, ~mainOut);
~s.set(\out, ~peaveyBus);
~s.set(\out, ~rbus);

// reverb
~r.set(\out, ~mainOut);
