/////////////////////////////////////////////////////////////
// VM imports
// ----------------------------------------------------------
function importVM(path, id) {
	if (not (local vm = std::vmload(path, id)))
		std::error("Could not import " + id + " from " + path);
	else
		std::vmrun(vm);
	return vm;
}
local u  = importVM("Util/Lib/util.dbc", "util");
local rg = importVM("ReportGenerator/Lib/ReportGenerator.dbc", "ReportGenerator");
local sl_sd = importVM("SolutionLoader/Lib/SolutionData.dbc", "SolutionLoader/SolutionData");
local sl = importVM("SolutionLoader/Lib/SolutionLoader.dbc", "SolutionLoader");


const SolutionXMLpath = "Solution.xml";
const RootTagName     = "VisualStudioSolution";
		
p = [
	/////////////////////////////////////////////////////////////
	// Load libs
	// ----------------------------------------------------------
	method LoadLibs {
		// Copy libs first
		function copylibs {
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
			function xml_libpathcomponents(configuration) {
				local result = nil;
				if (u.iswin32())
					result = ["..", "..", "..", "..", "thesis_new", "deltaide", "Tools", 
							"Delta", "DeltaExtraLibraries", "XMLParser", "lib", configuration];
				else if (u.islinux())
					result = ["..", "..", "..", "deltux", "psp", "projects", "Tools", 
						"Delta", "DeltaExtraLibraries", "XMLParserPSP", "Project"];
				else
					u.error().UnknownPlatform();
				return result;
			}
			function vcsp_libpathcomponents(configuration) {
				local result = nil;
				if (u.iswin32())
					result = ["..", "..", "..", "..", "thesis_new", "deltaide", "Tools",
							"Delta", "DeltaExtraLibraries", "VCSolutionParser", "lib", configuration];
				else if (u.islinux())
					result = [ "..", "..", "..", "deltux", "psp", "projects", "Tools",
							"Delta", "DeltaExtraLibraries", "VCSolutionParser", "Project"];
				else
					u.error().UnknownPlatform();
				return result;
			}
			function makelibpath(libid, configuration, basename) {
				local libpathcomponents = std::vmfuncaddr(std::vmthis(), libid + "_libpathcomponents");
				local result = u.file_pathconcatenate(|libpathcomponents(configuration)|) + libifyname(libid, configuration, basename);
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
				local src           = makelibpath(libid, configuration, libbasename);
				local dst           = makelibname(libid, configuration, libbasename);
				u.println("Copying " + src + " to " + dst);
				u.shellcopy(src, dst);
			}
		};
		if (@config.update_libs)
			copylibs();
		local libs_loaded_successfully = u.loadlibs();
		if (not libs_loaded_successfully)
			u.error().AddError("Could not load required libs");
		return libs_loaded_successfully;
	},
	method generateSolutionXML (solutionPath) {
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
	},
	method loadSolutionXML {
		local data = u.xmlload(SolutionXMLpath);
		if (not data)
			u.error().AddError(u.xmlloaderror());
		return data;
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
					"SolutionLoader/Source/SolutionData.dsc",
					"SolutionLoader/Source/SolutionLoader.dsc",
					"SolutionLoader/Source/ReportGenerator.dsc",
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
		const SolutionReportPath = "SolutioReport.xhtml";
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
	},
	method cleanup {
	}
];

function main (argc, argv, envp) {
	p.config = envp;
	p.init(argv);
	
	local solutionXML  = p.loadSolutionXML();
	local solutionData = sl.SolutionLoader_LoadSolution(solutionXML);
	
	p.generateReport(solutionData);
	p.cleanup();

	u.println("--done--");
}


