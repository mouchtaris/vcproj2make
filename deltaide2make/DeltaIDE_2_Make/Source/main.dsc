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
local u     = importVM("Util"            "/Lib/" "util"                                   ".dbc" , "util"                                            , onImportVMFail);
local rg    = importVM("ReportGenerator" "/Lib/" "ReportGenerator"                        ".dbc" , "ReportGenerator"                                 , onImportVMFail);
local sl_sd = importVM("SolutionLoader"  "/Lib/" "SolutionData"                           ".dbc" , "SolutionLoader/SolutionData"                     , onImportVMFail);
local sl_ve = importVM("SolutionLoader"  "/Lib/" "VariableEvaluator"                      ".dbc" , "SolutionLoader/VariableEvaluator"                , onImportVMFail);
local sl    = importVM("SolutionLoader"  "/Lib/" "SolutionLoader"                         ".dbc" , "SolutionLoader"                                  , onImportVMFail);
local pl_pr = importVM("ProjectLoader"   "/Lib/" "MicrosoftVisualStudioProjectFileReader" ".dbc" , "ProjectLoader/MicrosoftVisualStudioProjectReader", onImportVMFail);
local pl    = importVM("ProjectLoader"   "/Lib/" "ProjectLoader"                          ".dbc" , "ProjectLoader"                                   , onImportVMFail);

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
				local libpathcomponents = std::vmfuncaddr(std::vmthis(), libid + "_libpathcomponents");
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
			@solutionData = sl.SolutionLoader_LoadSolution(@solutionXML, @solutionDirectory, @solutionName);
			@log("Generating solution data core for storage..");
			local t0 = std::currenttime();
			sl_sd.SolutionDataFactory_DumpCore(@solutionData, local sdcore=[]);
			local t1 = std::currenttime();
			@log("Core generation needed: ", t1-t0, "msec");
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
		
		assert( @solutionData );
	},
	@log: u.bindfront(u.log, "Mainer")
];

function main0 (argc, argv, envp) {
	p.loadSolutionXML();
	p.loadSolutionData();

	// TMP test code
	local solutionData = p.solutionData;
	time("Writing solution data to rc...",[method@operator(){std::rcstore(@solutionData, "./solutionData.rc");},@solutionData:solutionData]);
	local log = u.bindfront(u.println, "[ProjectLoader]: ");
	local projectData = pl.ProjectLoader_loadProjectsFromSolutionData(solutionData, log);
	u.println(projectData);

	p.generateReport(solutionData);
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

function main (argc, argv, envp) {
	p.config = envp;
	p.init(argv);
	
	(function mains_dispatcher (...) {
		return std::vmfuncaddr(
				std::vmthis(),
				"main" + u.tostring(u.lastarg(arguments))
		)(|u.firstarg(arguments)|);
	})(arguments, 0, 1, 0, 1, 0, 1, 0, 2, 3, 4, 5, 3, 2, 3, 4, 5, 0, 6, 0, 7, 8, 0, 7, 0);
	
	p.cleanup();

	u.println("--done--");
}
