package jd2m.project;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;
import jd2m.cbuild.CProperties;
import jd2m.cbuild.builders.CProjectBuilder;
import jd2m.solution.ConfigurationManager;
import jd2m.util.ProjectId;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

public final class XmlAnalyser {

    private static class XmlTreeWalker {
        private final Map<String, CProjectBuilder> _builders;
        XmlTreeWalker (final Map<String, CProjectBuilder> projConfToProjMap) {
            _builders = projConfToProjMap;
        }

        void VisitDocument (final Document doc) {
            for (   Node child = doc.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE            &&
                    child.getNodeName().equals("VisualStudioProject"))
                {
                    VisitRoot(child);
                }
            }
        }

        void VisitRoot (final Node root) {
            assert root.getNodeType() == Node.ELEMENT_NODE;
            assert root.getNodeName().equals("VisualStudioProject");

            for(Node child = root.getFirstChild();
                child != null;
                child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    final String name = child.getNodeName();
                    switch (name) {
                        case "Configurations":
                            VisitConfigurations(child);
                            break;
                        case "References":
                            VisitReferences(child);
                            break;
                        case "Files":
                            VisitFiles(child);
                    }
                }
            }
        }

        void VisitConfigurations (final Node configurationsNode) {
            for (   Node child = configurationsNode.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeName().equals("Configuration"))
                    VisitConfiguration(child);
            }
        }

        void VisitConfiguration (final Node configuration) {
            final NamedNodeMap attrs = configuration.getAttributes();
            final String configurationName = attrs.getNamedItem("Name")
                    .getNodeValue();
            final String outputDirectory = attrs
                    .getNamedItem("OutputDirectory").getNodeValue();
            final String intermediateDirectory = attrs
                    .getNamedItem("IntermediateDirectory")
                    .getNodeValue();
            final String projectType = attrs
                    .getNamedItem("ConfigurationType").getNodeValue();
            final String propertySheets = attrs
                    .getNamedItem("InheritedPropertySheets")
                    .getNodeValue();
            // TODO figure out codes for encodings (and use it in CProject)
            final String charset = attrs
                    .getNamedItem("CharacterSet").getNodeValue();

            assert _builders.containsKey(configurationName);

            final CProjectBuilder builder = _builders.get(configurationName);
            builder.SetOutput(new File(outputDirectory));
            builder.SetIntermediate(new File(intermediateDirectory));
            builder.SetType(_u_vsProjTypeToCProjType(projectType));
            _u_addPropertySheets(builder, propertySheets);
            //
            // the default propject properties
            final CProperties props = new CProperties();
            builder.AddProperty(props);

            for (   Node child = configuration.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE    &&
                    child.getNodeName().equals("Tool"))
                {
                    final Node tool = child;
                    final NamedNodeMap toolAttrs = tool.getAttributes();
                    final String toolName = toolAttrs.getNamedItem("Name")
                            .getNodeValue();
                    switch (toolName) {
                        case "VCCLCompilerTool": {
                            final String definitions = toolAttrs
                                    .getNamedItem("PreprocessorDefinitions")
                                    .getNodeValue();
                            _u_addDefinitions(props, definitions);
                            break;
                        }
                        case "VCLinkerTool": {
                            //
                            final String outputFilePath = toolAttrs
                                    .getNamedItem("OutputFile").getNodeValue();
                            final String libDirectories = toolAttrs
                                    .getNamedItem("AdditionalLibraryDirectories")
                                    .getNodeValue();
                            //
                            final File outputFile = new File(outputFilePath);
                            assert outputFile.isFile();
                            assert !outputFile.isAbsolute();
                            builder.SetOutput(outputFile.getParentFile());
                            //
                            final String nameWithExt = outputFile.getName();
                            final String[] nameTokens =
                                    _u_SplitName(nameWithExt);
                            final String name = nameTokens[0];
                            final String ext  = nameTokens[1];
                            builder.SetTarget(name);
                            builder.SetExt(ext);
                            //
                            _u_addLibraryDirectories(props, libDirectories);
                            break;
                        }
                    }
                }
            }
        }

        void VisitReferences (final Node referencesNode) {
            assert referencesNode.getNodeType() == Node.ELEMENT_NODE;
            assert referencesNode.getNodeName().equals("References");

            for (   Node child = referencesNode.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE    &&
                    child.getNodeName().equals("ProjectReference"))
                {
                    final Node projRefNode = child;
                    final NamedNodeMap attrs = projRefNode.getAttributes();
                    //
                    final String referenceId = attrs
                            .getNamedItem("ReferencedProjectIdentifier")
                            .getNodeValue();
                    final String referencePath = attrs // TODO store reference paths somewhere too
                            .getNamedItem("RelativePathToProject")
                            .getNodeValue();
                    //
                    // Add references for every project configuration
                    for (   final Entry<String, CProjectBuilder> entry:
                            _builders.entrySet())
                        entry.getValue().AddDependency(referenceId);
                }
            }
        }

        private final List<File> _sources = new LinkedList<>();
        void VisitFiles (final Node files) {
            assert files.getNodeType() == Node.ELEMENT_NODE;
            assert files.getNodeName().equals("Files");

            for (   Node child = files.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    final String childNodeName = child.getNodeName();
                    switch (childNodeName) {
                        case "Filter":
                            VisitFilter(child);
                            break;
                        case "File":
                            VisitFile(child);
                            break;
                    }
                }
            }

            for (final File source: _sources)
                for (   final Entry<String, CProjectBuilder> entry:
                        _builders.entrySet())
                    entry.getValue().AddSource(source);
        }

        void VisitFilter (final Node filter) {
            assert filter.getNodeType() == Node.ELEMENT_NODE;
            assert filter.getNodeName().equals("Filter");

            for (   Node child = filter.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    final String childNodeName = child.getNodeName();
                    switch (childNodeName) {
                        case "Filter":
                            VisitFilter(child);
                            break;
                        case "File":
                            VisitFile(child);
                            break;
                    }
                }
            }
        }


        void VisitFile (final Node fileNode) {
            assert fileNode.getNodeType() == Node.ELEMENT_NODE;
            assert fileNode.getNodeName().equals("File");

            final String filePath = fileNode.getAttributes()
                    .getNamedItem("RelativePath").getNodeValue();
            _sources.add(new File(filePath));

            for (   Node child = fileNode.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    final String childNodeName = child.getNodeName();
                    switch (childNodeName) {
                        case "Filter":
                            VisitFilter(child);
                            break;
                        case "File":
                            VisitFile(child);
                            break;
                    }
                }
            }
        }

        // -------------------------------------
        private CProjectType _u_vsProjTypeToCProjType (final String vsProjType){
            CProjectType result = null;
            switch (vsProjType) {
                case "1":   result = CProjectType.Executable;       break;
                case "2":   result = CProjectType.DynamicLibrary;   break;
                case "4":   result = CProjectType.StaticLibrary;    break;
                default: throw new RuntimeException("Unknown VSProjType: "
                            + vsProjType);
            }
            return result;
        }
        private static final Pattern _u_SemicolonPattern = Pattern
                .compile(";");
        private void _u_addPropertySheets ( final CProjectBuilder builder,
                                            final String sheetsLine)
        {
            final String[] tokens = _u_SemicolonPattern.split(sheetsLine, 0);
            // TODO load sheets
        }
        private void _u_addDefinitions (final CProperties   props,
                                        final String        definitions) {
            final String[] tokens = _u_SemicolonPattern.split(definitions, 0);
            for (final String token: tokens)
                props.AddDefinition(token);
        }
        private String[] _u_SplitName (final String nameWithExt) {
            final int dotIndex = nameWithExt.lastIndexOf('.');
            assert dotIndex > 0;
            assert nameWithExt.length() > dotIndex + 1;
            final String ext = nameWithExt.substring(dotIndex+1);
            final String name = nameWithExt.substring(0, dotIndex);
            return new String[] {name, ext};
        }
        private void _u_addLibraryDirectories ( final CProperties   props,
                                                final String        dirpaths) {
            final String[] paths = _u_SemicolonPattern.split(dirpaths);
            final List<String> paths_iterable = java.util.Arrays.asList(paths);
            props.AddLibraryDirectoriesFromPaths(paths_iterable);
        }
    }

    public static Map<String, CProject> ParseProjectXML (final Document doc,
                                            final ConfigurationManager m,
                                            final ProjectId id)
    {
        final Map<String, CProjectBuilder> builders = new HashMap<>(5);

        {
            // TODO add loggig to the walking
            new XmlTreeWalker(builders).VisitDocument(doc);
        }

        final Map<String, CProject> result = new HashMap<>(5);
        for (final Entry<String, CProjectBuilder> entry: builders.entrySet())
            result.put(entry.getKey(), entry.getValue().MakeProject());
        
        return result;
    }

    public static Map<String, CProject> ParseProjectXML (final InputStream ins,
                                            final ConfigurationManager m,
                                            final ProjectId id)
    {
        Map<String, CProject> result = null;
        try {
            final Document xmlDoc = DocumentBuilderFactory.newInstance().
                    newDocumentBuilder().parse(ins);
            xmlDoc.normalize();
            result = ParseProjectXML(xmlDoc, m, id);
        } catch (ParserConfigurationException ex) {
            ex.printStackTrace();
        } catch (SAXException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    public static Map<String, CProject> ParseProjectXML (final File file,
                                            final ConfigurationManager m,
                                            final ProjectId id)
    {
        Map<String, CProject> result = null;
        try {
            result = ParseProjectXML(new FileInputStream(file), m, id);
        } catch (FileNotFoundException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    public static Map<String, CProject> ParseProjectXML (final String filepath,
                                            final ConfigurationManager m,
                                            final ProjectId id)
    {
        return ParseProjectXML(new File(filepath), m, id);
    }

    // ---------------------------
    
    private static final Logger LOG = Logger.getLogger(XmlAnalyser.class.getName());
    private XmlAnalyser () {
    }
}
