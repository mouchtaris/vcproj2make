a = [
	@v {
		@set method (v) { @v = v; }
		@get method { return @v; }
	},
	@v: 12
];

std::print(a.v, "\n")
;


std::tabredefineattribute(
	a, #v,
	std::error,
	[ method @operator() { std::print("through me\n");return std::tabgetattribute(@obj, #v); }, @obj:a ]
);
std::tabsetattribute(a, #v, 12);
std::print(a.v, "\n")
;
a.v = #q3;
