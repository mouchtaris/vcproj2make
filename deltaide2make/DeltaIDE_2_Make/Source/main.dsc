/////////////////////////////////////////////////////////////
// VM imports
// ----------------------------------------------------------
function importVM(path, id, onfail) {
	std::libs::registershared(id, path);
	assert( std::libs::isregisteredshared(id) );
	local result = std::libs::import(id);
	if (not result)
		onfail(path, id, "could not load vm");
	else if (not result.Initialise())
		onfail(path, id, "initialisation failed");
	return result;
}
function onImportVMFail(path, id, reason) {
	std::error("Could not import " + id + " from " + path + ". Reason: " + reason);
}
const SolutionDataCoreCache_filename = "SolutionDataCache";
local u     = importVM("Util"              "/Lib/" "util"                                   ".dbc" , "util"                                            , onImportVMFail);
local rg    = importVM("ReportGenerator"   "/Lib/" "ReportGenerator"                        ".dbc" , "ReportGenerator"                                 , onImportVMFail);
local sl_sd = importVM("SolutionLoader"    "/Lib/" "SolutionData"                           ".dbc" , "SolutionLoader/SolutionData"                     , onImportVMFail);
local sl_ve = importVM("SolutionLoader"    "/Lib/" "VariableEvaluator"                      ".dbc" , "SolutionLoader/VariableEvaluator"                , onImportVMFail);
local sl    = importVM("SolutionLoader"    "/Lib/" "SolutionLoader"                         ".dbc" , "SolutionLoader"                                  , onImportVMFail);
local pl_pr = importVM("ProjectLoader"     "/Lib/" "MicrosoftVisualStudioProjectFileReader" ".dbc" , "ProjectLoader/MicrosoftVisualStudioProjectReader", onImportVMFail);
local pl    = importVM("ProjectLoader"     "/Lib/" "ProjectLoader"                          ".dbc" , "ProjectLoader"                                   , onImportVMFail);
local mkgen = importVM("MakefileGenerator" "/Lib/" "MakefileGenerator"                      ".dbc" , "MakefileGenerator"                               , onImportVMFail);

const SolutionXMLpath = "Solution.xml";
const RootTagName     = "VisualStudioSolution";


function time (desc, action) {
	u.print(desc);
	local time0 = std::currenttime();
	action();
	local time1 = std::currenttime();
	u.println(" ", time1-time0, "msec");
}


