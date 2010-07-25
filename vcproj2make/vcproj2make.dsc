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
		
		local prefixpath = builddir.Concatenate(proj.getLocation());
		local ext        = proj[transformationExtensionPrefix + #Extension]();
		local pathmapper = relocateAndReextensionise;
		pathmapper = ::util.bindfront(pathmapper, prefixpath);
		pathmapper = ::util.bindback(pathmapper, ext);
		return pathMapping(proj.Sources(), pathmapper);
	}
	function objectsFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Object);
	}
	function dependenciesFromSources(proj, builddir) {
		return transformSources(proj, builddir, #Dependency);
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
			method writeSubprojectRelatedCPPFLAGS {
				local options = cppOptionsFromSubprojects(@proj, @proj.Subprojects());
				@writePrefixedOptions(options);
			},
			method writeCPPFLAGS {
				std::filewrite(@fh, ::util.ENDL(), "CPPFLAGS = \\");
				@writePre(#CPPFLAGS);
				@writeSubprojectRelatedCPPFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.PreprocessorDefinitions(), "-D", deltastringToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.IncludeDirectories()     , "-I", pathToString));
				@writePost(#CPPFLAGS);
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeSubprojectRelatedLDFLAGS {
				local subprojGeneratedOptions = ldOptionsFromSubprojects(@proj, @proj.Subprojects());
				@writePrefixedOptions(subprojGeneratedOptions);
			},
			method writeLDFLAGS {
				std::filewrite(@fh, ::util.ENDL(), "LDFLAGS = \\");
				@writePre(#LDFLAGS);
				@writeSubprojectRelatedLDFLAGS();
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.LibrariesPaths(), "-L", pathToString));
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(@proj.Libraries()     , "-l", pathToString));
				@writePost(#LDFLAGS);
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeCXXFLAGS {
				std::filewrite(@fh, ::util.ENDL(), "CXXFLAGS = \\");
				@writePre(#CXXFLAGS);
				@writePrefixedOptions(optionsFromIterableConstantPrefixAndValueToStringFunctor(["pedantic", "Wall", "ansi"], "-", deltastringToString));
				@writePost(#CXXFLAGS);
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeFlags {
				std::filewrite(@fh, "# Flagspace", ::util.ENDL(), "SHELL = /bin/bash", ::util.ENDL());
				@writeCPPFLAGS();
				@writeLDFLAGS();
				@writeCXXFLAGS();
			},
			
			// VARIABLES
			method writeSourcesVariables {
				std::filewrite(@fh, ::util.ENDL(), "SOURCES = \\");
				foreach (local src, @proj.Sources())
					@writeLine(pathToString(@proj.getLocation().Concatenate(src)));
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeObjectsVariables {
				std::filewrite(@fh, ::util.ENDL(), "OBJECTS = \\");
				foreach (local obj, objectsFromSources(@proj, @builddir))
					@writeLine(pathToString(obj));
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeDependenciesVariables {
				std::filewrite(@fh, ::util.ENDL(), "DEPENDENCIES = \\");
				foreach (local dep, dependenciesFromSources(@proj, @builddir))
					@writeLine(pathToString(dep));
				std::filewrite(@fh, ::util.ENDL());
			},
			method writeVariables {
				@writeSourcesVariables();
				@writeObjectsVariables();
				@writeDependenciesVariables();
			},
			// before calling, call init()
			method writeAll {
				local pathstr = @basedir.Concatenate("Makefile");
				::util.println("Writing crap to ", pathstr.deltaString());
				local fh = std::fileopen(pathstr.deltaString(), "wt");
				if (fh) {
					@fh = fh;
					@writeFlags();
					@writeVariables();
					std::filewrite(@fh, ::util.ENDL(), ::util.ENDL(), ::util.ENDL(),
							"all:",::util.ENDL(),
							"	@echo LOL IT WORKED $(SHELL) $(CPPFLAGS) $(LDFLAGS) $(CXXFLAGS) "
							"$(SOURCES) $(OBJECTS) $(DEPENDENCIES)", ::util.ENDL(), ::util.ENDL());
					std::fileclose(@fh);
				}
				else
					::util.println("Error, could not open file ", pathstr);
			},
			method init(basedir, project) {
				assert( ::util.Path_isaPath(basedir) );
				@basedir = basedir;
				@builddir = basedir.Concatenate(::util.file_hidden("build"));
				assert( ::util.Path_isaPath(@builddir) );
				//
				assert( ::util.CProject_isaCProject(project) );
				@proj = project;
				//
				@config = @proj.getManifestationConfiguration(#Makefile);
				::util.assert_obj( @config );
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

	local proj = ::util.CProject().createInstance(::util.ProjectType().Executable, "/something/in/hell/Project", "Loolis projec");
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
	proj.addSource("../Src/something.cpp");
	proj.addSource("../Src/nothing.cpp");
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


{
	// Checked: string utility functions work correctly
	local s1 = "The fogx jumps the dog.";
	local s2 = "og";
	local s3 = "";
	local s4 = ".";
	local s5 = "z";
	local s1_len = ::util.strlength(s1);
	local rindex01 = ::util.strrindex(s1, s2);
	local rindex02 = ::util.strrindex(s1, s3);
	local rindex03 = ::util.strrindex(s1, s4);
	local rindex04 = ::util.strrindex(s1, s5);
	local insp = ::util.inspect;
	::util.println(
			"ruler            : ", "0123456789012345678901234567890123456"      , ::util.ENDL(),
			"s1               : ", insp(s1                                     ), ::util.ENDL(),
			"s2               : ", insp(s2                                     ), ::util.ENDL(),
			"s3               : ", insp(s3                                     ), ::util.ENDL(),
			"s4               : ", insp(s4                                     ), ::util.ENDL(),
			"s5               : ", insp(s5                                     ), ::util.ENDL(),
			"strlength(s1)    : ", insp(s1_len                                 ), ::util.ENDL(),
			"strrindex(s1, s2): ", insp(rindex01                               ), ::util.ENDL(),
			"strsubstr(...)   : ", insp(::util.strsubstr(s1, rindex01)         ), ::util.ENDL(),
			"strrindex(s1, s3): ", insp(rindex02                               ), ::util.ENDL(),
			"strsubstr(...)   : ", insp(::util.strsubstr(s1, rindex02)         ), ::util.ENDL(),
			"strrindex(s1, s4): ", insp(rindex03                               ), ::util.ENDL(),
			"strsubstr(...)   : ", insp(::util.strsubstr(s1, rindex03)         ), ::util.ENDL(),
			"strrindex(s1, s5): ", insp(rindex04                               ), ::util.ENDL(),
			"strsubstr(...)   : ", insp(::util.strsubstr(s1, rindex04)         ), ::util.ENDL(),
			"strsubstr(len_s1): ", insp(::util.strsubstr(s1, s1_len)           ), ::util.ENDL(),
			"strsubstr(len+1) : ", insp(::util.strsubstr(s1, s1_len + 1)       ), ::util.ENDL(),
			nil
	);
}
// Show all classes
{
	::util.println("----");
	local reg = ::util.dobj_get(::util.Class_classRegistry(), #list);
	foreach (local class, reg)
		::util.println(class);
	::util.println("----");
}


if (::util.False()) {
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

