util = std::vmget("util");
assert( util );

//////////////////////////////
// *** MakefileManifestation
//     Produces Makefiles given a solution.
function MakefileManifestation(basedirpath, solution) {
	function escapeString(str) {
		if (str == "")
			return str;
		// escape for Makefile
		// - escape all "#"s with "\"s
		local result = ::util.strgsub(str, "#", "\\#");
		assert( result );
		// - "escape" all "$"s with "$$"
		result = ::util.strgsub(result, "$", "$$");
		assert( result );
		//
		// escape for bash
		// - replace all "'"s with "'\''"s
		result = ::util.strgsub(result, "'", "'\\''");
		assert( result );

		return result;
	}
	function deltastringToString(str) {
		::util.assert_str( str );
		return escapeString(str);
	}
	function pathToString(path) {
		assert( ::util.Path_isaPath(path) );
		return deltastringToString(path.deltaString());
	}
	// struct Option
	// createInstance(prefix_const_Or_f, value_const_or_f)
	function Option {
		if (std::isundefined(static Option_class))
			Option_class = ::util.Class().createInstance(
				// stateInitialiser
				function Option_stateInitialiser(newOptionInstance, validStateFieldsNames, prefix_const_or_f, value_const_or_f) {
					::util.assert_or( ::util.isdeltastring(prefix_const_or_f) , ::util.isdeltacallable(prefix_const_or_f) );
					::util.assert_or( ::util.isdeltastring(prefix_const_or_f) , ::util.isdeltacallable(value_const_or_f)  );
					::util.Class_checkedStateInitialisation(
						newOptionInstance, validStateFieldsNames,
						[ {#Option_prefix: prefix_const_or_f}, {#Option_value: value_const_or_f} ]
					);
				},
				// prototype
				[
					method prefix {
						local result = ::util.val(::util.dobj_checked_get(self, #Option_prefix));
						::util.assert_or( ::util.isdeltastring(result) , ::util.isdeltanil(result) );
						return result;
					},
					method value {
						local result = ::util.val(::util.dobj_checked_get(self, #Option_value));
						::util.assert_or( ::util.isdeltastring(result) , ::util.isdeltanil(result) );
						return result;
					}
				],
				// mixInRequirements
				[],
				// stateFields
				[#Option_value, #Option_prefix],
				// className
				#Option
			);
		return Option_class;
	}
	function optionPair(prefix, value) {
		return Option().createInstance(prefix, value);
	}
	function optionsFromIterableConstantPrefixAndValueToStringFunctor(iterable, prefix, valueToStringFunctor) {
		local result = std::list_new();
		foreach (local value, iterable) {
			local valueString = valueToStringFunctor(value);
			if (valueString) {
				::util.assert_str( valueString );
				result.push_back(optionPair(prefix, valueString));
			}
		}
		return result;
	}
	function cppOptionsFromDependencies(basedir, dependencies) {
		local result = std::list_new();
		foreach (local dep, dependencies)
			if (dep.isLibrary())
				result.push_back(optionPair(
					// prefix getter functor
					[
						method @operator () {
							assert( @dep.isLibrary() );
							return "-I";
						},
						@dep: dep
					],
					// value getter functor
					[
						method @operator () {
							local dep = @dep;
							local basedir = @basedir;
							assert( dep.isLibrary() );
							return pathToString(
									basedir
											.Concatenate(dep.getLocation())
											.Concatenate(dep.getAPIDirectory())
							);
						},
						@dep       : dep     ,
						@basedir   : basedir
					]
				));
		return result;
	}
	function ldOptionsFromSubprojects(parent_project, subprojects) {
		local result = std::list_new();
		foreach (local subproj, subprojects)
			if (subproj.isLibrary()) {
				// Add a library path option (-L)
				result.push_back(
					optionPair(
						// prefix getter
						[
							method @operator () {
								assert( @subproj.isLibrary() );
								return "-L";
							},
							@subproj: subproj
						],
						// value getter
						[
							method @operator () {
								local subproj = @subproj;
								local parentproj = @parentproj;
								assert( subproj.isLibrary() );
								return pathToString(
									parentproj.getLocation()
											.Concatenate(subproj.getLocation())
											.Concatenate(subproj.getOutputDirectory())
								);
							},
							@subproj   : subproj,
							@parentproj: parent_project
						]
					)
				);
				// Add a library linking option (-l)
				result.push_back(
					optionPair(
						// prefix getter
						[
							method @operator () {
								assert( @subproj.isLibrary() );
								return "-l";
							},
							@subproj: subproj
						],
						// value getter
						[
							method @operator () {
								local subproj = @subproj;
								assert( subproj.isLibrary() );
								local parentproj = @parentproj;
								return deltastringToString(subproj.getOutputName());
							},
							@subproj: subproj
						]
					)
				);
			}
		return result;
	}
	function pathToPathWithoutParentAndSelfDirectories(path) {
		local pathstr = path.deltaString();
		pathstr = ::util.strgsub(pathstr, "../", "__/");
		pathstr = ::util.strgsub(pathstr, "./" , "_/" );
		return ::util.Path_castFromPath(pathstr);
	}
	function pathMapping(paths, pathmapf) {
		return ::util.iterable_map(paths,
			[
				method @operator ()(path) {
					assert( ::util.Path_isaPath(path) );
					local newpath = @pathmapf(path);
					assert( ::util.Path_isaPath(newpath) );
					return newpath;
				},
				@pathmapf: pathmapf
			]
		);
	}
	function relocateAndReextensionise(prefixpath, name, ext) {
		assert( ::util.Path_isaPath(prefixpath) );
		assert( ::util.Path_isaPath(name) );
		::util.assert_str(ext);
		return prefixpath.Concatenate(name.asWithExtension(ext));
	}
	function transformSources(proj, builddir, transformationExtensionPrefix) {
		assert( ::util.CProject_isaCProject(proj) );
		assert( ::util.Path_isaPath(builddir) );
		
		local prefixpath = builddir;
		local ext        = proj[transformationExtensionPrefix + #Extension]();
		local pathmapper = relocateAndReextensionise;
		pathmapper = ::util.bindfront(pathmapper, prefixpath);
		pathmapper = ::util.bindback(pathmapper, ext);
		pathmapper = ::util.fcomposition(pathmapper, pathToPathWithoutParentAndSelfDirectories);
		return pathMapping(proj.Sources(), pathmapper);
	}
	function objectsFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Object);
	}
	function dependenciesFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Dependency);
	}
	
	function appendCommandsFromSubprojects(subprojects, commands) {
		foreach (local subproj, subprojects)
			std::list_push_back(commands,
					"( cd " + subproj.getLocation().deltaString() + " && ${MAKE} -f " + subproj.getName() + "Makefile.mk )"
			);
	}
	
	if (std::isundefined(static makemani))
		makemani = [
			// Utility methods
			method writeLine(...) {
				local fh = @fh;
				std::filewrite(fh, ::util.ENDL(), "        ");
				::util.foreacharg(arguments,
					[
						method @operator () (arg) {
							std::filewrite(@fh, arg);
							return true;
						},
						@fh: fh
					]);
				std::filewrite(fh, " \\");
			},
			method writePre(ID) {
				if (local pres = @config[ID + "_pre"])
					foreach (local preflag, pres)
						@writeLine(preflag);
				else
					std::error("No iterable given for Manifestation Configuration \"Makefile\" for option " + ID + "_pre");
			},
			method writePost(ID) {
				if (local posts = @config[ ID + "_post"])
					foreach (local postflag, posts)
						@writeLine(postflag);
				else
					std::error("No iterable given for Manifestation Configuration \"Makefile\" for option " + ID + "_post");
			},
			// iterable contains Option instances
			method writePrefixedOptions(iterable) {
				foreach (local pair, iterable) {
					local prefix = pair.prefix();
					local value  = pair.value();
					if (prefix) {
						::util.assert_str( prefix );
						::util.assert_str( value );
						@writeLine(prefix, "'", value, "'");
					}
				}
			},

			// FLAGS
			// Specific flag methods
			method writeFlagspaceHeader {
				std::filewrite(@fh, "# Flagspace", ::util.ENDL(), "SHELL = /bin/bash", ::util.ENDL());
			},
			method writeDependencyRelatedCPPFLAGS {
				local options = cppOptionsFromDependencies(
						@basedir,
						@proj.Dependencies());
				@writePrefixedOptions(options);
			},
			method writeCPPFLAGS {
				std::filewrite(@fh, "CPPFLAGS = \\");
				@writePre(#CPPFLAGS);
				@writeDependencyRelatedCPPFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.PreprocessorDefinitions(), "-D", deltastringToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.IncludeDirectories()     , "-I", pathToString));
				@writePost(#CPPFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeSubprojectRelatedLDFLAGS {
				local subprojGeneratedOptions = ldOptionsFromSubprojects(@proj, @proj.Dependencies());
				@writePrefixedOptions(subprojGeneratedOptions);
			},
			method writeLDFLAGS {
				std::filewrite(@fh, "LDFLAGS = \\");
				@writePre(#LDFLAGS);
				@writeSubprojectRelatedLDFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.LibrariesPaths(), "-L", pathToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.Libraries()     , "-l", pathToString));
				@writePost(#LDFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeCXXFLAGS {
				std::filewrite(@fh, "CXXFLAGS = \\");
				@writePre(#CXXFLAGS);
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(["pedantic", "Wall", "ansi"], "-", deltastringToString));
				@writePost(#CXXFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeFlags {
				@writeFlagspaceHeader();
				@writeCPPFLAGS();
				@writeLDFLAGS();
				@writeCXXFLAGS();
			},
			
			// VARIABLES
			method writeSourcesVariables {
				std::filewrite(@fh, "SOURCES = \\");
				foreach (local src, @proj.Sources())
					@writeLine(pathToString(@proj.getLocation().Concatenate(src)));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeObjectsVariables {
				std::filewrite(@fh, "OBJECTS = \\");
				foreach (local obj, objectsFromSources(@proj, @builddir))
					@writeLine(pathToString(obj));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeDependenciesVariables {
				std::filewrite(@fh, "DEPENDENCIES = \\");
				foreach (local dep, dependenciesFromSources(@proj, @builddir))
					@writeLine(pathToString(dep));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeVariables {
				@writeSourcesVariables();
				@writeObjectsVariables();
				@writeDependenciesVariables();
			},
			
			// TARGETS
			method writeTarget(target, deps, commands) {
				::util.assert_str( target );
				std::filewrite(@fh, target, ": ");
				foreach (local dep, deps)
					std::filewrite(@fh, " ", ::util.val(dep));
				foreach (local command, commands)
					std::filewrite(@fh, ::util.ENDL(), "	", ::util.val(command));
			},
			method writeAllTarget {
				local commands = std::list_new();
				appendCommandsFromSubprojects(@proj.Dependencies(), commands);
				@writeTarget(
						#all,
						[],
						commands
				);
			},
			method writeTargets {
				@writeAllTarget();
			},
			
			// before calling, call init()
			method writeAll(makefile_path_prefix) {
				::util.assert_str(makefile_path_prefix);
				local path = ::util.Path_castFromPath(makefile_path_prefix).Concatenate("Makefile");
				assert( ::util.Path_isaPath(path) );
				::util.println("Writing crap to ", path.deltaString());
				local fh = std::fileopen(path.deltaString(), "wt");
				if (fh) {
					@fh = fh;
					@writeFlags();
					@writeVariables();
					@writeTargets();
					std::fileclose(@fh);
				}
				else
					::util.println("Error, could not open file ", path.deltaString());
			},
			method writeSolutionMakefileTargets {
				local commands = std::list_new();
				appendCommandsFromSubprojects(@solution.Projects(), commands);
				@writeTarget(#all, [], commands);
			},
			method writeSolutionMakefile {
				local makefilepath = @basedirpath
						.Concatenate(@solution.getLocation())
						.Concatenate(@solution.getName() + "Makefile.mk");
				local makefile_fh = std::fileopen(makefilepath.deltaString(), "wt");
				if (makefile_fh) {
					::util.println("Writing solution makefile: ", makefilepath.deltaString());
					@fh = makefile_fh;
					@writeFlagspaceHeader();
					@writeSolutionMakefileTargets();
					std::fileclose(makefile_fh);
				}
				else
					::util.error().AddError("Could not open file ", makefilepath.deltaString());
			},
			method init(solution, basedirpath) {
				//
				@basedirpath = basedirpath;
				::util.Assert( ::util.Path_isaPath(basedirpath) );
				//
				::util.Assert( ::util.CSolution_isaCSolution(solution) );
				@solution = solution;
				//
				@writeSolutionMakefile();
			}
		];
	else
		makemani = makemani;

	// Per project manifestation
	// args -> (project, makefile_path_prefix, basedir)
	// ---
	//assert( ::util.CProject_isaCProject(project) );
	//assert( ::util.Path_isaPath(basedir) );
	//makemani.init(project, basedir);
	//makemani.writeAll(makefile_path_prefix);
	
	::util.Assert( ::util.Path_isaPath(basedirpath) );
	::util.Assert( ::util.CSolution_isaCSolution(solution) );
	makemani.init(solution, basedirpath);
}