package jd2m.project;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;
import jd2m.cbuild.CProperties;
import jd2m.cbuild.builders.CProjectBuilder;
import jd2m.util.Name;
import jd2m.util.ProjectId;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

final class XmlAnalyser {

    public static final File API_DIRECTORY = new File("../Include");

    private static class XmlTreeWalker {
        private final Map<String, CProjectBuilder> _builders = new HashMap<>(5);
        private final Name      _projectName;
        private final ProjectId _projectId;
        private final File      _projectLocation;
        XmlTreeWalker ( final Name      projectName,
                        final ProjectId projectId,
                        final File      projectLocation)
        {
            _projectName        = projectName;
            _projectId          = projectId;
            _projectLocation    = projectLocation;
        }

        XmlTreeWalker VisitDocument (final Document  doc) {
            LOG.log(Level.INFO, "Analysing project {0}/{1}", new Object[]{
                    _projectName, _projectId});

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

            return this;
        }

        void VisitRoot (final Node root) {
            assert root.getNodeType() == Node.ELEMENT_NODE;
            assert root.getNodeName().equals("VisualStudioProject");

            final NamedNodeMap attrs    = root.getAttributes();
            final String projectName    = attrs.getNamedItem("Name")
                    .getNodeValue();
            assert _projectName.Equals(projectName);
            final String projectId      = attrs.getNamedItem("ProjectGUID")
                    .getNodeValue();
            assert _projectId.Equals(projectId);

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
            // foreach configuration, add the same location, name and id
            for (   final Entry<String, CProjectBuilder> entry:
                    _builders.entrySet())
            {
                final CProjectBuilder builder = entry.getValue();
                builder.SetLocation(_projectLocation);
                builder.SetName(_projectName);
                builder.SetId(_projectId);
                builder.SetApiDirectory(API_DIRECTORY);
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

            CProjectBuilder _builder = _builders.get(configurationName);
            if (_builder == null) {
                _builder = new CProjectBuilder();
                _builders.put(configurationName, _builder);
            }

            final CProjectBuilder builder = _builder;
            //
            final File output = new File(outputDirectory);
            builder.SetOutput(output);
            final File intermediate = new File(intermediateDirectory);
            builder.SetIntermediate(intermediate);
            final CProjectType type = _u_vsProjTypeToCProjType(projectType);
            builder.SetType(type);
            LOG.log(Level.INFO, "Output = {0}\nIntermediate = {1}\nType = {2}",
                    new Object[]{output, intermediate, type});

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
                            final Node outputFilePathAttr = toolAttrs
                                    .getNamedItem("OutputFile");
                            final Node libDirectoriesAttr = toolAttrs
                                    .getNamedItem("AdditionalLibraryDirectories");
                            String _libDirectories = null;
                            if (libDirectoriesAttr != null)
                                _libDirectories = libDirectoriesAttr
                                        .getNodeValue();
                            final String libDirectories = _libDirectories;
                            //
                            String name, ext;
                            if (outputFilePathAttr != null) {
                                final String outputFilePath = outputFilePathAttr
                                        .getNodeValue();
                                final File outputFile = new File(outputFilePath);
                                assert !outputFile.isAbsolute();
                                final File outputDirectory0 = outputFile.getParentFile();
                                if (!outputDirectory.equals(outputDirectory0))
                                {
                                    LOG.log(Level.WARNING, "Project's output directory {0} and linker's output directory {1} do not match. Resetting outputDirectory to linker's value",
                                            new Object[]{outputDirectory, outputDirectory0});
                                    builder.SetOutput(outputDirectory0);
                                }
                                //
                                final String nameWithExt = outputFile.getName();
                                final String[] nameTokens =
                                        _u_SplitName(nameWithExt);
                                name = nameTokens[0];
                                ext  = nameTokens[1];
                            }
                            else {
                                name = "$(ProjectName)";
                                ext  = type.GetExtension();
                            }
                            builder.SetTarget(name);
                            builder.SetExt(ext);
                            LOG.log(Level.INFO, "name = {0}\nextension = {1}",
                                    new Object[]{name, ext});
                            //
                            if (libDirectories != null)
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

                    LOG.log(Level.INFO, "parent reference = {0}", referenceId);
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

            LOG.log(Level.INFO, "sources = {0}", _sources);
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
            LOG.log(Level.INFO, "preprocessor definitions = {0}",
                    java.util.Arrays.toString(tokens));
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
            LOG.log(Level.INFO, "library paths = {0}",
                    java.util.Arrays.toString(paths));
        }
    }

    /**
     *
     * @param doc
     * @param args
     * @return a mapping from project configurations to {@link CProject}s
     */
    static Map<String, CProject> ParseProjectXML (final Document doc,
                                            final XmlAnalyserArguments args)
    {
        final Map<String, CProjectBuilder> builders =
                new XmlTreeWalker(args.name, args.id, args.location)
                .VisitDocument(doc)._builders;

        final Map<String, CProject> result = new HashMap<>(5);
        for (final Entry<String, CProjectBuilder> entry: builders.entrySet())
            result.put(entry.getKey(), entry.getValue().MakeProject());
        
        return result;
    }

    /**
     * same as {@link #ParseProjectXML(Document,XmlAnalyserArguments)}
     * @param ins
     * @param args
     * @return
     */
    static Map<String, CProject> ParseProjectXML (final InputStream ins,
                                            final XmlAnalyserArguments args)
    {
        Map<String, CProject> result = null;
        try {
            final Document xmlDoc = DocumentBuilderFactory.newInstance().
                    newDocumentBuilder().parse(ins);
            xmlDoc.normalize();
            result = ParseProjectXML(xmlDoc, args);
        } catch (ParserConfigurationException ex) {
            ex.printStackTrace();
        } catch (SAXException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    /**
     * same as {@link #ParseProjectXML(InputStream,XmlAnalyserArguments)}
     * @param path
     * @param args
     * @return
     */
    static Map<String, CProject> ParseProjectXML (final Path path,
                                            final XmlAnalyserArguments args)
    {
        Map<String, CProject> result = null;
        try {
            final InputStream is = path.newInputStream(StandardOpenOption.READ);
            final InputStream bins = new BufferedInputStream(is);
            result = ParseProjectXML(bins, args);
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    /**
     * same as {@link #ParseProjectXML(Path,XmlAnalyserArguments)}
     * @param file
     * @param args
     * @return
     */
    static Map<String, CProject> ParseProjectXML (final File file,
                                            final XmlAnalyserArguments args)
    {
        Map<String, CProject> result = null;
        result = ParseProjectXML(file.toPath(), args);

        return result;
    }

    /** same as {@link #ParseProjectXML(Path,XmlAnalyserArguments)}
     *
     * @param filepath
     * @param args
     * @return
     */
    static Map<String, CProject> ParseProjectXML (final String filepath,
                                            final XmlAnalyserArguments args)
    {
        Map<String, CProject> result = null;
        result =  ParseProjectXML(Paths.get(filepath), args);

        return result;
    }

    // ---------------------------
    
    private static final Logger LOG = Logger.getLogger(XmlAnalyser.class.getName());
    private XmlAnalyser () {
    }
}
