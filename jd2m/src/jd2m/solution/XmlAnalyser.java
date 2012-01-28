package jd2m.solution;

import java.nio.file.Files;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jd2m.util.ProjectId;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

import static jd2m.util.PathHelper.UnixifyPath;

final class XmlAnalyser {

    private static class XmlTreeWalker {
        private final ConfigurationManager  _configurationManager;
        private final ProjectEntryHolder    _projectEntryHolder;
        private final PathResolver          _pathResolver;
        XmlTreeWalker ( final ConfigurationManager  configurationManager,
                        final ProjectEntryHolder    projectEntryHolder,
                        final PathResolver          pathResolver)
        {
            _configurationManager   = configurationManager;
            _projectEntryHolder     = projectEntryHolder;
            _pathResolver           = pathResolver;
        }

        void VisitDocument (final Node doc) {
            assert doc.getNodeType() == Node.DOCUMENT_NODE;
            final Node xmlRoot = doc.getFirstChild();
            assert xmlRoot == doc.getLastChild();
            VisitRoot (xmlRoot);
        }

        void VisitRoot (final Node root) {
            assert root.getNodeType() == Node.ELEMENT_NODE;
            assert root.getNextSibling() == null;
            assert root.getPreviousSibling() == null;
            assert root.getNodeName().equals("VisualStudioSolution");

            for (   Node child = root.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    final String nodeName = child.getNodeName();
                    if (nodeName.equals("Project"))
                        VisitProject(child);
                    else
                    if (nodeName.equals("Global"))
                        VisitGlobal(child);
                }
            }
        }

        private ProjectEntry _projectEntry;
        void VisitProject (final Node project) {
            assert ! _globalVisited;
            assert project.getNodeType() == Node.ELEMENT_NODE;
            assert project.getNodeName().equals("Project");

            final NamedNodeMap attrs = project.getAttributes();
            final Node id           = attrs.getNamedItem("id");
            final Node path         = attrs.getNamedItem("path");
            final Node name         = attrs.getNamedItem("name");
            final Node parentref    = attrs.getNamedItem("parentref");

            assert id.getNodeType()         == Node.ATTRIBUTE_NODE;
            assert path.getNodeType()       == Node.ATTRIBUTE_NODE;
            assert name.getNodeType()       == Node.ATTRIBUTE_NODE;
            assert parentref.getNodeType()  == Node.ATTRIBUTE_NODE;

            final String projectXmlFilePathWindows = path.getNodeValue();
            final String projectXmlFilePath =
                    UnixifyPath(projectXmlFilePathWindows);
            // Only save a project entry if this is actually a project entry.
            // <Project> tags are also used for solution filters.
            final Path projectXmlFileFullPath = _pathResolver
                    .SolutionResolve(projectXmlFilePath);
            if (Files.exists(projectXmlFileFullPath)) {
                _projectEntry = ProjectEntry.Create(
                        ProjectId.GetOrCreate(id.getNodeValue()),
                        name.getNodeValue(),
                        projectXmlFilePath,
                        ProjectId.GetOrCreate(parentref.getNodeValue()));

                for (   Node child = project.getFirstChild();
                        child != null;
                        child = child.getNextSibling())
                {
                    if (    child.getNodeType() == Node.ELEMENT_NODE        &&
                            child.getNodeName().equals("ProjectSection")    &&
                            child.getAttributes().getNamedItem("type").
                                    getNodeValue().equals("ProjectDependencies")
                    )
                        VisitProjectDependencies(child);
                }

                LOG.log(Level.INFO, "Adding project entry {0}", _projectEntry);
                _projectEntryHolder.Add(_projectEntry);

                _projectEntry = null;
            }
            else
                LOG.log(Level.INFO, "Ignoring node {0} because file {1} does not exist",
                        new Object[]{project, projectXmlFileFullPath});
        }

        void VisitProjectDependencies (final Node node) {
            {
                assert node.getNodeType() == Node.ELEMENT_NODE;
                assert node.getNodeName().equals("ProjectSection");
                final Node type = node.getAttributes().getNamedItem("type");
                assert type.getNodeValue().equals("ProjectDependencies");
            }
            for (   Node child = node.getFirstChild();
                    child != null;
                    child = child.getNextSibling())
            {
                if (    child.getNodeType() == Node.ELEMENT_NODE        &&
                        child.getNodeName().equals("Pair"))
                {
                    final String value = _u_singleValueFromPair(child);
                    final ProjectId dependencyId = ProjectId.GetOrCreate(value);

                    LOG.log(Level.INFO, "Adding dependency {0} for {1}",
                            new Object[]{dependencyId, _projectEntry});
                    _projectEntry.AddDependency(dependencyId);
                }
            }
        }

        private boolean _globalVisited = false;
        void VisitGlobal (final Node global) {
            assert global.getNodeType() == Node.ELEMENT_NODE;
            assert global.getNodeName().equals("Global");
            assert ! _globalVisited;
            _globalVisited = true;

            boolean visitedSolutions = false;
            boolean visitedProjects  = false;
            for (   Node childNode = global.getFirstChild();
                    childNode != null && !(visitedSolutions && visitedProjects);
                    childNode = childNode.getNextSibling())
            {
                final Node node = childNode;
                if (    node.getNodeType() == Node.ELEMENT_NODE &&
                        node.getNodeName().equals("GlobalSection"))
                {
                    final String type = node.getAttributes().
                            getNamedItem("type").getNodeValue();
                    if (type.equals("SolutionConfigurationPlatforms")) {
                        assert !visitedSolutions;
                        VisitSolutionConfigurationPlatforms(node);
                        visitedSolutions = true;
                    }
                    else
                    if (type.equals("ProjectConfigurationPlatforms")) {
                        assert !visitedProjects;
                        VisitProjectConfigurationPlatforms(node);
                        visitedProjects = true;
                    }
                    else
                        throw new RuntimeException("Unknow child " + node);
                }
            }
            assert visitedSolutions && visitedProjects;
        }