p = [
	/////////////////////////////////////////////////////////////
	// Load libs
	// ----------------------------------------------------------
	method LoadLibs {
		// Copy libs first
		function copylibs (deltaRoot) {
			function win32debugSuffix (libid, configuration, basename) {
				local isdebug = configuration == "debug";
				local win32debugSuffix = u.ternary(isdebug, "D", "");
				return win32debugSuffix;
			}
			function libifyname(libid, configuration, basename) {
				local result = nil;
				local isdebug = configuration == "debug";
				if (u.iswin32())
					result = u.libifyname(basename + win32debugSuffix(libid, configuration, basename));
				else if (u.islinux())
					result = u.libifyname(u.ternary(isdebug, basename + "-linux", "DOES NOT EXIST"));
				else
					u.error().UnknownPlatform();
				return result;
			}
			function xml_libpathcomponents(root, configuration) {
				local result = nil;
				if (u.iswin32())
					result = [root, "Delta", "DeltaExtraLibraries", "XMLParser", "lib", configuration];
				else if (u.islinux())
					result = [root, "..", "..", "..", "deltux", "psp", "projects", "Tools", 
						"Delta", "DeltaExtraLibraries", "XMLParserPSP", "Project"];
				else
					u.error().UnknownPlatform();
				return result;
			}
			function vcsp_libpathcomponents(root, configuration) {
				local result = nil;
				if (u.iswin32())
					result = [root, "Delta", "DeltaExtraLibraries", "VCSolutionParser", "lib", configuration];
				else if (u.islinux())
					result = [ "..", "..", "..", "deltux", "psp", "projects", "Tools",
							"Delta", "DeltaExtraLibraries", "VCSolutionParser", "Project"];
				else
					u.error().UnknownPlatform();
				return result;
			}
			function makelibpath(libid, configuration, basename, root) {
				if (std::isundefined(static libpathcomponents_functions))
					libpathcomponents_functions = [
						{ "xml": xml_libpathcomponents },
						{ "vcsp": vcsp_libpathcomponents }
					];
				else
					libpathcomponents_functions = libpathcomponents_functions;
				local libpathcomponents = libpathcomponents_functions[libid];
				assert( u.isdeltacallable(libpathcomponents) );
				local result = u.file_pathconcatenate(|libpathcomponents(root, configuration)|) + libifyname(libid, configuration, basename);
				return result;
			}
			function makelibname (libid, configuration, basename) {
				local result = u.libifyname(basename + win32debugSuffix(libid, configuration, basename));
				return result;
			}
			// Libs basenames
			const xmllibbasename           = "XMLParser";
			const vcsplibbasename          = "VCSolutionParser";
			// Libs info
			libsinfo = [
				["release" , "xml" , xmllibbasename       ],
				["debug"   , "xml" , xmllibbasename       ],
				["release" , "vcsp", vcsplibbasename      ],
				["debug"   , "vcsp", vcsplibbasename      ]
			];
			foreach (local libinfo, libsinfo) {
				local configuration = libinfo[0];
				local libid         = libinfo[1];
				local libbasename   = libinfo[2];
				//
				local src           = makelibpath(libid, configuration, libbasename, deltaRoot);
				local dst           = makelibname(libid, configuration, libbasename);
				u.println("Copying " + src + " to " + dst);
				u.shellcopy(src, dst);
			}
		};
		if (@config.update_libs)
			copylibs(@config.DeltaBuildRoot);
		local libs_loaded_successfully = u.loadlibs();
		if (not libs_loaded_successfully)
			u.error().AddError("Could not load required libs");
		return libs_loaded_successfully;
	},
	method generateSolutionXML (solutionPath) {
		if (@config.RegenerateSolutionXML) {
			local shellcommandGenerator = (function(p){
				local result = nil;
				if (u.iswin32())
					result = p.generateSedCommandWin32;
				else  if (u.islinux())
					result = p.generateSedCommandLinux;
				else
					u.error().UnknownPlatform();
				return result;
			})(self);
			
			if (local fh = std::fileopen(SolutionXMLpath, "wt")) {
				std::filewrite(fh, "<", RootTagName, ">",
						u.strmul(u.ENDL(), 5));
				std::fileclose(fh);
				//
				@shellverb(shellcommandGenerator(solutionPath, SolutionXMLpath));
				//
				if (fh = std::fileopen(SolutionXMLpath, "at")) {
					std::filewrite(fh, u.strmul(u.ENDL(), 5), 
							"</", RootTagName, ">", u.ENDL());
					std::fileclose(fh);
				}
				else
					u.error().AddError("Could not (re)open file ", SolutionXMLpath,
							" for appending text");
			}
			else
				u.error().AddError("Could not open solution XML file for writing (",
						SolutionXMLpath, ")");
		}
	},
	method loadSolutionXML {
		local data = u.xmlload(SolutionXMLpath);
		if (not data)
			u.error().AddError(u.xmlloaderror());
		local fout = std::fileopen("./DeltaIDE_2_Make/Source/SolutionXMLCache.dsc", "wt");
		assert(fout);
		method append (...) {
			u.foreacharg(arguments, [
				method @operator () (arg) {
					std::filewrite(@fout, arg);
					return true;
				},
				@fout: @fout
			]);
		}
		append.self.fout = fout;
		op = [ method @operator () {
			u.obj_dump_delta(
					@data,
					@append,
					"SolutionXML",
					"function getSolutionXML { ", "return SolutionXML; } "
			);
		}, @data: data, @append: append];
		//time("Writing Solution xml to cache file...", op);
		std::fileclose(fout);
		return @solutionXML = data;
	},
	@bashescape: function bashescape (str) {
		function squote (str) {
			return "'" + str + "'";
		}
		return squote(u.strgsub(str, "'", "'\\''"));
	},
	method generateSedCommandLinux (inputPath, outputPath) {
		return @config.SED + " --regexp-extended --file " + @bashescape("vcsol2xml.sed") +
				" " + @bashescape(inputPath) + " 1>> " + @bashescape(outputPath);
	},
	@dosesc: function dosesc (str) { return "\"" + str + "\""; },
	method generateSedCommandWin32 (inputPath, outputPath) {
		return @config.SED + " --regexp-extended --file " +
				@dosesc("vcsol2xml.sed") + " --binary " +
				@dosesc(inputPath) + " >> " + @dosesc(outputPath);
	},
	method unixify (inputPath, outputPath) {
		const tmppath = "unixification_tmp";
		assert( inputPath != tmppath );
		assert( outputPath != tmppath );
		local sedcommands = nil;
		if (u.iswin32())
			sedcommands = [
				(@config).SED + " --regexp-extended --binary --expression \"s/\x0d//g\" " +
					@dosesc(inputPath) + " > " + @dosesc(tmppath),
				"move " + @dosesc(tmppath) + " " + @dosesc(outputPath)
			];
		else if (u.islinux())
			sedcommands = [
				(@config).SED + " --regexp-extended --expression \"s/\x0d//g\" " +
					@bashescape(inputPath) + " 1> " + @bashescape(tmppath),
				"mv " + @bashescape(tmppath) + " " + @bashescape(outputPath)
			];
		else
			u.error().UnknownPlatform();

		foreach (local command , sedcommands)
			@shellverb(command);
	},
	method unixifySources {
		if (@config.unixify)
			foreach (local src, [
					"DeltaIDE_2_Make/Source/main.dsc",
					"DeltaIDE_2_Make/Source/main_win.dsc",
					"DeltaIDE_2_Make/Source/main_linux.dsc",
					"SolutionLoader/Source/SolutionData.dsc",
					"SolutionLoader/Source/SolutionLoader.dsc",
					"SolutionLoader/Source/VariableEvaluator.dsc",
					"ReportGenerator/Source/ReportGenerator.dsc",
					"ProjectLoader/Source/ProjectLoader.dsc",
					"ProjectLoader/Source/MicrosoftvisualStudioProjectFileReader.dsc",
					"Util/Source/util.dsc"
			])
				@unixify(src, src);
	},
	method shellverb (comm) {
		u.println("Shell: ", comm);
		return u.shell(comm);
	},
	method configure {
		// FIRST (!!) set any manual platform configuration that
		// might be requested.
		if ( local config = @config.strict_delta )
			u.setManualConfiguration(config);
		
		// Set lean classes, if so desired.
		if ( @config.lean_classes )
			u.becomeLean();
			
		// enable or disable the report generator
		if ( @config.report )
			rg.ReportGenerator_respectReportGenerationRequests();
		else
			rg.ReportGenerator_ignoreReportGenerationRequests();
	},
	method generateReport (solutionData) {
		const SolutionReportPath = "SolutionReport.xhtml";
		rg.ReportGenerator_generateReport(
				SolutionReportPath,
				u.log,
				solutionData.ConfigurationManager,
				solutionData.ProjectEntryHolder);
	},
	method init (argv) {
		(local p = self).unixifySources();
		p.configure();
		p.LoadLibs();
		p.generateSolutionXML(local solutionPath = argv.solution_path);
		@solutionDirectory = argv.solution_path;
		@solutionName      = argv.solution_name;
	},
	method cleanup {
	},
	method loadSolutionData {
		const SolutionDataCoreCache_funcname = #SolutionDataCoreCache;
		const SolutionDataCoreCache_classMapperAccessorFuncname = #ClassMapper;
		local SolutionBaseDir = @config.solution_base_dir;
		local cache_hit = false;
		if (@config.SolutionDataCached) {
			@log("Looking for cached solution data...");
			local op = [
				method @operator () () {
					@result = importVM(
							"SolutionLoader/Lib/" + SolutionDataCoreCache_filename + ".dbc",
							"SolutionLoader/SolutionDataCache",
							onImportVMFail);
				},
				@result: false
			];
			time("loading vm with cached data", op);
			local sl_sdch = op.result;
			if (sl_sdch.Initialise()) {
				local cache_func       = sl_sdch[SolutionDataCoreCache_funcname];
				local classMapper_func = sl_sdch[SolutionDataCoreCache_classMapperAccessorFuncname];
				if (cache_func) {
					local op = [
						method @operator () {
							@cache       = @cache_func();
							@classMapper = @classMapperFunc();
						},
						@cache_func: cache_func,
						@classMapperFunc: classMapper_func,
						@cache: false,
						@classMapper: false
					];
					time("acquiring cached data from vm", op);
					local cache       = op.cache;
					local classMapper = op.classMapper;
					//
					op.() = u.methodinstalled(op, method { @sl_sdch.CleanUp(); });
					op.sl_sdch = sl_sdch;
					time("Cleaning Up cache-data vm", op);
					//
					op.() = [
						method @operator () { u.obj_load_delta(@core, @classMapper); },
						@core: cache,
						@classMapper: classMapper
					];
					time("Relinking loaded core", op);
					//
					op = [
						method @operator () {
							@sd = sl_sd.SolutionDataFactory_CreateFromCore(@cache);
						},
						@cache: cache,
						@sd: false
					];
					time("recreating Solution data from cache", op);
					local solutionData = op.sd;
					if (solutionData) {
						cache_hit = true;
						@solutionData = solutionData;
						@log("SolutionData cache hit");
					}
				}
			}
		}
		
		if ( not cache_hit ) {
			@log("Solution data not cached, generating from files...");
			@solutionData = sl.SolutionLoader_LoadSolution(@solutionXML, SolutionBaseDir, @solutionDirectory, @solutionName);
			@log("Generating solution data core for storage..");
			local t0 = std::currenttime();
			sl_sd.SolutionDataFactory_DumpCore(@solutionData, local sdcore=[]);
			local t1 = std::currenttime();
			@log("Core generation needed: ", t1-t0, "msec");
			if (@config.SolutionDataCache) {
				@log("Writing core as a delta source file...");
				t0 = std::currenttime();
				const sdcorecache_varname = "p__sdcore";
				u.obj_dump_delta(
						sdcore,
						(local fileappender =
								u.func_FileAppender(
										"./SolutionLoader/Source/" +
												SolutionDataCoreCache_filename + ".dsc"
								).init()
						).append,
						sdcorecache_varname,
						"function " + SolutionDataCoreCache_funcname +
								" { " + u.ENDL(),
						u.ENDL() + " return local " + sdcorecache_varname + ";" + u.ENDL() + "}");
				fileappender.cleanup();
				t1 = std::currenttime();
				@log("Writing cache to delta source needed: ", t1 - t0, "msec");
			}
		}
		
		assert( @solutionData );
	},
	@log: u.bindfront(u.log, "Mainer"),
	method loadProjectData {
		local log = u.bindfront(@log, "[ProjectLoader]: ");
		local op = [
			method @operator () {
				@projectData = pl.ProjectLoader_loadProjectsFromSolutionData(@solutionData, @log);
			},
			@solutionData: @solutionData,
			@log: log,
			@projectData: false
		];
		@log("Loading projects...");
		time("", op);
		@projectData = local projectData = op.projectData;
	},
	method printObjectStatistics {
		local instanceCounters = u.Object_getInstanceCounters();
		u.Iterable_foreach(u.Iterable_fromDObj(instanceCounters), local ObjPairPrinter = [
			method @operator () (key, val) {
				u.println("- ", key, ": ", val);
				@total += val;
				return true; // keep iterating
			},
			@total: 0
		]);
		u.println("Total: ", ObjPairPrinter.total);
	}
];

