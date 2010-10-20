main = std::vmload("DeltaIDE_2_Make/Lib/main.dbc", "main");
std::vmrun(main);

envp = [
	// Platform sed executable (either full path or executable name, if it's in the path)
	@SED					: "/bin/sed",
	// Use only standard delta features, without any custom extensions
	// (custom library functions, etc). Valid values are only the ones
	// listed here as comments
	@strict_delta			: false,
	//@strict_delta			: "win32_debug",
	//@strict_delta			: "win32_release",
	//@strict_delta			: "linux_debug",
	//@strict_delta			: "linux_release",
	// Copy libraries from predefined paths, so as to have the latest versions
	@update_libs	      : true,
	// unixify sources
	@unixify		      : false,
	// lean classes
	@lean_classes	      : false,
	// Try to load Solution Data from cache
	@SolutionDataCached   : false,
	// If Solution Data are not loaded from the cache, generate the
	// solution data cache.
	@SolutionDataCache    : true,
	// re-create the solution XML file from the .sln file
	@RegenerateSolutionXML: not @self.SolutionDataCached,
	// An HTML Report: generate it or not? (takes time)
	@report			      : @self.SolutionDataCached,
	// Root directory of the Delta build used to run this script
	// (should contain DeltaExtraLibraries/, etc...)
	@DeltaBuildRoot	      : 	".",
	// The base directory against which the solution directory will be interpreted
	// (if it is a relative path). This one better be an absolute path.
	@solution_base_dir    : "/home/muhtaris/hg_repos/vcproj2make/deltaide2make",
	// dummy nothing
	{false:false},{false:nil}
];

args = [
	@progname:		"deltaide2make",
	@solution_name:	"IDE",
	@solution_path:
			//	"../../../deltux/deltaide/IDE/IDE.sln"
				"../vcproj2make_old/vcproj2make_testprojects/vcproj2make_testprojects.sln"
];

main.main(std::tablength(args), args, envp);
