function p (...) { std::print(..., "\n"); }
d = std::delegate;

z = [
	@data: 6
];

a = [
	@meth {
		@set 	nil
		@get	method {
					::p("getting prop meth from an a, self.data: ", self.data);
					return self.data;
				}
	}
];

b = [
	{.data: 5}
];

::d(a, z);
::d(b, a);

::p(b.meth);

