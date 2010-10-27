u = std::libs::import("util");
assert( u );

function VariableEvaluator {
	const SolutionDir_VariableName       = "SolutionDir"      ;
	const ConfigurationName_VariableName = "ConfigurationName";
	const ProjectName_VariableName       = "ProjectName"      ;
	const OutDir_VariableName            = "OutDir"           ;
	//
	static VariableEvaluator_class_light;
	static VariableEvaluator_class_classy;
	static VariableEvaluator_stateFields;
	if ( std::isundefined(static static_variables_initialised) ) {
		VariableEvaluator_stateFields = [ #VariableEvaluator_variables, #VariableEvaluator_root,
				#VariableEvaluator_solutionBaseDir, #VariableEvaluator_solutionConfigurationName];
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
			return not u.isdeltanil(result);
		}
		function p_setVariable (this, varname, value) {
			assert( u.isdeltastring(varname) );
			assert( u.isdeltastring(value)   );
			if ( p_hasVariable(this, varname) )
				u.error().AddError("Cannot set variable \"", varname,
						"\" in variable evaluator. Variable already defined "
						"with value \"", p_getVariables(this)[varname], "\"");
			else
				p_getVariables(this)[varname] = value;
		}
		function p_generateVariable (this, varname) {
			local result = false;
			if (varname == SolutionDir_VariableName)
				result = p_getVariables(this)[varname] = 
						u.dobj_checked_get(
								this,
								VariableEvaluator_stateFields,
								#VariableEvaluator_solutionBaseDir
						).deltaString() + "/" +
						u.dobj_checked_get(
								this,
								VariableEvaluator_stateFields,
								#VariableEvaluator_root
						).basename() + "/"
				;
			return result;
		}
		//
		// classy implementation
		VariableEvaluator_class_classy = u.Class().createInstance(
			// state initialiser
			function VariableEvaluator_stateInitialiser (newVariableEvaluatorInstance, validFieldsNames, solutionBaseDirectory, solutionDirectory, solutionConfigurationName) {
				assert( u.Path_isaPath(solutionBaseDirectory) );
				assert( u.isdeltastring(solutionConfigurationName) );
				local root = u.Path_fromPath(solutionDirectory, false);
				local base = solutionBaseDirectory;
				u.Assert( u.Path_isaPath(root) );
				u.Class_checkedStateInitialisation(
					newVariableEvaluatorInstance,
					validFieldsNames,
					[
						{#VariableEvaluator_variables                : []  },
						{#VariableEvaluator_root                     : root},
						{#VariableEvaluator_solutionBaseDir          : base},
						{#VariableEvaluator_solutionConfigurationName: solutionConfigurationName}
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
				},
				method setConfigurationName (configurationName) {
					p_setVariable(self, ConfigurationName_VariableName, configurationName);
				},
				method setProjectName (projectName) {
					p_setVariable(self, ProjectName_VariableName, projectName);
				},
				method setOutdir (outdir) {
					p_setVariable(self, OutDir_VariableName, outdir);
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
		static_variables_initialised = true;
	}
	return VariableEvaluator_class_classy;
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
