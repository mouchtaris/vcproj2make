util = std::vmload("util.dbc", "util");
std::vmrun(util);

vc2mk = std::vmload("vcproj2make.dbc", "vc2mk");
std::vmrun(vc2mk);



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
	::vc2mk.MakefileManifestation(proj);
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