function main0 (argc, argv, envp) {
	p.loadSolutionXML();
	p.loadSolutionData();
	p.loadProjectData();

	// TMP test code
	// "/Users/TURBO_X/Documents/uni/UOC/CSD/metaterrestrial/saviwork/vcproj2make/deltaide2make"
	local solutionData = p.solutionData;
	//time("Writing solution data to rc...",[method@operator(){std::rcstore(@solutionData, "./solutionData.rc");},@solutionData:solutionData]);
	local projectData = p.projectData;
	// cheatingly generate makefiles only for the Debug|Win32 configuration
	const DebugWin32Configuration = "Debug|Win32";
	{
		local key = DebugWin32Configuration;
		local val = projectData[key];
		p.log("Generating makefiles for configuration ", key);
		mkgen.MakefileManifestation(
				u.Path_castFromPath(
					//	"C:\\Users\\TURBO_X\\Documents\\uni\\UOC\\CSD\\metaterrestrial\\saviwork\\vcproj2make\\deltaide2make"
					//	"./"
						solutionData.SolutionBaseDirectory
						, false
				),
				val
		);
	}

	p.generateReport(solutionData);
	p.printObjectStatistics();
}

function main1 {
	local l1 = u.list_new();
	u.list_push_back(l1, l1);
	local a = [ 
		@self,
		l1,
		l1,
		@self[0],
		@self[2],
		[//a
			[ {false:local tooEarly = @self}, {false:nil},
				[//c
					[//d
						// how to ref b??
						tooEarly,
						l1
					]
				]
			]
		]
	];
	u.list_push_back(l1, a[5]            );
	u.list_push_back(l1, a[5][0]         );
	u.list_push_back(l1, a[5][0][0]      );
	u.list_push_back(l1, a[5][0][0][0]   );
	u.list_push_back(l1, a[5][0][0][0][0]);
	u.list_push_back(l1, l1);
	a[1] = l1;

	// Do the ultimate test
	const test_file_path = "./SolutionLoader/Source/SolutionDataCache.dsc";
	local strappender = u.func_StringAppender().init();
	u.obj_dump_delta( a, strappender.append, "boolis",
			u.ENDL() + ::u.ENDL() + "function Boolis {", " return boolis; }");
	local bytecode_outbuf = std::vmcompstringtooutputbuffer(
				local boolis = strappender.deltastring(), u.println, false);
	std::strsavetofile( boolis, test_file_path );
	local bytecode_inbuf = std::inputbuffer_new(bytecode_outbuf);
	std::libs::registershared("Bob", bytecode_inbuf);
	local Bob = std::libs::import("Bob");
	assert( Bob );
	local Bob_initialised = Bob.Initialise();
	assert( Bob_initialised );
	local a_new = Bob.Boolis();
	Bob.CleanUp();
	std::libs::unimport(Bob);
	local strappender2 = u.func_StringAppender().init();
	u.obj_dump_delta( a_new, strappender2.append, "coolis", "function Coolis {", " return coolis; }");
	local coolis = strappender2.deltastring();
	u.println( coolis );
}

