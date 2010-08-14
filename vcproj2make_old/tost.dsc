dll = std::dllimport("../../../../thesis_new/"
	"Delta/DeltaExtraLibraries/XMLParser/lib/debug/XMLParserD.dll", "Install");
assert(dll);

std::print(#xmlparse("
			<root> 
				<parent attr=\"lal\">
					<choild/>
					<contoild>  Halloa  </contoild>
				</parent>
			</root>"));