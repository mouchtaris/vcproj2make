p = [
	method @operator () (...) {
		std::print(..., "\n");
		return "true";
	},
	{ "." : function (t, i) {
		local func = std::tabget(t, "()");
		if (i == "()")
			return func;
		func(i);
		return "true";
	}}
];

d = std::delegate;

p("hi?");

/*
foreach (local k: local e,
[	method iterator {
		return [
			@begin: true,
			method setbegin (c) { @begin = p("setbegin"); },
			method checkend (c) {
				p("checkend");
				return not @begin;
			},
			method getval { return p.getval; },
			method getindex { return p.getindex; },
			method fwd { @begin = false; }
		];
	}
])
	p("key  = ", k, " element = ", e);
	*/