function main2 { // Issue 001
	std::vmload("No path", "Non-existant VM");
	foreach (local dummy_table_iteration, [1,2,3])
		std::print(dummy_table_iteration);
}

function main3 { // Issue 002
	const p__Object__Object_id_attribute_name = "$_ObjectID";
	local o = [];
	std::tabnewattribute(o, p__Object__Object_id_attribute_name,
		function Object_setObjectID { std::error("Setting an object ID is not allowed"); },
		// PROBLEM HERE ---> doing a std::tabget() for an attribute
		std::tabmethodonme(o, method Object_getObjectID { return std::tabget(self, p__Object__Object_id_attribute_name); })
	);
	std::tabsetattribute(o, p__Object__Object_id_attribute_name, 34);
	std::print(o."$_ObjectID");
}


function main4 { // Issue 3
	local state = [ @val: 8 ];
	local proto = [ 
		@Val {
			@set method (val) { self.val = val; }
			@get method { return self.val; }
		}
	];
	std::delegate(state, proto);
	std::print(state.Val);
}


function main5 { // Issue 4
	local ob = std::vmcompstringtooutputbuffer("std::print(\"Hello\\n\");", std::error, false);
}

function main6 {
	u.println("Hello");
	local r = u.fncomposition(
		function f6 (n) { local r = n + 0; u.println("f6 makes ", n, " to ", r); return r; } ,
		function f5 (n) { local r = n + 1; u.println("f5 makes ", n, " to ", r); return r; } ,
		function f4 (n) { local r = n + 9; u.println("f4 makes ", n, " to ", r); return r; } ,
		function f3 (n) { local r = n + 8; u.println("f3 makes ", n, " to ", r); return r; } ,
		function f2 (n) { local r = n + 5; u.println("f2 makes ", n, " to ", r); return r; } ,
		function f1 (n) { local r = n + 3; u.println("f1 makes ", n, " to ", r); return r; }
	)(15);
	u.println("Total result: ", r);
}

