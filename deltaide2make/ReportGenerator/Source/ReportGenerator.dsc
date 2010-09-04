u = std::libs::import("util");
assert( u );

/////////////////////////////////////////////////////////////////
// report generation
// --------------------------------------------------------------
::p__ignoreReportGenerationRequests = false;
function ReportGenerator_ignoreReportGenerationRequests {
	::p__ignoreReportGenerationRequests = true;
}
function ReportGenerator_respectReportGenerationRequests {
	::p__ignoreReportGenerationRequests = false;
}
function ReportGenerator_ignoresReportGenerationRequests {
	return ::p__ignoreReportGenerationRequests;
}
function ReportGenerator_generateReport (report_file_path, outer_log, configurationManager, projectEntryHolder) {
	local log = u.bindfront(outer_log, "ReportGenerator: ");
	if ( ::ReportGenerator_ignoresReportGenerationRequests() )
		local result = true;
	else if ( result = u.tobool(local fh = std::fileopen(report_file_path, "wt")) ) {
		log("Generating results report...");
		
		local append = [ 
			method @operator () (str) {
				std::filewrite(@outf, str);
			},
			@buf: "",
			@outf: fh,
			@log: log
		];
		local conclude = [
			method @operator () { std::filewrite(@outfile, @appender.buf); },
			@outfile: fh,
			@appender: append
		];
		local isBuildable = configurationManager.isBuildable;
		
		append("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
	\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
			<head>
				<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
				<style type=\"text/css\" media=\"all\">
/*<![CDATA[*/
				body {
					background-color: #000000;
					font-family: \"verdana\", \"deja-vu sans\", sans-serif;
					font-size: 11px;
					color: #c0c0c0;
					text-wrap: unrestricted;
				}
				table {
					position: relative;
					width: 60%;
					max-width: 60%;
					left: 20%;
					border: 3px double #303030;
					border-collapse: collapse;
					background-color: #101010;
					margin: 2em 0 2em 0;
				}
				td, th {
					padding: .3em;
				}
				thead th {
					border-color: #505050;
					background-color: #301010;
				}
				.separator th, .separator td {
					border-top: 5px double #303030;
				}
				.buildable {
					background-color: #101810;
				}
				.projname {
					letter-spacing: .2em;
				}
				.projid {
					font-family: monospace;
				}
				.infopost_buildable, .infopost_id, .infopost_path, .infopost_deps, .infopost_rdeps {
					color: #a0a0a0;
					font-size: .85em;
					border-left: 1px solid #303030;
					text-align: right;
				}
				.infopost_buildable, .infopost_id, .infopost_path, .infopost_deps,
				.projid, .projpath, .projbuildable, .projdeps {
					border-bottom: 1px dotted #303030;
				}
				.buildable .projname, .nonbuildable .projname, .projdep_buildable, .projdep_nonbuildable  {
					padding-left: 20px;
					background-position: left center;
					background-repeat: no-repeat;
				}
				.buildable .projname, .projdep_buildable {
					background-image: url('resources/icons/icon16_tick.png');
				}
				.nonbuildable .projname {
					background-image: url('resources/icons/icon-minus (1).png');
				}
				
				.projdep_buildable {
					color: #a0c0a0;
				}
				
				.projdep_nonbuildable {
					color: #f00000;
					background-image: url('resources/icons/iconExclamation.png');
					font-weight: bold;
				}
				
				a.projdep_buildable, a.projdep_nonbuildable {
					text-decoration: none;
				}
				a.projdep_buildable:hover, a.projdep_nonbuildable:hover {
					text-decoration: underline;
				}
/*]]>*/
				</style>
				<title></title>
			</head><body>");
		foreach (local conf, configurationManager.Configurations()) {
			log("Adding results for solution configuration: ", conf);
			//
			append("<table summary=\"projects for configuration ");
			append(conf);
			append("\"><thead><tr><th colspan=\"3\">");
			append(conf);
			append("</th></tr></thead><tbody>");
			local projectsIDs = u.dobj_keys(configurationManager.Projects(conf));
			foreach (local projid, projectsIDs) {
				log("adding info for project ", projid);
				//
				function idescape(str) {
					return 
						u.strgsub(
							u.strgsub(
								u.strgsub(
									u.strgsub(
										u.strgsub(
											u.strgsub(str, "\"", "&quot;"),
											" ",
											"_"),
										"{",
										"_"),
									"}",
									"_"),
								"-",
								"_"),
							"|",
							"_")
					;
				}
				function makeprojhtmlid (conf, projid) {
					return idescape(conf) + "_" + idescape(projid);
				}
				local projectEntry = projectEntryHolder.getProjectEntry(projid);
				local buildable = isBuildable(conf, projid);
				local trclass = (function (buildable) {
						local trclass = nil;
						if ( buildable )
							trclass = "buildable";
						else
							trclass = "nonbuildable";
						return trclass;
				})(buildable);
				local tr = "<tr class=\"" + trclass + "\">";
				local projname = projectEntry.getName();
				local projhtmlid = makeprojhtmlid(conf, projid);
				append("<tr class=\"");
				append(trclass);
				append(" separator\"><th class=\"projname\" rowspan=\"5\" id=\"" +
						projhtmlid + "\">");
				append(projname);
				append("</th><td class=\"infopost_id\">ID:</td><td class=\"projid\">");
				append(projectEntry.getID());
				append("</td></tr>");
				append(tr);
				append("<td class=\"infopost_path\">Path:</td><td class=\"projpath\">");
				append(projectEntry.getLocation().deltaString());
				append("</td></tr>");
				append(tr);
				append("<td class=\"infopost_buildable\">Buildable:</td><td class=\"projbuildable\">");
				append(buildable);
				append("</td></tr>");
				append(tr);
				append("<td class=\"infopost_deps\">Depends on:</td><td class=\"projdeps\">");
				//
				function appendDep (append, depid, makeprojhtmlid, isBuildable, conf, getProjectEntry) {
					local buildable = isBuildable(conf, depid);
					local depentry = getProjectEntry(depid);
					local class = "projdep_" + u.ternary(buildable, "buildable", "nonbuildable");
					append("<a class=\"");
					append(class);
					append("\" href=\"#" + makeprojhtmlid(conf, depid) + "\">");
					append(depentry.getName());
					append("</a>");
				}
				local comma = "";
				foreach (local depid, u.list_to_stdlist(projectEntry.Dependencies())) {
					append(comma);
					appendDep(append, depid, makeprojhtmlid, isBuildable, conf, projectEntryHolder.getProjectEntry);
					comma = ", ";
				}
				append("</td></tr>");
				append(tr);
				append("<td class=\"infopost_rdeps\">R-Depend:</td><td class=\"projrdeps\">");
				function dependsOn (projentryHolder, projid, rdepid) {
					return u.iterable_contains(
						projentryHolder.getProjectEntry(rdepid).Dependencies(),
						projid);
				}
				comma = "";
				foreach (local rdepid, u.dobj_keys(configurationManager.Projects(conf)))
					if ( dependsOn(projectEntryHolder, projid, rdepid) ) {
						append(comma);
						appendDep(append, rdepid, makeprojhtmlid, isBuildable, conf, projectEntryHolder.getProjectEntry);
						comma = ", ";
					}
				append("</td></tr>");
			}
			append("</tbody></table>");
		}
		append("</body></html>");
		
		conclude();
	}
	else
		log("Could not open ", report_file_path, " for writing");
	return result;
}

////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("ReportGenerator", nil, nil);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////
