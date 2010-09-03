// Get util library
u = std::libs::import("util");
assert( u );



/////////////////////////////////////////////////////////////////
// Class ProjectEntry
// --------------------------------------------------------------
// Static members
function ProjectEntry_validProjectID (id) {
	return // some heuristics
			u.isdeltastring(id)            and
			u.strlength(id) == (52-15+1)   and
			u.strchar(id, 0) == "{"        and
			u.strchar(id, u.strlength(id) - 1) == "}" and
	true;
}
// --------------------------------------------------------------
function ProjectEntry {
	static static_variables_initialised;
	static ProjectEntry_stateFields;
	static method_toString_for_ProjectEntry;
	static classy_ProjectEntry_class;
	static mixinsInstancesStateInitialisersArgumentsFunctors;
	static light_ProjectEntry_class;
	if (std::isundefined(static static_variables_initialised)) {
		static_variables_initialised = true;
		//
		ProjectEntry_stateFields = [ #ProjectEntry_parentReference, #ProjectEntry_dependencies ];
		//
		method_toString_for_ProjectEntry = (method toString_for_ProjectEntry {
			return "ProjectEntry[" +
					@getName() + "/" + @getID() + "/" + @getLocation() + "]";
		});
		function method_toString_for_ProjectEntry_installed (obj) {
			return std::tabmethodonme(obj, method_toString_for_ProjectEntry);
		}
		//
		// private methods
		function deps(projdata) {
			return u.dobj_checked_get(projdata, ProjectEntry_stateFields, #ProjectEntry_dependencies);
		}
		//
		classy_ProjectEntry_class = u.Class().createInstance(
			// stateInitialiser
			function ProjectEntry_stateInitialiser (new, validFieldsNames) {
				u.Class_checkedStateInitialisation(new, validFieldsNames,
					[
						{ #ProjectEntry_parentReference: ""              },
						{ #ProjectEntry_dependencies   : u.list_new() }
					]);
			},
			// prototype
			[
				method setParentReference (parentID) {
					u.assert_str( parentID );
					return u.dobj_checked_set(self, ProjectEntry_stateFields, #ProjectEntry_parentReference, parentID);
				},
				method getParentReference {
					local result = u.dobj_checked_get(self, ProjectEntry_stateFields, #ProjectEntry_parentReference);
					return result;
				},
				method addDependency (projID) {
					u.Assert( ProjectEntry_validProjectID(projID) );
					local dops = deps(self);
					local deps = dops;
					u.Assert( not u.iterable_contains(deps, projID) );
					u.list_push_back(deps, projID);
				},
				method Dependencies {
					return u.list_clone(deps(self));
				},
				// NOT API related
				method @ {
					return "{" + 
							(local gn = self.getName)()     + "," +  // TODO why @getName does not work?
							(local gi = self.getID)()       + "," + 
							(local gl = self.getLocation)() + "}";
				}
			],
			// mixInRequirements
			[],
			// stateFields
			ProjectEntry_stateFields,
			// class name
			#ProjectEntry
		);
		//
		mixinsInstancesStateInitialisersArgumentsFunctors = [
			@Namable  : lambda {["__noname__"]},
			@IDable   : lambda {["__noID__"  ]},
			@Locatable: lambda {["__nopath__"]}
		];
		// Mix-ins
		classy_ProjectEntry_class.mixIn(u.Namable     (), mixinsInstancesStateInitialisersArgumentsFunctors.Namable   );
		classy_ProjectEntry_class.mixIn(u.IDable      (), mixinsInstancesStateInitialisersArgumentsFunctors.IDable    );
		classy_ProjectEntry_class.mixIn(u.Locatable   (), mixinsInstancesStateInitialisersArgumentsFunctors.Locatable );
		//
		light_ProjectEntry_class = [
			@createInstance: function createInstance {
				return [
					method setName(name) { @name = name; },
					method setID  (id)   { @id = id; },
					method setParentReference(pr) { @pr = pr; },
					method setLocation(path) { @path = [@path:path, method deltaString { return @path; }]; },
					method addDependency(projID) { u.list_push_back(@deps, projID); },
					@deps: u.list_new(),
					method getName { return @name; },
					method getID { return @id; },
					method getParentReference { return @pr; },
					method getLocation { return @path; },
					method Dependencies { return u.iterable_clone_to_list(@deps); },
					{"()": method_toString_for_ProjectEntry_installed(@self)}
				];
			},
			{"$___CLASS_LIGHT___": "ProjectEntry"}
		];
	}
	return u.ternary(u.beClassy(),
			classy_ProjectEntry_class,
			light_ProjectEntry_class
	);
}
// --------------------------------------------------------------
function ProjectEntry_isaProjectEntry (obj) {
	return 
		(
			(local lightclass = (local class = ProjectEntry())."$___CLASS_LIGHT___") and
			lightclass == "ProjectEntry"
		)
		or
			u.Class_isa(obj, class)
	;
}


/////////////////////////////////////////////////////////////////
// Class ConfigurationManager
// --------------------------------------------------------------
function classy_ConfigurationManager {
	if (std::isundefined(static ConfigurationManager_stateFields))
		ConfigurationManager_stateFields = [#ConfigurationManager_configurationsMap];

	// Private methods
	function getconfigmap (this) {
		return u.dobj_checked_get(this, ConfigurationManager_stateFields, #ConfigurationManager_configurationsMap);
	}
	function setconfigmap (this, map) {
		return u.dobj_checked_set(this, ConfigurationManager_stateFields, #ConfigurationManager_configurationsMap, map);
	}
	//
	function check_configid (this, configid) {
		local result = false;
		if (not u.isdeltastring(configid) )
			u.error().AddError("Configuration ID has to be a stirng. "
					"Given id: ", u.inspect(configid));
		else
			result = true;
		return result;
	}
	function check_projid (this, projid) {
		 if ( not (local result = ProjectEntry_validProjectID(projid)))
			u.error().AddError("Invalid project id given: ", projid);
		return result;
	}
	function check_hasnoconfig (this, configid) {
		if ( not (local result = not this.hasConfiguration(configid)) )
			u.error().AddError("Configuration ", configid, " already registered");
		return result;
	}
	function check_hasconfig (this, configid) {
		if ( not (local result = this.hasConfiguration(configid)) )
			u.error().AddError("Configuration ", configid, " has not been registered");
		return result;
	}
	function check_hasnoproj (this, configid, projid) {
		if (not (local result = not this.hasProject(configid, projid)) )
			u.error().AddError("Configuration ", configid, " already has"
					"project ", projid, " registered");
		return result;
	}
	function check_hasproj (this, configid, projid) {
		if ( not (local result = this.hasProject(configid, projid)) )
			u.error().AddError("Configuration ", configid, " has no "
					"project ", projid, " registered");
		return result;
	}
	//
	// f(configID, projmap)
	function foreachconfiguration (this, f) {
		local configmap     = getconfigmap(this);
		local done          = false;
		local configs       = u.dobj_keys(configmap);
		local config_ite    = std::tableiter_new();
		for (std::tableiter_setbegin(config_ite, configs); not done and not std::tableiter_checkend(config_ite, configs); std::tableiter_fwd(config_ite)) {
			local configID = std::tableiter_getval(config_ite);
			done = not f(configID, configmap[configID]);
		}
	}
	//
	
	if (std::isundefined(static ConfigurationManager_class)) {
		ConfigurationManager_class = u.Class().createInstance(
			// stateInitialiser
			function ConfigurationManager_stateInitialiser (new, validFieldsNames) {
				u.Class_checkedStateInitialisation(
					new,
					validFieldsNames,
					[
						@ConfigurationManager_configurationsMap: [] // [sol_conf_id => [ projid => [ confid, buildable ], ...], ...]
					]
				);
			},
			// prototype
			[
				method addConfiguration (configurationID) {
					if (check_hasnoconfig(self, configurationID))
						getconfigmap(self)[configurationID] = [];
				},
				method hasConfiguration (configurationID) {
					local result = nil;
					if ( check_configid(self, configurationID) )
						result = u.dobj_contains_key(getconfigmap(self), configurationID);
					return result;
				},
				method Configurations {
					return u.dobj_keys(getconfigmap(self));
				},
				method hasProject (configurationID, projID) {
					local result = nil;
					if (check_hasconfig(self, configurationID) and check_projid(self, projID))
						result = u.dobj_contains_key(getconfigmap(self)[configurationID], projID);
					return result;
				},
				method hasProjectInAnyConfiguration (projID) {
					local result = nil;
					if ( check_projid(self, projID) ) {
						foreachconfiguration(self, local projectHavingDetector = [
							method @operator () (configurationID, configMap) {
								return not @result = @hasProject(configurationID, @projID);
							},
							@hasProject : self.hasProject, // why won't  @hasProject work?
							@projID     : projID
						]);
						result = projectHavingDetector.result;
					}
					return result;
				},
				method registerProjectConfiguration (solutionConfigurationID, projectID, projectConfigurationID) {
					if (check_hasnoproj(self, solutionConfigurationID, projectID) and check_configid(self, projectConfigurationID)) {
						local projmap = getconfigmap(self)[solutionConfigurationID];
						u.Assert( not projmap[projectID] );
						projmap[projectID] = [ {"config": projectConfigurationID}, {"buildable": false} ];
						//
						u.Assert( self.hasProject(solutionConfigurationID, projectID) );
					}
				},
				method Projects (solutionConfigurationID) {
					local result = nil;
					if ( check_hasconfig(self, solutionConfigurationID) )
						result = u.dobj_keys(getconfigmap(self)[solutionConfigurationID]);
					return result;
				},
				method markBuildable (solutionConfigurationID, projectID) {
					if ( check_hasproj(self, solutionConfigurationID, projectID) ) {
						local projconfig = getconfigmap(self)[solutionConfigurationID][projectID];
						if ( projconfig.buildable )
							u.warning("ConfigurationManager::markBuildable(): re-marking as buildable "
									"a buildable project: solution:", solutionConfigurationID,
									", project:", projectID);
						projconfig.buildable = true;
					}
				},
				method markNonBuildable (solutionConfigurationID, projectID) {
					if ( check_hasproj(self, solutionConfigurationID, projectID) ) {
						local projconfig = getconfigmap(self)[solutionConfigurationID][projectID];
						if ( not projconfig.buildable )
							u.warning("ConfigurationManager::markBuildable(): re-marking as non-buildable "
									"a non-buildable project: solution:", solutionConfigurationID,
									", project:", projectID);
						projconfig.buildable = false;
					}
				},
				method isNonBuildable (solutionConfigurationID, projID) {
					local result = false;
					if ( check_hasproj(self, solutionConfigurationID, projID) )
						result = not getconfigmap(self)[solutionConfigurationID][projID].buildable;
					return result;
				},
				method isBuildable (solutionConfigurationID, projID) {
					return not self.isNonBuildable(solutionConfigurationID, projID);
					// TODO why not @isNonBuildable ?
				},
				method isBuildableInAnyConfiguration (projID) {
					local result = nil;
					if ( check_projid(self, projID) ) {
						foreachconfiguration(self, local buildableDetector = [
							method @operator () (solutionConfigurationID, configurationsMap) {
								local projID = @projID;
								if ( not (local keep_iterating = not (@result = @isBuildable(solutionConfigurationID, projID))) ) {
									u.Assert( configurationsMap[projID] );
									u.Assert( not @isNonBuildable(solutionConfigurationID, projID) );
								}
								return keep_iterating;
							},
							@projID        : projID,
							@isBuildable   : self.isBuildable, // TODO why @isBuildable doesn't work?
							@isNonBuildable: self.isNonBuildable // TODO as above
						]);
						result = buildableDetector.result;
					}
					return result;
				},
				method isNonBuildableInEveryConfiguration (projID) {
					local result = nil;
					if ( check_projid(self, projID) ) {
						foreachconfiguration(self, local notnonbuildable_detector = [
							method @operator () (solutionConfigurationID, configurationMap) {
								local projID = @projID;
								if ( not (local keep_iterating = @result = @isNonBuildable(solutionConfigurationID, projID)) ) {
									u.Assert( configurationMap[projID].buildable );
									u.Assert( @isBuildable(solutionConfigurationID, projID) );
								}
								return keep_iterating;
							},
							@projID         : projID,
							@isBuildable    : self.isBuildable,
							@isNonBuildable : self.isNonBuildable
						]);
						result = notnonbuildable_detector.result;
					}
					return result;
				}
			],
			// mixinRequirements
			[],
			// state field names
			ConfigurationManager_stateFields,
			// class name
			#ConfigurationManager
		);

		ConfigurationManager_class.DumpCore = (
				function DumpCore (this, target) {
					target."$__MAGIC_MUSHROOM_magic_mushroom__" = 43;
					target."43" = "$__SPORES_spores_SPORES_spores__";
					target."$__MM_confmap" = 
					//		u.dval_copy_into([],
							getconfigmap(this)
					//		)
					;
					return target;
				});
		ConfigurationManager_class.CreateFromCore = (
				function CreateFromCore (from) {
					assert( from."$__MAGIC_MUSHROOM_magic_mushroom__" == 43 );
					assert( from."43" == "$__SPORES_spores_SPORES_spores__" );
					local result = ConfigurationManager_class.createInstance();
					setconfigmap(result,
						//	u.dval_copy(
							from."$__MM_confmap"
						//	)
					);
					return result;
				});
	}

	return ConfigurationManager_class;
}

function light_ConfigurationManager {
	if ( std::isundefined(static ConfigurationManager_class) )
		ConfigurationManager_class = [
			method createInstance {
				return [
					{ u.pfield(#ConfigurationManager_configurationsMap): [] },
					method getmap { return self[u.pfield("ConfigurationManager_configurationsMap")]; },
					//
					method addConfiguration (conf) { @getmap()[conf] = []; },
					method Configurations { return u.dobj_keys(@getmap()); },
					method registerProjectConfiguration (conf, projid, projconf) { @getmap()[conf][projid] = [ {"id": projconf}, {"buildable": false}]; },
					method Projects (conf) { return u.dobj_keys(@getmap()[conf]); },
					method markNonBuildable (conf, projid) { @getmap()[conf][projid].buildable = false; },
					method markBuildable (conf, projid) { @getmap()[conf][projid].buildable = true; },
					method hasConfiguration (conf) { return not not @getmap()[conf]; },
					method hasProject (conf, projid) { return not not @getmap()[conf][projid]; },
					method isNonBuildable (conf, projid) { return not @getmap()[conf][projid].buildable; },
					method isBuildable (conf, projid) { return not not @getmap()[conf][projid].buildable; },
					{ "isBuildableInAnyConfiguration"     : std::tabmethodonme(@self, (local stealingPrototype = classy_ConfigurationManager().getPrototype()).isBuildableInAnyConfiguration) },
					{ "isNonBuildableInEveryConfiguration": std::tabmethodonme(@self, stealingPrototype.isNonBuildableInEveryConfiguration)     },
					{ "hasProjectInAnyConfiguration"      : std::tabmethodonme(@self, stealingPrototype.hasProjectInAnyConfiguration)           }
				];
			}
		];
	return ConfigurationManager_class;
}

function ConfigurationManager {
	return u.ternary(u.beClassy(),
		classy_ConfigurationManager,
		light_ConfigurationManager
	)();
}
function ConfigurationManager_isaConfigurationManager (obj) {
	local confmanag = ConfigurationManager();
	if (confmanag == light_ConfigurationManager())
		local result = true;
	else
		result = u.Class_isa(obj, confmanag);
	return result;
}


function ProjectEntryHolder {
	static mixy_ProjectEntryHolder_class;
	static classy_ProjectEntryHolder_class;
	static light_ProjectEntryHolder_class;
	static ProjectEntryHolder_stateFields;
	static method_toString_for_ProjectEntryHolders;
	if (std::isundefined(static static_variables_initialised)) {
		static_variables_initialised = true;
		//
		// private methods (commonly used)
		ProjectEntryHolder_stateFields = [#ProjectEntryHolder_entries];
		function getentries (this) {
			return u.dobj_checked_get(this, ProjectEntryHolder_stateFields, #ProjectEntryHolder_entries);
		}
		//
		method_toString_for_ProjectEntryHolders = (method toString_for_ProjectEntryHolders {
			return 
					"{" + 
					(function (entries) {
						local result = "";
						local keys = u.dobj_keys(entries);
						if (local first_key = keys[0]) {
							result += entries[first_key];
							keys[0] = nil;
						}
						foreach (local key, keys)
							result += ", " + entries[key];
						return result;
					})(getentries(self)) +
					"}"
			;
		});
		function method_toString_for_ProjectEntryHolders_installed (obj) {
			return std::tabmethodonme(obj, method_toString_for_ProjectEntryHolders);
		}
		//
		mixy_ProjectEntryHolder_class = u.Class().createInstance(
			// state initialiser
			u.nothing,
			// prototype
			[],
			// mix in requirements
			[],
			// state fields
			[],
			// class name
			#ProjectEntryHolder
		);
		mixy_ProjectEntryHolder_class.mixIn(
			u.IDableHolder("ProjectEntry"), lambda { [] }
		);
		//
		classy_ProjectEntryHolder_class = u.Class().createInstance(
			function ProjectEntryHolder_stateInitialiser (newProjectHolder, validFieldsNames) {
				u.Class_checkedStateInitialisation(
						newProjectHolder,
						validFieldsNames,
						[
							{#ProjectEntryHolder_entries: []}
						]
				);
			},
			// prototype
			[
				method addProjectEntry (projectEntry) {
					u.Assert( ::ProjectEntry_isaProjectEntry(projectEntry) );
					if ((local entries = getentries(self))[local id = projectEntry.getID()])
						u.error().AddError("Project entry already added in holder: ", projectEntry);
					else
						entries[id] = projectEntry;
				},
				method getProjectEntry (id) {
					if (not local result = getentries(self)[id] )
						u.error().AddError("Project entry with ID ", id, " not in holder");
					else
						u.Assert( result.getID() == id );
					return result;
				},
				method ProjectEntries {
					return u.dobj_copy(getentries(self));
				},
				// NOT API related
				{"()": method_toString_for_ProjectEntryHolders_installed(@self)}
			],
			// mix in requirements
			[],
			// valid fields names
			ProjectEntryHolder_stateFields,
			// class name
			#ProjectEntryHolder
		);
		
		light_ProjectEntryHolder_class = [
			method createInstance {
				return [
					{ u.pfield(ProjectEntryHolder_stateFields[0]): [] },
					method addProjectEntry (projectEntry) { getentries(self)[projectEntry.getID()] = projectEntry; },
					method getProjectEntry (id) { return getentries(self)[id]; },
					method ProjectEntries { return u.dobj_copy(getentries(self)); },
					// NOT API relaated
					{"()": method_toString_for_ProjectEntryHolders_installed(@self)}
				];
			},
			{"$___CLASS_LIGHT___": "ProjectEntryHolder"}
		];
	}
	
	return u.ternary(u.beClassy(),
			classy_ProjectEntryHolder_class,
			light_ProjectEntryHolder_class
	);
}
function ProjectEntryHolder_isaProjectEntryHolder (obj) {
	return
		(
			(local classlight = (local class = ProjectEntryHolder())."$___CLASS_LIGHT___" )  and
			classlight == "ProjectEntryHolder"
		)
		or
			u.Class_isa(obj, class);
}


/////////////////////////////////////////////////////////////////
// SolutionData
function SolutionData_make (configurationManager, projectEntryHolder, solutionDirectory) {
	assert( u.Class_isa(configurationManager, ::ConfigurationManager()) );
	assert( ProjectEntryHolder_isaProjectEntryHolder(projectEntryHolder) );
	assert( u.isdeltastring(solutionDirectory) );
	return [
		@ConfigurationManager: configurationManager,
		@ProjectEntryHolder  : projectEntryHolder  ,
		@SolutionDirectory   : solutionDirectory
	];
}

/////////////////////////////////////////////////////////////////
// SolutionDataFactory
function SolutionDataFactory_DumpCore (sd, target) {
		return std::tabextend(target, sd);
}
function SolutionDataFactory_CreateFromCore (core) {
		return core;
}

////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("SolutionLoader/SolutionData",
	[ method @operator () {
		::ProjectEntry(), ::ConfigurationManager(), ::ProjectEntryHolder();
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