function main7 {
	u.println(pl_pr.p_xpath);
	xml = [];
	xml.Grandpa = [];
	xml.Grandpa.Dad = [];
	xml.Grandpa.Dad.Child = ["Hello mommy"];
	u.println(xml);
	u.println(pl_pr.p_xpath(xml, #Grandpa, #Dad, #Child));
}

function main8 {
	(function (...) {
		local iterable = u.Iterable_fromArguments(u.argspopback(u.argspopfront(arguments,1),1));
		u.Iterable_foreach(iterable, u.successifier(u.argumentSelector(u.println,1)));
	})(#MUSTNOTBESHOWN, #a, #b, #c, #d, #e,#f, [#g], [#h], [#i], #j , #k , #l, #m, #n , #o, #MUSTNOTBESHOWN);
}

function main9 {
//<?xml version=\"1.0\" encoding=\"windows-1253\"?>
	const str = "
<VisualStudioProject
	ProjectType=\"Visual C++\"
	Version=\"9,00\"
	Name=\"isiapp_VS\"
	ProjectGUID=\"{F6459465-11D4-4CFD-99B9-5D8BDC5B598C}\"
	RootNamespace=\"isiapp_VS\"
	Keyword=\"Win32Proj\"
	TargetFrameworkVersion=\"196613\"
	>
	<Platforms>
		<Platform
			Name=\"Win32\"
		/>
	</Platforms>
	<ToolFiles>
	</ToolFiles>
	<Configurations>
		<Configuration
			Name=\"Debug|Win32\"
			OutputDirectory=\"$(SolutionDir)$(ConfigurationName)\"
			IntermediateDirectory=\"$(ConfigurationName)\"
			ConfigurationType=\"1\"
			InheritedPropertySheets=\"..\..\..\commonPropertiesSheet.vsprops\"
			CharacterSet=\"1\"
			>
			<Tool
				Name=\"VCPreBuildEventTool\"
			/>
			<Tool
				Name=\"VCCustomBuildTool\"
			/>
			<Tool
				Name=\"VCXMLDataGeneratorTool\"
			/>
			<Tool
				Name=\"VCWebServiceProxyGeneratorTool\"
			/>
			<Tool
				Name=\"VCMIDLTool\"
			/>
			<Tool
				Name=\"VCCLCompilerTool\"
				Optimization=\"0\"
				PreprocessorDefinitions=\"ISIAPP_VERSION=\&quot;Mironeus_Miraculum_Malefocarus_334.22212\&quot;;_DEBUG;WIN32;_CONSOLE;ISIDLL_VS_IMPORTS\"
				MinimalRebuild=\"true\"
				BasicRuntimeChecks=\"3\"
				RuntimeLibrary=\"3\"
				UsePrecompiledHeader=\"0\"
				WarningLevel=\"4\"
				DebugInformationFormat=\"4\"
			/>
			<Tool
				Name=\"VCManagedResourceCompilerTool\"
			/>
			<Tool
				Name=\"VCResourceCompilerTool\"
			/>
			<Tool
				Name=\"VCPreLinkEventTool\"
			/>
			<Tool
				Name=\"VCLinkerTool\"
				LinkIncremental=\"2\"
				GenerateDebugInformation=\"true\"
				SubSystem=\"1\"
				TargetMachine=\"1\"
			/>
			<Tool
				Name=\"VCALinkTool\"
			/>
			<Tool
				Name=\"VCManifestTool\"
			/>
			<Tool
				Name=\"VCXDCMakeTool\"
			/>
			<Tool
				Name=\"VCBscMakeTool\"
			/>
			<Tool
				Name=\"VCFxCopTool\"
			/>
			<Tool
				Name=\"VCAppVerifierTool\"
			/>
			<Tool
				Name=\"VCPostBuildEventTool\"
			/>
		</Configuration>
		<Configuration
			Name=\"Release|Win32\"
			OutputDirectory=\"$(SolutionDir)$(ConfigurationName)\"
			IntermediateDirectory=\"$(ConfigurationName)\"
			ConfigurationType=\"1\"
			CharacterSet=\"1\"
			WholeProgramOptimization=\"1\"
			>
			<Tool
				Name=\"VCPreBuildEventTool\"
			/>
			<Tool
				Name=\"VCCustomBuildTool\"
			/>
			<Tool
				Name=\"VCXMLDataGeneratorTool\"
			/>
			<Tool
				Name=\"VCWebServiceProxyGeneratorTool\"
			/>
			<Tool
				Name=\"VCMIDLTool\"
			/>
			<Tool
				Name=\"VCCLCompilerTool\"
				Optimization=\"2\"
				EnableIntrinsicFunctions=\"true\"
				PreprocessorDefinitions=\"ISIAPP_VERSION=\&quot;Mironeus_Miraculum_Malefocarus_334.22212\&quot;;WIN32;NDEBUG;_CONSOLE;ISIDLL_VS_IMPORTS\"
				RuntimeLibrary=\"2\"
				EnableFunctionLevelLinking=\"true\"
				UsePrecompiledHeader=\"0\"
				WarningLevel=\"3\"
				DebugInformationFormat=\"3\"
			/>
			<Tool
				Name=\"VCManagedResourceCompilerTool\"
			/>
			<Tool
				Name=\"VCResourceCompilerTool\"
			/>
			<Tool
				Name=\"VCPreLinkEventTool\"
			/>
			<Tool
				Name=\"VCLinkerTool\"
				LinkIncremental=\"1\"
				GenerateDebugInformation=\"true\"
				SubSystem=\"1\"
				OptimizeReferences=\"2\"
				EnableCOMDATFolding=\"2\"
				TargetMachine=\"1\"
			/>
			<Tool
				Name=\"VCALinkTool\"
			/>
			<Tool
				Name=\"VCManifestTool\"
			/>
			<Tool
				Name=\"VCXDCMakeTool\"
			/>
			<Tool
				Name=\"VCBscMakeTool\"
			/>
			<Tool
				Name=\"VCFxCopTool\"
			/>
			<Tool
				Name=\"VCAppVerifierTool\"
			/>
			<Tool
				Name=\"VCPostBuildEventTool\"
			/>
		</Configuration>
	</Configurations>
	<References>
		<ProjectReference
			ReferencedProjectIdentifier=\"{E67531FD-67A7-4A61-A098-945EAA03DC89}\"
			RelativePathToProject=\".\isidll\Project\isidll_VS\isidll_VS.vcproj\"
		/>
		<ProjectReference
			ReferencedProjectIdentifier=\"{2BC9A5B4-DE5D-4855-ACB7-A6835190C0D7}\"
			RelativePathToProject=\".\isistatic\Project\isistatic_VS\isistatic_VS.vcproj\"
		/>
	</References>
	<Files>
		<Filter
			Name=\"Source Files\"
			Filter=\"cpp;c;cc;cxx;def;odl;idl;hpj;bat;asm;asmx\"
			UniqueIdentifier=\"{4FC737F1-C7A5-4376-A066-2A32D752A2FF}\"
			>
			<File
				RelativePath=\"..\..\Source\main.cpp\"
				>
			</File>
		</Filter>
		<Filter
			Name=\"Header Files\"
			Filter=\"h;hpp;hxx;hm;inl;inc;xsd\"
			UniqueIdentifier=\"{93995380-89BD-4b04-88EB-625FBE52EBFB}\"
			>
		</Filter>
		<Filter
			Name=\"Resource Files\"
			Filter=\"rc;ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe;resx;tiff;tif;png;wav\"
			UniqueIdentifier=\"{67DA6AB6-F800-4c08-8B7A-83BB121AAD01}\"
			>
		</Filter>
	</Files>
	<Globals>
	</Globals>
</VisualStudioProject>
";
	local xml = #xmlparse(str);
	std::print(xml, "\n", #xmlloadgeterror());
}

function main10 (argc, argv, envp) {
	foreach (local vm_file_pair, [
		[u, "utilFunctionInstaller"],
		[sl_sd, "solutionDataFunctionInstaller"],
		[sl, "solutionLoaderFunctionInstaller"]
	]) {
		local vm = vm_file_pair[0];
		local filename = vm_file_pair[1];
		u.println("Writing functions to ./", filename, ".dsc ...");
		u.produceVMFunctionInstaller(vm,
			u.bindfront(std::filewrite, local fh = std::fileopen("./" + filename + ".dsc", "wt"))
		);
		std::fileclose(fh);
	}
}

function main11 (argc, argv, envp) {
	u.println(u.xmlstore);
	u.println("Writing XML with xmlstore()");
	u.xmlstore([
				{"$Name": "SuperXMLRoot"},
				// This gets printed as an invalid key
				{"$Attributes": [
						{ "attr1": "v1" },
						{ "attr2": "v2" }
					]},
				// This gets printed as an invalid key
				{"$CharData": "Abla blab alb alba blab albabl "},
				{"Choild1": "Atrtr"},
				{"Choild2": [
						// This gets printed as three attributes, all named "Choild2-1"
						{"Choild2-1": ["one", "two", "three"]}
					]},
				{"Choild3": []}, // Wishlist: empty elements could close right away, ie <Choild3 />
				{"Choild4": []}
			], "./xmlstore_tost.xml");
	u.println("Done writing");
}


function main (argc, argv, envp) {
	p.config = envp;
	p.init(argv);

	(function mains_dispatcher (...) {
		return std::vmfuncaddr(
				std::vmthis(),
				"main" + u.tostring(u.lastarg(arguments))
		)(|u.firstarg(arguments)|);
	})(arguments, 0, 1, 0, 1, 0, 1, 0, 2, 3, 4, 5, 3, 2, 3, 4, 5, 0, 6, 0, 7, 8, 0, 7, 0, 9, 0, 10, 0, 11, 0);
	
	p.cleanup();

	u.println("--done--");
}
