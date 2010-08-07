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
local sd = importVM("SolutionLoader/Lib/SolutionData.dbc", "SolutionData");
local sl = importVM("SolutionLoader/Lib/SolutionLoader.dbc", "SolutionLoader");


const SolutionXMLpath = "Solution.xml";
const RootTagName     = "VisualStudioSolution";
		
p = [
	/////////////////////////////////////////////////////////////
	// Load libs
	// ----------------------------------------------------------
	method LoadLibs {
		// Copy libs first
		(function copylibs {
			function libifyname(basename) {
				local result = nil;
				if (u.iswin32())
					result = u.libifyname(basename);
				else if (u.islinux())
					result = u.libifyname(basename + "-linux");
				else
					u.error().UnknownPlatform();
				return result;
			}
			function xmllibpathcomponents(configuration) {
				local result = nil;
				if (u.iswin32())
					result = ["..", "..", "..", "..", "thesis_new", "deltaide", "Tools", 
							"Delta", "DeltaExtraLibraries", "XMLParser", "lib", configuration];
				else if (u.islinux())
					result = ["..", "..", "..", "..", "deltux", "psp", "projects", "Tools", 
						"Delta", "DeltaExtraLibraries", "XMLParserPSP", "Project"];
				else
					u.error().UnknownPlatform();
				return result;
			}
			function vcsplibpathcomponents(configuration) {
				local result = nil;
				if (u.iswin32())
					result = ["..", "..", "..", "..", "thesis_new", "deltaide", "Tools",
							"Delta", "DeltaExtraLibraries", "VCSolutionParser", "lib", configuration];
				else if (u.islinux())
					result = [ "." ]; // dummy lib
				else
					u.error().UnknownPlatform();
				return result;
			}
			function makelibpath(libid, configuration, basename) {
				local libpathcomponents = std::vmfuncaddr(std::vmthis(), libid + "libpathcomponents");
				local result = u.file_pathconcatenate(|libpathcomponents(configuration)|) + libifyname(basename);
				return result;
			}
			// Libs basenames
			const xmllibbasename           = "XMLParser";
			const vcsolutionparserbasename = "VCSolutionParser";
			// Libs info
			libsinfo = [
				["release", "xml" , xmllibbasename                ],
				["debug"  , "xml" , xmllibbasename + "D"          ],
				["."      , "vcsp", vcsolutionparserbasename      ],
				["."      , "vcsp", vcsolutionparserbasename + "D"]
			];
			foreach (local libinfo, libsinfo) {
				local configuration = libinfo[0];
				local libid         = libinfo[1];
				local libbasename   = libinfo[2];
				//
				local src           = makelibpath(libid, configuration, libbasename);
				local dst           = u.libifyname(libbasename);
				u.println("Copying " + src + " to " + dst);
				u.shellcopy(src, dst);
			}
		})();
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
			u.shell(shellcommandGenerator(solutionPath, SolutionXMLpath));
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
	method loadSolutionData {
		local data = u.xmlload(SolutionXMLpath);
		if (not data)
			u.error().AddError(u.xmlloaderror());
		return data;
	},
	method generateSedCommandLinux (inputPath, outputPath) {
		function bashescape (str) {
			function squote (str) {
				return "'" + str + "'";
			}
			return squote(u.strgsub(str, "'", "'\\''"));
		}
		return "sed --regexp-extended --file " + bashescape("vcsol2xml.sed") +
				" " + bashescape(inputPath) + " 1> " + bashescape(outputPath);
	},
	method generateSedCommandWin32 (inputPath, outputPath) {
		return "\cygwin\bin\sed --regexp-extended --file vcsol2xml.sed " +
				inputPath + " >> " + outputPath;
	}
];

function main (argc, argv, envp) {
	local solutionPath = argv[2];
	local solutionName = argv[1];
	
	p.LoadLibs();
	p.generateSolutionXML(solutionPath);
	
	local solutionXML  = p.loadSolutionData();
	local solutionData = sl.SolutionLoader_LoadSolution(solutionXML);
	
	u.println("--done--");
}


