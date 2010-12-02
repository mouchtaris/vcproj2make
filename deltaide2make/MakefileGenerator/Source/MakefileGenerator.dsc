util = u = std::libs::import("util");
assert( u );

//////////////////////////////
// *** MakefileManifestation
//    TODO
//    - add generation/inclusion of dependency files in makefiles
function MakefileManifestation(solutionDirectory, outputDirectory, solution) {
	function squote(str) {
		::util.assert_str( str );
		return "'" + str + "'";
	}
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
						local result = ::util.val(::util.dobj_checked_get(self, Option().stateFields(), #Option_prefix));
						::util.assert_or( ::util.isdeltastring(result) , ::util.isdeltanil(result) );
						return result;
					},
					method value {
						local result = ::util.val(::util.dobj_checked_get(self, Option().stateFields(), #Option_value));
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
		foreach (local dep, u.list_to_stdlist(dependencies))
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
							local depLocation = dep.getLocation();
							local depDirectory = depLocation.basename();
							local apiDirectory = dep.getAPIDirectory();
							local fullApiDirectory = basedir.Concatenate(depDirectory).Concatenate(apiDirectory);
							return pathToString(fullApiDirectory);
						},
						@dep       : dep     ,
						@basedir   : basedir
					]
				));
		return result;
	}
	function ldOptionsFromDependencies(basedir, dependencies) {
		local result = std::list_new();
		foreach (local dep, u.list_to_stdlist(dependencies))
			if (dep.isLibrary()) {
				local outputDirectory = dep.getOutputDirectory();
				// outputDirectory could already be an absolute path
				if (outputDirectory.IsRelative())
					local libLocation = basedir
							.Concatenate(dep.getLocation().basename())
							.Concatenate(dep.getOutputDirectory());
				else
					libLocation = outputDirectory;
				// Add a library path option (-L)
				result.push_back(
					optionPair(
						// prefix getter
						[
							method @operator () {
								::util.Assert( @dep.isLibrary() );
								return "-L";
							},
							@dep: dep
						],
						// value getter
						[
							method @operator () {
								local dep = @dep;
								::util.Assert( dep.isLibrary() );
								return pathToString(@libLocation);
							},
							@dep         : dep,
							@basedir     : basedir,
							@libLocation : libLocation
						]
					)
				);
				// Add a library linking option (-l)
				result.push_back(
					optionPair(
						// prefix getter
						[
							method @operator () {
								::util.Assert( @dep.isLibrary() );
								return "-l";
							},
							@dep: dep
						],
						// value getter
						[
							method @operator () {
								local dep = @dep;
								::util.Assert( dep.isLibrary() );
								return deltastringToString(dep.getOutputName());
							},
							@dep: dep
						]
					)
				);
				// Add the runtime library location information (--rpath)
				// for dynamic libraries
				if (dep.isDynamicLibrary()) {
					result.push_back(
						optionPair(
							lambda { "-Xlinker " },
							lambda { "--rpath"  }
						)
					);
					result.push_back(
						optionPair(
							lambda { "-Xlinker " },
							[
								method @operator () {
									return pathToString(@libLocation);
								},
								@libLocation : libLocation
							]
						)
					);
				}
			}
		return result;
	}
	function pathToPathWithoutParentAndSelfDirectories(path) {
		local pathstr = path.deltaString();
		pathstr = ::util.strgsub(pathstr, "../", "__/");
		pathstr = ::util.strgsub(pathstr, "./" , "_/" );
		return ::util.Path_castFromPath(pathstr, false);
	}
	function pathMapping(paths, pathmapf) {
		return ::util.list_to_stdlist(::util.iterable_map_to_list(paths,
			[
				method @operator ()(path) {
					assert( ::util.Path_isaPath(path) );
					local newpath = @pathmapf(path);
					assert( ::util.Path_isaPath(newpath) );
					return newpath;
				},
				@pathmapf: pathmapf
			]
		));
	}
	function relocateAndReextensionise(prefixpath, name, ext) {
		assert( ::util.Path_isaPath(prefixpath) );
		assert( ::util.Path_isaPath(name) );
		::util.assert_str(ext);
		return prefixpath.Concatenate(name.asWithExtension(ext));
	}
	function makeSourceTransformer(proj, builddir, transformTo) {
		// relocateAndReextensionise(prefixpath, name, ext)
		local prefixpath = builddir.Concatenate(proj.getName());
		local ext        = proj[transformTo + #Extension]();
		local sourceTransformer = relocateAndReextensionise;
		sourceTransformer = ::util.bindfront   (sourceTransformer, prefixpath                               );
		sourceTransformer = ::util.bindback    (sourceTransformer, ext                                      );
		sourceTransformer = ::util.fcomposition(sourceTransformer, pathToPathWithoutParentAndSelfDirectories);
		return sourceTransformer;
	}
	function transformSources(proj, builddir, transformationExtensionPrefix) {
		assert( ::util.CProject_isaCProject(proj) );
		assert( ::util.Path_isaPath(builddir) );

		return pathMapping(u.list_to_stdlist(proj.Sources()), makeSourceTransformer(proj, builddir, transformationExtensionPrefix));
	}
	function objectsFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Object);
	}
	function dependenciesFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Dependency);
	}
	
	function projectTargetNameForProject(project) {
		return "proj_" + project.getName();
	}
	function subbuildCommandForSubproject(project, makefileTarget_str) {
		return "( cd " + pathToString(::util.Path_fromPath(project.getLocation().basename(), false)) + " && ${MAKE} -f " +
					deltastringToString(project.getName() + "Makefile.mk") + " " +
					makefileTarget_str + ")";
	}
	function appendCommandsFromSubprojects(commands, projects, makefileTarget) {
		::util.assert_str( makefileTarget );
		local makefileTarget_str = deltastringToString(makefileTarget);
		foreach (local proj, projects)
			std::list_push_back(commands, subbuildCommandForSubproject(proj, makefileTarget_str));
	}

	function outputPathname(project) {
		function executableOutputTransformer(project) {
			local path = project.getOutputDirectory()
					.Concatenate(project.getOutputName());
			return path;
		}
		function LibraryOutputTransformer(project) {
			local path = project.getOutputDirectory()
					.Concatenate("lib" + project.getOutputName());
			return path;
		}
		function staticLibraryOutputTransformer(project) {
			local path = LibraryOutputTransformer(project)
					.Append(".a");
			return path;
		}
		function dynamicLibraryOutputTransformer(project) {
			local path = LibraryOutputTransformer(project)
					.Append(".so");
			return path;
		}
		if (std::isundefined( static outputTransformers ))
			outputTransformers = [
				@executable     :  executableOutputTransformer    ,
				@staticLibrary  :  staticLibraryOutputTransformer ,
				@dynamicLibrary :  dynamicLibraryOutputTransformer
			];
		else
			outputTransformers = outputTransformers;

		::util.Assert( ::util.CProject_isaCProject(project) );
		local result = nil;
		if (project.isExecutable())
			result = outputTransformers.executable(project);
		else if (project.isStaticLibrary())
			result = outputTransformers.staticLibrary(project);
		else if (project.isDynamicLibrary())
			result = outputTransformers.dynamicLibrary(project);
		else
			::util.assert_fail();
		return result;
	}
	
	const VAR_MKSHELL      = #SHELL       ;
	const VAR_MKCXX        = #CXX         ;
	const VAR_MKAR         = #AR          ;
	const VAR_MKCPPFLAGS   = #CPPFLAGS    ;
	const VAR_MKCXXFLAGS   = #CXXFLAGS    ;
	const VAR_MKLDFLAGS    = #LDFLAGS     ;
	const VAR_MKARFLAGS    = #ARFLAGS     ;
	//
	const TARGET_MKPHONY   = ".PHONY"     ;
	//
	const VAR_OBJECTS      = #OBJECTS     ;
	const VAR_SOURCES      = #SOURCES     ;
	const VAR_DEPENDENCIES = #DEPENDENCIES;
	//
	const TARGET_ALL       = #all         ;
	const TARGET_OBJECTS   = #objects     ;
	const TARGET_TARGET    = #target      ;
	const TARGET_CLEAN     = #clean       ;
	//
	local MK_PHONY_TARGETS = [ TARGET_ALL, TARGET_OBJECTS, TARGET_TARGET, TARGET_CLEAN ];
	function MKVAR(varname_or_f) {
		local varname = ::util.val(varname_or_f);
		::util.assert_str( varname );
		return "$(" + varname + ")";
	}
	if (std::isundefined(static makemani))
		makemani = [
			// --------------------------------------
			// Utility methods --------------------------------------
			// --------------------------------------
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
				::util.assert_str( ID );
				if (local pres = @config[ID + "_pre"])
					foreach (local preflag, pres)
						@writeLine(preflag);
				else
					std::error("No iterable given for Manifestation Configuration \"Makefile\" for option " + ID + "_pre");
			},
			method writePost(ID) {
				::util.assert_str( ID );
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
					if (not (::util.isdeltanil(prefix) or ::util.isdeltaundefined(prefix) )) {
						::util.assert_str( prefix );
						::util.assert_str( value );
						@writeLine(prefix, "'", value, "'");
					}
				}
			},

			// --------------------------------------
			// FLAGS --------------------------------------
			// --------------------------------------
			// Specific flag methods
			method writeFlagspaceHeader {
				std::filewrite(@fh, "# Flagspace", ::util.ENDL(), VAR_MKSHELL, " = /bin/bash", ::util.ENDL());
			},
			method writeDependencyRelatedCPPFLAGS {
				local dependenciesGeneratedOptions = cppOptionsFromDependencies(
														@basedir_ccat_solution_path,
														@proj.Dependencies()
													);
				@writePrefixedOptions(dependenciesGeneratedOptions);
			},
			method writeCPPFLAGS {
				std::filewrite(@fh, VAR_MKCPPFLAGS + " = \\");
				@writePre(VAR_MKCPPFLAGS);
				@writeDependencyRelatedCPPFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(u.list_to_stdlist(@proj.PreprocessorDefinitions()), "-D", deltastringToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(u.list_to_stdlist(@proj.IncludeDirectories()     ), "-I", pathToString));
				// Include own API dir in include paths
				if (@proj.isLibrary())
					@writePrefixedOptions([optionPair("-I", pathToString(@proj.getAPIDirectory()))]);
				@writePost(VAR_MKCPPFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeDependenyRelatedLDFLAGS {
				local dependenciesGeneratedOptions = ldOptionsFromDependencies(
						@basedir_ccat_solution_path,
						@proj.Dependencies());
				@writePrefixedOptions(dependenciesGeneratedOptions);
			},
			method writeLDFLAGS {
				std::filewrite(@fh, VAR_MKLDFLAGS + " = \\");
				@writePre(VAR_MKLDFLAGS);
				@writeDependenyRelatedLDFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(u.list_to_stdlist(@proj.LibrariesPaths()), "-L", pathToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(u.list_to_stdlist(@proj.Libraries()     ), "-l", deltastringToString));
				@writePost(VAR_MKLDFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeCXXFLAGS {
				std::filewrite(@fh, VAR_MKCXXFLAGS + " = \\");
				@writePre(VAR_MKCXXFLAGS);
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(["pedantic", "Wall", "ansi"], "-", deltastringToString));
				@writePost(VAR_MKCXXFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeARFLAGS {
				std::filewrite(@fh, VAR_MKARFLAGS + " = \\");
				@writePre(VAR_MKARFLAGS);
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(["crv"], "", deltastringToString));
				@writePost(VAR_MKARFLAGS);
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeFlags {
				@writeFlagspaceHeader();
				@writeCPPFLAGS();
				@writeLDFLAGS();
				@writeCXXFLAGS();
				@writeARFLAGS();
			},
			
			// --------------------------------------
			// VARIABLES --------------------------------------
			// --------------------------------------
			method writeSourcesVariables {
				std::filewrite(@fh, VAR_SOURCES, " = \\");
				foreach (local src, u.list_to_stdlist(@proj.Sources()))
					@writeLine(pathToString(src));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeObjectsVariables {
				std::filewrite(@fh, VAR_OBJECTS, " = \\");
				foreach (local obj, objectsFromSources(@proj, @builddir))
					@writeLine(pathToString(obj));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeDependenciesVariables {
				std::filewrite(@fh, VAR_DEPENDENCIES, " = \\");
				foreach (local dep, dependenciesFromSources(@proj, @builddir))
					@writeLine(pathToString(dep));
				std::filewrite(@fh, ::util.ENDL(), ::util.ENDL());
			},
			method writeVariables {
				@writeSourcesVariables();
				@writeObjectsVariables();
				@writeDependenciesVariables();
			},
			
			// --------------------------------------
			// TARGETS --------------------------------------
			// --------------------------------------
			method writeTarget(target, deps, commands) {
				::util.assert_str( target );
				std::filewrite(@fh, target, ": ");
				foreach (local dep, deps) {
					local val = ::util.val(dep);
					::util.assert_str( val );
					std::filewrite(@fh, " ", val);
				}
				foreach (local command, commands) {
					local val = ::util.val(command);
					std::filewrite(@fh, ::util.ENDL(), "	", val);
				}
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeDirectoryTarget(dir_path_str) {
				::util.assert_str( dir_path_str );
				@writeTarget(
					dir_path_str,
					[],
					[ "mkdir -p -v " + squote(dir_path_str) ]
				);
			},
			method writeAllTarget {
				local commands = std::list_new();
				@writeTarget(
						TARGET_ALL,
						[ TARGET_OBJECTS, TARGET_TARGET ],
						commands
				);
			},
			method writeObjectsTarget {
				if (std::isundefined(static deps))
					deps = [ MKVAR(VAR_OBJECTS) ];
				if (std::isundefined(static commands))
					commands = [];
				@writeTarget(
						TARGET_OBJECTS,
						deps,
						commands
				);
			},
			method writeTargetTarget {
				function ExecutableCommandsGenerator(project) {
					::util.Assert( ::util.CProject_isaCProject(project) );
					::util.Assert( project.isExecutable() );
					static prefix;
					static suffix;
					if (std::isundefined(static static_variables_initialised)) {
						static_variables_initialised = true;
						prefix = MKVAR(VAR_MKCXX) + " " + MKVAR(VAR_OBJECTS) + " -o";
						suffix = " " + MKVAR(VAR_MKCXXFLAGS) + " " + MKVAR(VAR_MKLDFLAGS);
					}
					local pathstr = pathToString(outputPathname(project));
					local result = prefix + pathstr + suffix;
					return [ result ];
				}
				function StaticLibraryCommandsGenerator(project) {
					::util.Assert( ::util.CProject_isaCProject(project) );
					::util.Assert( project.isStaticLibrary() );
					static prefix;
					static suffix;
					if (std::isundefined(static static_variables_initialised)) {
						static_variables_initialised = true;
						prefix = MKVAR(VAR_MKAR) + " " + MKVAR(VAR_MKARFLAGS) + " " ;
						suffix = " " + MKVAR(VAR_OBJECTS);
					}
					local pathstr = pathToString(outputPathname(project));
					local result = prefix + pathstr + suffix;
					return [ result ];
				}
				function DynamicLibraryCommandsGenerator(project) {
					::util.Assert( ::util.CProject_isaCProject(project) );
					::util.Assert( project.isDynamicLibrary() );
					static prefix;
					static suffix;
					if (std::isundefined(static static_variables_initialised)) {
						static_variables_initialised = true;
						prefix = MKVAR(VAR_MKCXX) + " " + MKVAR(VAR_MKCXXFLAGS) + " " + MKVAR(VAR_MKLDFLAGS) + " -shared -o" ;
						suffix = " " + MKVAR(VAR_OBJECTS) ;
					}
					local pathstr = pathToString(outputPathname(project));
					local result = prefix + pathstr + suffix;
					return [ result ];
				}
				//
				function DependenciesGeneratorForAll(basedir_ccat_solution_path, project, basename_path_str) {
					::util.Assert( ::util.CProject_isaCProject(project) );
					::util.Assert( ::util.Path_isaPath(basedir_ccat_solution_path) );
					local deps = std::list_new();
					std::list_push_back(deps, MKVAR(VAR_OBJECTS));
					std::list_push_back(deps, basename_path_str);
					// real dependencies are also the static libs
					foreach (local dep, ::util.list_to_stdlist(project.Dependencies()))
						if (dep.isStaticLibrary()) {
							local outputPathnamePath = outputPathname(dep);
							// it is possibe that output paths are absolute
							if (outputPathnamePath.IsRelative())
								std::list_push_back(deps, basedir_ccat_solution_path
										.Concatenate(dep.getLocation())
										.Concatenate(outputPathnamePath)
										.deltaString()
								);
							else
								std::list_push_back(deps, outputPathnamePath.deltaString());
						}
					return deps;
				}
				const ExecutableDependenciesGenerator     = DependenciesGeneratorForAll;
				const StaticLibraryDependenciesGenerator  = DependenciesGeneratorForAll;
				const DynamicLibraryDependenciesGenerator = DependenciesGeneratorForAll;
				::util.assert_clb( ExecutableCommandsGenerator );
				::util.assert_clb( StaticLibraryCommandsGenerator );
				::util.assert_clb( DynamicLibraryCommandsGenerator );
				local commandsGenerator = nil;
				local dependenciesGenerator = nil;
				local proj = @proj;
				if (proj.isExecutable()) {
					commandsGenerator = ExecutableCommandsGenerator;
					dependenciesGenerator = ExecutableDependenciesGenerator;
				}
				else if (proj.isStaticLibrary()) {
					commandsGenerator = StaticLibraryCommandsGenerator;
					dependenciesGenerator = StaticLibraryDependenciesGenerator;
				}
				else if (proj.isDynamicLibrary) {
					commandsGenerator = DynamicLibraryCommandsGenerator;
					dependenciesGenerator = DynamicLibraryDependenciesGenerator;
				}
				else
					::util.assert_fail();
				::util.assert_clb( commandsGenerator );
				local output_pathname     = outputPathname(proj);
				local output_pathname_str = pathToString(output_pathname);
				local output_basename_str = deltastringToString(output_pathname.basename());
				@writeTarget(
						TARGET_TARGET,
						[ output_pathname_str ],
						[]
				);
				@writeTarget(
					output_pathname_str,
					dependenciesGenerator(@basedir_ccat_solution_path, proj, output_basename_str),
					commandsGenerator(proj)
				);
				@writeDirectoryTarget(output_basename_str);
					
			},
			method writeCleanTarget {
				const objvarname = "haris";
				static deps, static commands;
				if (std::isundefined(static static_vars_initialised)) {
					static_vars_initialised = true;
					deps = [];
					objvarname_str = deltastringToString("\"$" + objvarname + "\"");
					commands = [ 
								"@for " + objvarname + " in " + MKVAR(VAR_OBJECTS) + " " +
								pathToString(outputPathname(@proj)) + " " + MKVAR(VAR_DEPENDENCIES) +
								" ; do if [ -e " + objvarname_str + " ] ; then rm -v " + objvarname_str + 
								" ; else printf 'File \"%s\" does not exist, not deleting\\n' " + 
								objvarname_str + " ; fi ; done" ];
				}
				@writeTarget(
					TARGET_CLEAN,
					deps,
					commands
				);
			},
			method writePhonyTarget {
				if (std::isundefined(static commands))
					commands = [];
				@writeTarget(
					TARGET_MKPHONY,
					@MK_PHONY_TARGETS,
					commands
				);
			},
			method writeTargets {
				@writeAllTarget();
				@writeObjectsTarget();
				@writeTargetTarget();
				@writeCleanTarget();
				@writePhonyTarget();
			},
			
			// --------------------------------------
			// RULES --------------------------------------
			// --------------------------------------
			method writeObjectsRules {
				local sourceTransformer = makeSourceTransformer(@proj, @builddir, #Object);
				foreach (local src, ::util.list_to_stdlist(@proj.Sources())) {
					local obj             = sourceTransformer(src);
					local objpath_str     = pathToString(obj);
					local objbasename_str = obj.basename();
					local srcpath_str     = pathToString(src);
					local build_command =
							MKVAR(VAR_MKCXX) + " " + MKVAR(VAR_MKCPPFLAGS) + " " + MKVAR(VAR_MKCXXFLAGS) +
							" -c -o" + squote(objpath_str) + " " + squote(srcpath_str);
					@writeTarget(
						objpath_str,
						[ srcpath_str, objbasename_str ],
						[ build_command ]
					);
					@appendDirectoryTarget(objbasename_str);
				}
			},
			method writeRules {
				@writeObjectsRules();
			},
			method writeDirectoriesTargets {
				foreach (local directory, @directoriesInNeedOfTargets)
					@writeDirectoryTarget(u.assert_str(directory));
				@resetDirectoriesTargets();
			},
			
			// utilities and buffers
			method appendDirectoryTarget (directory) {
				assert( u.isdeltastring(directory) );
				directoriesInNeedOfTargets = @directoriesInNeedOfTargets;
				local previousEntry = directoriesInNeedOfTargets[directory];
				if ( u.isdeltanil(previousEntry) )
					directoriesInNeedOfTargets[directory] = directory;
				else
					assert( u.strequal(previousEntry, directory) );
			},
			method resetDirectoriesTargets {
				u.dobj_clear(@directoriesInNeedOfTargets);
			},

			// high-level methods (for projects, solutions)
			method writeAll(makefile_path) {
				assert( ::util.Path_isaPath(makefile_path) );
				::util.println("Writing crap to ", makefile_path.deltaString());
				local fh = std::fileopen(makefile_path.deltaString(), "wt");
				if (fh) {
					@fh = fh;
					@writeFlags();
					@writeVariables();
					@writeTargets();
					@writeRules();
					@writeDirectoriesTargets();
					std::fileclose(@fh);
				}
				else
					::util.println("Error, could not open file ", makefile_path.deltaString());
			},
			method writeProjectMakefile(project) {
				local path = @outputRoot_ccat_solution_path
						.Concatenate(project.getLocation().basename())
						.Concatenate(::util.file_pathify(project.getName()) + "Makefile.mk")
				;
				@config = project.getManifestationConfiguration(#Makefile);
				@proj = project;
				@writeAll(path);
			},
			method writeProjectsMakefiles {
				foreach (local project, ::util.list_to_stdlist(@solution.Projects()))
					@writeProjectMakefile(project);
			},
			method writeSolutionMakefileTargets {
				local projects = @solution.Projects();
				local projects_stdlist = ::util.list_to_stdlist(projects);
				local projects_targets_names = ::util.iterable_map_to_list(projects_stdlist, projectTargetNameForProject);
				local projects_targets_names_stdlist = ::util.list_to_stdlist(projects_targets_names);
				local commands = std::list_new();
				// all: proj1 proj2 ...
				@writeTarget(TARGET_ALL, projects_targets_names_stdlist, commands);
				// projn: projk projl porjm ...
				foreach (local project, ::util.list_to_stdlist(projects))
					@writeTarget(
						projectTargetNameForProject(project),
						::util.list_to_stdlist(::util.iterable_map_to_list(::util.list_to_stdlist(project.Dependencies()), projectTargetNameForProject)),
						[ subbuildCommandForSubproject(project, TARGET_ALL) ]
					);
				
				// clean:
				appendCommandsFromSubprojects(commands, projects_stdlist, TARGET_CLEAN);
				//     also recursively delete the build directory
				std::list_push_back(commands, "@ if [ -e " + @builddir_str + " ] ; then rm -r -v " + @builddir_str +
						" ; else printf 'Build dir \"%s\" already missing\\n' \"" + @builddir_str + "\" ; fi");
				@writeTarget(TARGET_CLEAN, [], commands);

				std::list_clear(commands);
				local deps = projects_targets_names_stdlist;
				std::list_push_back(deps, TARGET_ALL);
				std::list_push_back(deps, TARGET_CLEAN);
				// .PHONY
				@writeTarget(
					TARGET_MKPHONY,
					deps,
					commands
				);	
			},
			// before calling, call init()
			method writeSolutionMakefile {
				local makefilepath = @outputRoot_ccat_solution_path
						.Concatenate(::util.file_pathify(@solution.getName()) + "Makefile.mk");
				local makefile_fh = std::fileopen(makefilepath.deltaString(), "wt");
				if (makefile_fh) {
					::util.println("Writing solution makefile: ", makefilepath.deltaString());
					@fh = makefile_fh;
					@writeFlagspaceHeader();
					@writeSolutionMakefileTargets();
					std::fileclose(makefile_fh);
					@fh = nil;
					@writeProjectsMakefiles();
				}
				else
					::util.error().AddError("Could not open file ", makefilepath.deltaString());
			},
			method init(solution, solutionDirectory) {
				::util.Assert( ::util.CSolution_isaCSolution(solution) );
				::util.Assert( ::util.Path_isaPath(solutionDirectory) );
				//
				local solutionBasename = u.Path_castFromPath(solution.getLocation().basename(), false);
				//
				@basedirpath = basedirpath;
				//
				@outputRoot_ccat_solution_path = @basedir_ccat_solution_path = solutionDirectory.Concatenate(solutionBasename);
				//
				@builddir = @basedir_ccat_solution_path.Concatenate(::util.file_hidden("build"));
				@builddir_str = pathToString(@builddir);
				//
				@solution = solution;
				//
				@directoriesInNeedOfTargets = [];
				//
				@writeSolutionMakefile();
			},
			@MK_PHONY_TARGETS: MK_PHONY_TARGETS
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
	
	::util.Assert( ::util.Path_isaPath(solutionDirectory) );
	::util.Assert( solutionDirectory.IsAbsolute() );
	::util.Assert( ::util.CSolution_isaCSolution(solution) );
	assert( solution.getLocation().IsRelative() );
	makemani.init(solution, solutionDirectory);
}



////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("MakefileGenerator", nil, nil);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////
