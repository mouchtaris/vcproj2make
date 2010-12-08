package jd2m.project;

import java.io.BufferedInputStream;
import java.io.FileFilter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;
import jd2m.cbuild.CProperties;
import jd2m.cbuild.builders.CProjectBuilder;
import jd2m.solution.VariableEvaluator;
import jd2m.util.Name;
import jd2m.util.ProjectId;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

import static jd2m.util.PathHelper.IsWindowsPath;
import static jd2m.util.PathHelper.UnixifyPath;
import static jd2m.util.PathHelper.CreatePath;
import static jd2m.util.PathHelper.GetFileSystem;

final class XmlAnalyser {

    public static final Path API_DIRECTORY = CreatePath("../Include");

    private static class XmlTreeWalker {
        private final Map<String, CProjectBuilder> _builders = new HashMap<>(5);
        private final Name              _projectName;
        private final ProjectId         _projectId;
        private final Path              _projectLocation;
        private final VariableEvaluator _ve;
        XmlTreeWalker ( final Name              projectName,
                        final ProjectId         projectId,
                        final Path              projectLocation,
                        final VariableEvaluator ve)
        {
            assert !IsWindowsPath(projectLocation.toString());

            _projectName        = projectName;
            _projectId          = projectId;
            _projectLocation    = projectLocation;
            _ve                 = ve;
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

        private boolean _visitedConfigurations = false;
        private boolean _visitingConfigurations = false;
        void VisitConfigurations (final Node configurationsNode) {
            assert !_visitedConfigurations;
            assert !_visitingConfigurations;
            _visitingConfigurations = true;
            //
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
            //
            _visitingConfigurations = false;
            _visitedConfigurations = true;
        }

        void VisitConfiguration (final Node configuration) {
            _ve.Reset();
            _ve.SetProjectName(_projectName.StringValue());
            //
            final NamedNodeMap attrs = configuration.getAttributes();
            final String configurationName = attrs.getNamedItem("Name")
                    .getNodeValue();
            //
            CProjectBuilder _builder = _builders.get(configurationName);
            if (_builder == null) {
                _builder = new CProjectBuilder();
                _builders.put(configurationName, _builder);
            }
            final CProjectBuilder builder = _builder;
            _builder.SetConfiguration(configurationName);
            _ve.SetConfigurationName(configurationName);
            //
            final String _m_outputDirectoryUnevaluated = attrs
                    .getNamedItem("OutputDirectory").getNodeValue();
            final String _m_outputDirectoryUnevaluatedUnix =
                    UnixifyPath(_m_outputDirectoryUnevaluated);
            final String outputDirectory = _ve
                    .EvaluateString(_m_outputDirectoryUnevaluatedUnix);
            final String _m_intermediateDirectoryUnevaluated = attrs
                    .getNamedItem("IntermediateDirectory")
                    .getNodeValue();
            final String _m_intermediateDirectoryUnevaluatedUnix =
                    UnixifyPath(_m_intermediateDirectoryUnevaluated);
            final String intermediateDirectory = _ve
                    .EvaluateString(_m_intermediateDirectoryUnevaluatedUnix);
            final String projectType = attrs
                    .getNamedItem("ConfigurationType").getNodeValue();
            final Node propertySheetsAttr = attrs
                    .getNamedItem("InheritedPropertySheets");
            // TODO figure out codes for encodings (and use it in CProject)
            final String charset = attrs
                    .getNamedItem("CharacterSet").getNodeValue();

            //
            _ve.SetOutDir(outputDirectory);
            final Path output = CreatePath(outputDirectory);
            builder.SetOutput(output);
            //
            final Path intermediate = CreatePath(intermediateDirectory);
            builder.SetIntermediate(intermediate);
            //
            final CProjectType type = _u_vsProjTypeToCProjType(projectType);
            builder.SetType(type);
            //
            LOG.log(Level.INFO, "Output = {0}\nIntermediate = {1}\nType = {2}",
                    new Object[]{output, intermediate, type});

            if (propertySheetsAttr != null) {
                final String propertySheets = propertySheetsAttr.getNodeValue();
                _u_addPropertySheets(builder, propertySheets);
            }
            
            //
            // the default propject properties
            final CProperties props = new CProperties();
            builder.AddProperty(props);

            boolean visitedCompiler = false, visitedLinker = false;
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
                            assert !visitedCompiler;
                            final String definitions = toolAttrs
                                    .getNamedItem("PreprocessorDefinitions")
                                    .getNodeValue();
                            _u_addDefinitions(props, definitions);
                            visitedCompiler = true;
                            break;
                        }
                        case "VCLinkerTool":
                        case "VCLibrarianTool":
                            assert !visitedLinker;
                            _u_extractLinkerInfo(toolAttrs, outputDirectory, builder, type, props);
                            visitedLinker = true;
                            break;
                    }
                }
            }
            assert visitedCompiler && visitedLinker;
        }

        void VisitReferences (final Node referencesNode) {
            assert _visitedConfigurations;
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
                    final String referenceIdStr = attrs
                            .getNamedItem("ReferencedProjectIdentifier")
                            .getNodeValue();
                    final String referencePath = attrs // TODO store reference paths somewhere too
                            .getNamedItem("RelativePathToProject")
                            .getNodeValue();
                    //
                    // Add references for every project configuration
                    final ProjectId referenceId = ProjectId
                            .GetOrCreate(referenceIdStr);
                    for (   final Entry<String, CProjectBuilder> entry:
                            _builders.entrySet())
                        entry.getValue().AddDependency(referenceId);

                    LOG.log(Level.INFO, "parent reference = {0}", referenceId);
                }
            }
        }

        private final List<Path> _sources = new LinkedList<>();
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

            for (final Path source: _sources)
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


        private static final PathMatcher _u_CppSourceFilesFilter =
                GetFileSystem().getPathMatcher("glob:**.cpp");

        void VisitFile (final Node fileNode) {
            assert fileNode.getNodeType() == Node.ELEMENT_NODE;
            assert fileNode.getNodeName().equals("File");

            final String _m_filePathWindows = fileNode.getAttributes()
                    .getNamedItem("RelativePath").getNodeValue();
            final String filePath = UnixifyPath(_m_filePathWindows);
            final Path potentialSourceFile = CreatePath(filePath);
            if (_u_CppSourceFilesFilter.matches(potentialSourceFile))
                _sources.add(potentialSourceFile);

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
                .compile(";+");
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
            for (final String _m_unevaluatedWindowsPath: paths) {
                final String _m_unevaluatedUnixPath =
                        UnixifyPath(_m_unevaluatedWindowsPath);
                final String path = _ve.EvaluateString(_m_unevaluatedUnixPath);
                if (!path.isEmpty())
                    props.AddLibraryDrectory(path);
            }
            LOG.log(Level.INFO, "library paths = {0}",
                    java.util.Arrays.toString(paths));
        }
        private final Pattern _u_SemicolonOrWhitespacePattern = Pattern
                .compile("[; ]+");
        private void _u_extractLinkerInfo ( final NamedNodeMap toolAttrs,
                                            final String outputDirectory,
                                            final CProjectBuilder builder,
                                            final CProjectType type,
                                            final CProperties props)
        {
            //
            final Node outputFilePathAttr = toolAttrs
                    .getNamedItem("OutputFile");
            final Node libDirectoriesAttr = toolAttrs
                    .getNamedItem("AdditionalLibraryDirectories");
            final Node additionalLibsAttr = toolAttrs
                    .getNamedItem("AdditionalDependencies");
            //
            String unevaluatedName, ext;
            String outputDirectory0str;
            //
            if (outputFilePathAttr != null) {
                final String outputFilePath = outputFilePathAttr.getNodeValue();
                final String outputFilePathUnix = UnixifyPath(outputFilePath);
                final String outputFilePathEvaluated = _ve
                        .EvaluateString(outputFilePathUnix);
                final Path outputFile = CreatePath(outputFilePathEvaluated);
                final Path outputDirectory0 = outputFile.getParent();
                assert outputDirectory0 != null;
                outputDirectory0str = outputDirectory0.toString();
                //
                final Path nameWithExtPath = outputFile.getName();
                final String[] nameTokens = _u_SplitName(
                        nameWithExtPath.toString());
                unevaluatedName = nameTokens[0];
                ext  = nameTokens[1];
            }
            else {
                outputDirectory0str = _ve.EvaluateString("$(OutDir)");
                unevaluatedName = "$(ProjectName)";
                ext  = type.GetExtension();
            }
            //
            if (!outputDirectory.equals(outputDirectory0str)) {
                LOG.log(Level.WARNING, "Project''s output directory {0} and linker''s output directory {1} do not match. Resetting outputDirectory to linker''s value",
                        new Object[] {outputDirectory, outputDirectory0str});
                final Path outputDirectory0 = CreatePath(outputDirectory0str);
                builder.SetOutput(outputDirectory0);
            }
            final String name = _ve.EvaluateString(unevaluatedName);
            builder.SetTarget(name);
            builder.SetExt(ext);
            //
            if (additionalLibsAttr != null) {
                final String additionalLibs = additionalLibsAttr.getNodeValue();
                final String[] tokens = _u_SemicolonOrWhitespacePattern
                        .split(additionalLibs);
                for (final String token: tokens)
                    props.AddWindowsLibrary(token);
                LOG.log(Level.INFO, "libraries = {0}",
                        java.util.Arrays.toString(tokens));
            }
            //
            LOG.log(Level.INFO, "name = {0}\nextension = {1}",
                    new Object[]{name, ext});
            //
            if (libDirectoriesAttr != null) {
                final String libDirectories = libDirectoriesAttr.getNodeValue();
                _u_addLibraryDirectories(props, libDirectories);
            }
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
                new XmlTreeWalker(args.name, args.id, args.location, args.ve)
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
