function p (...) { std::print(..., "\n"); }
d = std::delegate;

proto = [
	method m1 {},
	method m2 {}
];

function makeObjectAccessChecker (obj) {
	local indices = [];
	foreach (local key: local el, obj)
		indices[key] = el;
	return [
		.indices: indices,
		method checkedFieldAccess (obj, field) {
			if (std::isoverloadableoperator(field))
				return nil;
			if (indices[field] != nil)
				return std::tabget(obj, field);
			std::error("WHAT FIELD IS THIS?!!?! " + field);
			return nil;
		}
	].checkedFieldAccess;
}
proto."." = makeObjectAccessChecker(proto);

a = [];
d(a, proto);

a.m1();
a.m2();
a.BoO();
