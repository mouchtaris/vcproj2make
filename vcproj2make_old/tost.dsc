	function dobj_equal (one, two) {
		local previousOverloadingEnabled1 = std::tabisoverloadingenabled(one);
		local previousOverloadingEnabled2 = std::tabisoverloadingenabled(two);
		std::tabdisableoverloading(one);
		std::tabdisableoverloading(two);
		local result = one == two;
		if (previousOverloadingEnabled1)
			std::tabenableoverloading(one);
		if (previousOverloadingEnabled2)
			std::tabenableoverloading(two);
		return result;
	}
	
	const p__Object__ObjectID_id_key = "^^%@##^)@*$*)@%)!)@";
	const p__Object__Object_id_attribute_name = "$_ObjectID";
	o = [];
	id0 = [ { p__Object__ObjectID_id_key: 34 } ];
	idproto = [
		method @operator () { return self; },
		method @operator == (this, other) {
			assert( dobj_equal(this , self) );
			local c1= (local otherid = other[p__Object__ObjectID_id_key]);
			if (c1) 
					local c2 = otherid == local myid = self[p__Object__ObjectID_id_key];
			return c1 and c2;
		},
		method @ { return "^_^ ObjectID: " + self[p__Object__ObjectID_id_key]; },
		@tostring: @self."tostring()"
	];
	std::delegate(id0, idproto);
	std::tabnewattribute(o, p__Object__Object_id_attribute_name,
		function Object_setObjectID { std::error("Setting an object ID is not allowed"); },
		std::tabmethodonme(o, method Object_getObjectID { return std::tabget(self, p__Object__Object_id_attribute_name); })
	);
	std::tabsetattribute(o, p__Object__Object_id_attribute_name, id0);
	std::print(o."$_ObjectID");