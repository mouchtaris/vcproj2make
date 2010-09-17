u = std::libs::import("util");
assert( u );

function VariableEvaluator {
	static VariableEvaluator_class_light;
	static VariableEvaluator_class_classy;
	static VariableEvaluator_stateFields;
	if ( std::isundefined(static static_variables_initialised) ) {
		VariableEvaluator_stateFields = [ #VariableEvaluator_variables, #VariableEvaluator_root ];
		//
		// private methods
		function p_getVariables (this) {
			local result = u.dobj_checked_get(this, VariableEvaluator_stateFields, #VariableEvaluator_variables);
			return result;
		}
		function p_getRoot (this) {
			local result = u.dobj_checked_get(this, VariableEvaluator_stateFields, #VariableEvaluator_root);
			return result;
		}
		function p_hasVariable (this, varname) {
			u.assert_str( varname );
			local result = p_getVariables(this)[varname];
			return u.toboolean(result);
		}
		function p_generateVariable (this, varname) {
			// TODO add variables according to case
			return false;
		}
		//
		// classy implementation
		VariableEvaluator_class_classy = u.Class().createInstance(
			// state initialiser
			function VariableEvaluator_stateInitialiser (newVariableEvaluatorInstance, validFieldsNames, solutionDirectory) {
				local root = u.Path_fromPath(solutionDirectory, false);
				u.Assert( u.Path_isaPath(root) );
				u.Class_checkedStateInitialisation(
					newVariableEvaluatorInstance,
					validFieldsNames,
					[
						{#VariableEvaluator_variables: []  },
						{#VariableEvaluator_root     : root}
					]);
			},
			// prototype
			[
				method eval (varname) {
					u.assert_str( varname );
					if ( p_hasVariable(self, varname) )
						local result = p_getVariables(self)[varname];
					else if ( not result = p_generateVariable(self, varname) )
						u.error().AddError("Variable ", varname, " cannot be evaluated");
					return result;
				}
			],
			// mix in requirements
			[],
			// state fields
			VariableEvaluator_stateFields,
			// class name
			#VariableEvaluator
		);
		//
		// light implementaton
		VariableEvaluator_class_light = [
			method createInstance (root) {
				return [
					{u.pfield(VariableEvaluator_stateFields[0]): []                       },
					{u.pfield(VariableEvaluator_stateFields[1]): u.Path_fromPath(root)    },
					{#eval: u.methodinstalled(@self, VariableEvaluator_class_classy.eval) }
				];
			},
			{"$___CLASS_LIGHT___": "VariableEvaluator"}
		];
		//
		static_variables_initialised = true;
	}
	return u.ternary(u.beClassy(),
			VariableEvaluator_class_classy,
			VariableEvaluator_class_light
	);
}


////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("SolutionLoader/VariableEvaluator",
	[ method @operator () {
		::VariableEvaluator();
		return true;
	}]."()",
	nil
);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////
