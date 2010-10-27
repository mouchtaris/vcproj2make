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