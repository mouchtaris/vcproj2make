(function{
	API = [

	];

	s = [ 
		@attr {
			@set method (v) { std::print("Set through attribute. ID(", self.id, ")\n"); @attr = v; }
			@get method { std::print("Get through attribute. ID(", self.id, ")\n"); return @attr; }
		},
		method id { return "S"; } ];

	std::print(API, "\n", s, "\n");

	std::delegate(s, API);

	std::print(s.attr);

	(function {
	 std::print(...);
	})("print self");
});




(function {
	function assign (obj, val) {
		std::print(obj, val, "\n");
		return obj;
	}
	o = [@a: 4, @b: 5];
	o.= = assign;
	
	o = 18;
	o = 19;
	o = 020;
	
	s = [@c: 6, @d: 7];
	std::delegate(s, o);
	s = 21, s = 22, s = 23;
	p = [];
	std::delegate(s, p);
	
})();