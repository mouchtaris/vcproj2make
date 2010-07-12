util = std::vmload("util.dbc", "util");
std::vmrun(util);




//////////////////////////////
// *** MakefileManifestation
//     Produces Makefiles given a Project.
function MakefileManifestation(project, basedir__) {
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
		assert( ::util.isdeltastring(str) );
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
					assert( ::util.isdeltastring(prefix_const_or_f) or ::util.isdeltacallable(prefix_const_or_f) );
					assert( ::util.isdeltastring(prefix_const_or_f) or ::util.isdeltacallable(value_const_or_f));
					::util.Class_checkedStateInitialisation(
						newOptionInstance, validStateFieldsNames,
						[ {#Option_prefix: prefix_const_or_f}, {#Option_value: value_const_or_f} ]
					);
				},
				// prototype
				[
					method prefix {
						local result = ::util.val(::util.dobj_checked_get(self, #Option_prefix));
						assert( ::util.isdeltastring(result) or ::util.isdeltanil(result) );
						return result;
					},
					method value {
						local result = ::util.val(::util.dobj_checked_get(self, #Option_value));
						assert( ::util.isdeltastring(result) or ::util.isdeltanil(result) );
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
				assert( ::util.isdeltastring(valueString) );
				result.push_back(optionPair(prefix, valueString));
			}
		}
		return result;
	}
	function cppOptionsFromSubprojects(parent_project, subprojects) {
		local result = std::list_new();
		foreach (local subproj, subprojects)
			if (subproj.isLibrary())
				result.push_back(optionPair(
					// prefix getter functor
					[
						method @operator () {
							assert( @subproj.isLibrary() );
							return "-I";
						},
						@subproj: subproj
					],
					// value getter functor
					[
						method @operator () {
							local subproj = @subproj;
							local parentproj = @parentproj;
							assert( subproj.isLibrary() );
							return pathToString(
									parentproj.getLocation()
											.Concatenate(subproj.getLocation())
											.Concatenate(subproj.getAPIDirectory())
							);
						},
						@subproj   : subproj,
						@parentproj: parent_project
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
	if (std::isundefined(static makemani))
		makemani = [
			// Utility methods
			method writePre(ID) {
				if (local pres = @config[ID + "_pre"])
					foreach (local preflag, pres)
						std::filewrite(@fh, "\n        ", preflag, " \\");
				else
					std::error("No iterable given for Manifestation Configuration \"Makefile\" for option " + ID + "_pre");
			},
			method writePost(ID) {
				if (local posts = @config[ ID + "_post"])
					foreach (local postflag, posts)
						std::filewrite(@fh, "\n        ", postflag, " \\");
				else
					std::error("No iterable given for Manifestation Configuration \"Makefile\" for option " + ID + "_post");
			},
			// iterable contains Option instances
			method writePrefixedOptions(iterable) {
				foreach (local pair, iterable) {
					local prefix = pair.prefix();
					local value  = pair.value();
					if (prefix) {
						assert( ::util.isdeltastring(prefix) );
						assert( ::util.isdeltastring(value) );
						std::filewrite(@fh, "\n        ", prefix, "'", value, "' \\");
					}
				}
			},

			// Specific flag methods
			method writeSubprojectRelatedCPPFLAGS {
				local options = cppOptionsFromSubprojects(@proj, @proj.Subprojects());
				@writePrefixedOptions(options);
			},
			method writeCPPFLAGS {
				std::filewrite(@fh, "\nCPPFLAGS = \\");
				@writePre(#CPPFLAGS);
				@writeSubprojectRelatedCPPFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.PreprocessorDefinitions(), "-D", deltastringToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.IncludeDirectories()     , "-I", pathToString));
				@writePost(#CPPFLAGS);
				std::filewrite(@fh, "\n");
			},
			method writeSubprojectRelatedLDFLAGS {
				local subprojGeneratedOptions = ldOptionsFromSubprojects(@proj, @proj.Subprojects());
				@writePrefixedOptions(subprojGeneratedOptions);
			},
			method writeLDFLAGS {
				std::filewrite(@fh, "\nLDFLAGS = \\");
				@writePre(#LDFLAGS);
				@writeSubprojectRelatedLDFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.LibrariesPaths(), "-L", pathToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.Libraries()     , "-l", pathToString));
				@writePost(#LDFLAGS);
				std::filewrite(@fh, "\n");
			},
			method writeCXXFLAGS {
				std::filewrite(@fh, "\nCXXFLAGS = \\");
				@writePre(#CXXFLAGS);
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(["pedantic", "Wall", "ansi"], "-", deltastringToString));
				@writePost(#CXXFLAGS);
				std::filewrite(@fh, "\n");
			},
			method writeFlags {
				std::filewrite(@fh, "# Flagspace\nSHELL = /bin/bash\n");
				@writeCPPFLAGS();
				@writeLDFLAGS();
				@writeCXXFLAGS();
			},
			// before calling, call init()
			method writeAll {
				local pathstr = @basedir.Concatenate("Makefile");
				::util.println("Writing crap to ", pathstr.deltaString());
				local fh = std::fileopen(pathstr.deltaString(), "wt");
				if (fh) {
					@fh = fh;
					@writeFlags();
					std::filewrite(@fh, "\n\n\nall:\n	@echo LOL IT WORKED $(SHELL) $(CPPFLAGS) $(LDFLAGS) $(CXXFLAGS)\n\n");
					std::fileclose(@fh);
				}
				else
					::util.println("Error, could not open file ", pathstr);
			},
			method init(basedir, project) {
				assert( ::util.Path_isaPath(basedir) );
				@basedir = basedir;
				//
				assert( ::util.CProject_isaCProject(project) );
				@proj = project;
				//
				@config = @proj.getManifestationConfiguration(#Makefile);
				assert( ::util.isdeltaobject(@config) );
			}
		];
	else
		makemani = makemani;
	assert( ::util.CProject_isaCProject(project) );
	local basedir = ::util.Path_castFromPath(basedir__);
	makemani.init(basedir, project);
	makemani.writeAll();
}
















































// TODO think about:
// - is delegator-reference a reason to stay alive (not be collected)? Does this happen?
//   (if delegators are not collected, then maybe manual reference counting has to be
//    implemented -- and the global assignment operatator overloading should be user)
// Bug-reports
// - When a function returns nothing, the error message is confusing
//   Illegal use of '::Locatable()' as an object (type is ').
{
	local projlibisi = ::util.CProject().createInstance(::util.ProjectType().DynamicLibrary, "./libisi/Project", "Lib ISI  for the elderly");
	projlibisi.setAPIDirectory("../Include");
	projlibisi.setOutputDirectory("../lib/");
	projlibisi.setOutputName("isi");

	local projcalc = ::util.CProject().createInstance(::util.ProjectType().Executable, "./calc/Project", "A calculator for lulz");
	projcalc.setOutputDirectory("../bin/");
	projcalc.setOutputName("calc");


	local projfail = ::util.CProject().createInstance(::util.ProjectType().StaticLibrary, "./fail/Project", "A Failium");
	projfail.setAPIDirectory("../Include");
	projfail.setOutputDirectory("../lib/");
	projfail.setOutputName("fail");

	local proj = ::util.CProject().createInstance(::util.ProjectType().Executable, "/something/in/hell", "Loolis projec");
	proj.addSubproject(projlibisi);
	proj.addSubproject(projcalc);
	proj.addSubproject(projfail);
	//
	proj.addPreprocessorDefinition("Sakhs");
	proj.addPreprocessorDefinition("_LINUX_");
	proj.addPreprocessorDefinition("_DEBUG");
	proj.addPreprocessorDefinition("__NM_UNUSED(A)=A __attribute__((unused))");
	//
	proj.addLibrary("m");
	proj.addLibrary("pthread");
	proj.addLibrary("IsiLib");
	proj.addLibrary("DeltaVMCompilerAndStdLibContainerElementsComponent");
	//
	proj.addLibraryPath("/usr/bin");
	proj.addLibraryPath("../../..//Tools/Detla/Common/Lib/");
	proj.addLibraryPath("./");
	proj.addLibraryPath("../");
	proj.addLibraryPath("/");
	//
	proj.addIncludeDirectory("/jinka");
	proj.addIncludeDirectory("///////////");
	proj.addIncludeDirectory("@#@*@*@#@##@#@&%^");
	proj.addIncludeDirectory("../../../../../../../../../32423423423424234@#%*@*#%@%@%@?:\"<>,.|\\}{[]:;\\|`~!@#$%^&*()_+=-\"Hello guys. This is margert's nice inch tails mock.'''''\"\"''|\"");
	proj.addIncludeDirectory(".///////////");
	//
	proj.setManifestationConfiguration(#Makefile,
		[
			@CPPFLAGS_pre : [ "-custom_whatever=a_cpp_pre_flag" ],
			@CPPFLAGS_post: [ "-invalid_option_whatever=a_cpp_post_flag" ],
			@LDFLAGS_pre  : [ "-lolwhat=an_ld_flag_pre" ],
			@LDFLAGS_post : [ "-whatisthis=an_ld_flag_post" ],
			@CXXFLAGS_pre : [ "-flute=a_cxx_flag_pre" ],
			@CXXFLAGS_post: [ "-lute=a_cxx_flag_post" ]
		]
	);
	MakefileManifestation(proj, ".");
	//::util.println(proj);
	::util.println(::util.strgsub("../../../../../../../../../32423423423424234@#%*@*#%@%@%@?:\"<>,.|\\}{[]:;\\|`~!@#$%^&*()_+=-\"Hello guys. This is margert's nice inch tails mock.'''''\"\"''|\"", "#", "\\#"));
	::util.println(::util.strgsub("Sakhs", "#", "\\#"));
}

// Show all classes
{
	::util.println("----");
	local reg = ::util.dobj_get(::util.Class_classRegistry(), #list);
	foreach (local class, reg)
		::util.println(class);
	::util.println("----");
}

{
	::util.println("----");
	c = [method@{return #c;}];
	b = [method@{return #b;}];
	a=[];
	::util.println("A before delegation: ", a);
	std::delegate(a, b);
	::util.println("A delegated to b: ", a);
	std::undelegate(a, b);
	std::delegate(a, c);
	::util.println("A delegated to c: ", a);
	std::undelegate(a, c);
	std::delegate(a, b);
	std::delegate(a, c);
	::util.println("A delegated to b, c: ", a);
	std::undelegate(a, c);
	std::undelegate(a, b);
	std::delegate(a, c);
	std::delegate(a, b);
	::util.println("A delegated to c, b: ", a);
	::util.println("----");
}
