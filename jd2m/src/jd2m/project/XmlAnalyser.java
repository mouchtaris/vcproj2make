package jd2m.project;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jd2m.cbuild.CProject;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

public final class XmlAnalyser {

    private static class XmlTreeWalker {
        private final Map<String, CProject> _projConfToProjMap;
        XmlTreeWalker (final Map<String, CProject> projConfToProjMap) {
            _projConfToProjMap = projConfToProjMap;
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
            // <editor-fold defaultstate="collapsed" desc="TODO store all these data">
            final NamedNodeMap attrs = configuration.getAttributes();
            final String configurationName = attrs.getNamedItem("Name")
                    .getNodeValue();
            final String outputDirectory = attrs
                    .getNamedItem("OutputDirectory").getNodeValue();
            final String intermediateDirectory = attrs
                    .getNamedItem("IntermediateDirectory")
                    .getNodeValue();
            // TODO fix an enum for configuration types
            final String configurationType = attrs
                    .getNamedItem("ConfigurationType").getNodeValue();
            final String propertySheets = attrs
                    .getNamedItem("InheritedPropertySheets")
                    .getNodeValue();
            // TODO figure out codes for encodings
            final String charset = attrs
                    .getNamedItem("CharacterSet").getNodeValue();
            // </editor-fold>

            assert _projConfToProjMap.containsKey(configurationName);

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
                            // <editor-fold defaultstate="collapsed" desc="TODO store all these data">
                            final String definitions = toolAttrs
                                    .getNamedItem("PreprocessorDefinitions")
                                    .getNodeValue();
                            // </editor-fold>
                            break;
                        }
                        case "VCLinkerTool": {
                            // <editor-fold defaultstate="collapsed" desc="TODO store all these data">
                            final String outputFile = toolAttrs
                                    .getNamedItem("OutputFile").getNodeValue();
                            final String libDirectories = toolAttrs
                                    .getNamedItem("AdditionalLibraryDirectories")
                                    .getNodeValue();
                            // </editor-fold>
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
                    // TODO add these things
                    final String referenceId = attrs
                            .getNamedItem("ReferencedProjectIdentifier")
                            .getNodeValue();
                    final String referencePath = attrs
                            .getNamedItem("RelativePathToProject")
                            .getNodeValue();
                }
            }
        }

        private final List<File> _sources = new LinkedList<>(); // TODO add to the c-project
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

            final String filePath = fileNode.getAttributes() // TODO store to c-project
                    .getNamedItem("RelativePath").getNodeValue();

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

    }

    public static CProject ParseProjectXML (final Document doc) {
        final CProject cproj = new CProject();

        {
            // TODO , walk doc
            LOG.info("Ah mista logga loooga");
        }

        return cproj;
    }

    public static CProject ParseProjectXML (final InputStream ins) {
        CProject result = null;
        try {
            final Document xmlDoc = DocumentBuilderFactory.newInstance().
                    newDocumentBuilder().parse(ins);
            xmlDoc.normalize();
            result = ParseProjectXML(xmlDoc);
        } catch (ParserConfigurationException ex) {
            ex.printStackTrace();
        } catch (SAXException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    public static CProject ParseProjectXML (final File file) {
        CProject result = null;
        try {
            result = ParseProjectXML(new FileInputStream(file));
        } catch (FileNotFoundException ex) {
            ex.printStackTrace();
        }

        return result;
    }

    public static CProject ParseProjectXML (final String filepath) {
        return ParseProjectXML(new File(filepath));
    }
    private static final Logger LOG = Logger.getLogger(XmlAnalyser.class.getName());

    private XmlAnalyser () {
    }
}