        void VisitSolutionConfigurationPlatforms (final Node solConfPlats) {
            _u_assertGlobalSection( solConfPlats,
                                    "SolutionConfigurationPlatforms");

            for (   Node pair = solConfPlats.getFirstChild();
                    pair != null;
                    pair = pair.getNextSibling())
            {
                if (pair.getNodeType() == Node.ELEMENT_NODE) {
                    final String value = _u_singleValueFromPair(pair);

                    _configurationManager.RegisterConfiguration(value);
                    LOG.log(Level.INFO, "Registering solution configuration {0}",
                            value);
                }
            }
        }

        private static final Pattern _DotRegExp = Pattern.compile("\\.");
        void VisitProjectConfigurationPlatforms (final Node projConfPlats) {
            _u_assertGlobalSection( projConfPlats,
                                    "ProjectConfigurationPlatforms");

            for (   Node pairNode = projConfPlats.getFirstChild();
                    pairNode != null;
                    pairNode = pairNode.getNextSibling())
            {
                if (    pairNode.getNodeType() == Node.ELEMENT_NODE &&
                        pairNode.getNodeName().equals("Pair"))
                {
                    final Pair pair = _u_makePair(pairNode);
                    final String[] tokens = _DotRegExp.split(pair.left, 0);
                    boolean buildable = false;
                    //
                    final String solConfName    = pair.right;
                    final String projId         = tokens[0];
                    final String projConfName   = tokens[1];
                    if (tokens.length == 3)
                        assert tokens[2].equals("ActiveCfg");
                    else {
                        assert tokens.length == 4;
                        assert tokens[2].equals("Build");
                        assert tokens[3].equals("0");
                        buildable = true;
                    }
                    //
                    if (!_configurationManager.
                            HasRegisteredProjectConfiguration(  solConfName,
                                                                projId)
                    )
                        _u_registerProject(projId, projConfName, solConfName);
                    if (buildable) {
                        LOG.log(Level.INFO, "Also marking {0}/{1} as buildable under {2}",
                                new Object[]{projId, projConfName, solConfName}
                        );
                        _configurationManager.MarkBuildable(solConfName,
                                                            projId);
                    }
                }
            }
        }

        /////////////////////////
        private final class Pair {
            final String left; final String right;
            Pair (final String _left, final String _right) {
                left = _left; right = _right;
            }
        }
        private Pair _u_makePair (final Node pair) {
            assert pair.getNodeType() == Node.ELEMENT_NODE;
            assert pair.getNodeName().equals("Pair");
            final NamedNodeMap attrs    = pair.getAttributes();
            final Node left             = attrs.getNamedItem("left");
            final Node right            = attrs.getNamedItem("right");
            final String leftStr        = left.getNodeValue();
            final String rightStr       = right.getNodeValue();

            return new Pair(leftStr, rightStr);
        }
        private String _u_singleValueFromPair (final Node pair) {
            final Pair values = _u_makePair(pair);
            assert values.left.equals(values.right);
            return values.left;
        }
        private void _u_assertGlobalSection (final Node node, final String nm) {
            assert node.getNodeType() == Node.ELEMENT_NODE;
            assert node.getNodeName().equals("GlobalSection");
            final Node type_attr = node.getAttributes().
                    getNamedItem("type");
            assert type_attr.getNodeType() == Node.ATTRIBUTE_NODE;
            assert type_attr.getNodeValue().equals(nm);
        }
        private void _u_registerProject (   final String projId,
                                            final String projConfName,
                                            final String solConfName)
        {
            LOG.log(Level.INFO, "Registering {0} with configuration {1} under solution configuration {2}",
                    new Object[] {projId, projConfName, solConfName});
            _configurationManager.RegisterProjectConfiguration(solConfName, projId, projConfName);
        }

    }


    /**
     * {@code doc} has to be {@link Document#normalize normalized}.
     * @param doc
     */
    static void ParseXML (  final Document doc,
                            final XmlAnalyserArguments args)
    {
        assert doc.getNodeName().equals("#document");

        new XmlTreeWalker(  args.configurationManager,
                            args.projectEntryHolder,
                            args.pathResolver).
                VisitDocument(doc);
    }

    static void ParseXML (  final InputStream ins,
                            final XmlAnalyserArguments args)
    {
        try {
            final Document xmlDoc = DocumentBuilderFactory.newInstance().
                    newDocumentBuilder().parse(ins);
            xmlDoc.normalize();
            ParseXML(xmlDoc, args);
        } catch (ParserConfigurationException ex) {
            ex.printStackTrace();
        } catch (SAXException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }

    static void ParseXML (  final Path file,
                            final XmlAnalyserArguments args)
    {
        try {
            final InputStream is = Files.newInputStream(file, StandardOpenOption.READ);
            final InputStream buffed_ins = new BufferedInputStream(is);
            ParseXML(buffed_ins, args);
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }

    static void ParseXML (  final String filepath,
                            final XmlAnalyserArguments args)
    {
        ParseXML(Paths.get(filepath), args);
    }

    private XmlAnalyser () {
    }
    private static final Logger LOG = Logger.getLogger(XmlAnalyser.class.getName());

}
