package jcproj.loading;

import jcproj.vcxproj.ProjectGuid;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;
import jcproj.vcxproj.ProjectGuidFactory;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static jcproj.util.xml.XmlTreeVisitor.MakeChildrenIterator;
import static jcproj.util.xml.XmlTreeVisitor.GetPairValue;
import static jcproj.util.xml.XmlTreeVisitor.GetPairLeft;
import static jcproj.util.xml.XmlTreeVisitor.GetPairRight;

/**
 *
 * @date Sunday 7th August 2011
 * @author amalia
 */
public final class SolutionXmlWalker {
    
    ///////////////////////////////////////////////////////
    
    public void VisitDocument (final Node doc) {
        VisitRoot(doc.getFirstChild());
    }
    
    ///////////////////////////////////////////////////////

    public void VisitRoot (final Node root) {
        assert root.getNodeName().equals("VisualStudioSolution");

        boolean visitedGlobal = false;
        
        for (Node child : MakeChildrenIterator(root))
            if (child.getNodeType() == Node.ELEMENT_NODE)
                switch (child.getNodeName()) {
                    case "Project":
                        VisitProject(child);
                        break;
                    case "Global": {
                        assert !visitedGlobal;
                        visitedGlobal = true;
                        VisitGlobal(child);
                        break;
                    }
                }
    }
  
    ///////////////////////////////////////////////////////
    
    public void VisitGlobal (final Node global) {
        assert global.getNodeType() == Node.ELEMENT_NODE;
        assert global.getNodeName().equals("Global");


        boolean visitedSolutions = false;
        boolean visitedProjects  = false;
        
        for (Node node : MakeChildrenIterator(global))
            if (node.getNodeName().equals("GlobalSection"))
                switch (node.getAttributes().getNamedItem("type").getNodeValue()) {
                    case "SolutionConfigurationPlatforms": {
                        assert !visitedSolutions;
                        visitedSolutions = true;
                        VisitSolutionConfigurationPlatforms(node);
                        break;
                    }
                    case "ProjectConfigurationPlatforms": {
                        assert !visitedProjects;
                        visitedProjects = true;
                        VisitProjectConfigurationPlatforms(node);
                        break;
                    }
                }

        assert visitedSolutions && visitedProjects;
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitSolutionConfigurationPlatforms (final Node solConfPlats) {
        for (Node pair : MakeChildrenIterator(solConfPlats))
            if (pair.getNodeType() == Node.ELEMENT_NODE)
                manager.RegisterSolutionConfiguration(GetPairValue(pair));
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitProjectConfigurationPlatforms (final Node projConfPlats) {
        for (Node pair : MakeChildrenIterator(projConfPlats))
            if (pair.getNodeType() == Node.ELEMENT_NODE) {
                final String left = GetPairLeft(pair);
                final String solconfigid = GetPairRight(pair);
                
                final String[] lefts = Dot.split(left, 0);
                if (lefts.length == 4) {
                    assert lefts[2].equals("Build");
                    assert lefts[3].equals("0");
                    
                    final ProjectGuid   projid          = ProjectGuidFactory.GetSingleton().Get(lefts[0]);
                    final String        projconfigid    = lefts[1];
                    
                    manager.RegisterProjectEntryUnder(solconfigid, entries.get(projid).clone(projconfigid, true));
                }
            }
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitProject (final Node node) {
        final NamedNodeMap attrs = node.getAttributes();
        final ProjectGuid projid = ProjectGuidFactory.GetSingleton().Create(attrs.getNamedItem("id").getNodeValue());
        final ProjectConfigurationEntry entry = new ProjectConfigurationEntry(projid, attrs.getNamedItem("path").getNodeValue());
        final ProjectConfigurationEntry previous = entries.put(projid, entry);
        assert previous == null;
    }
            
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Accessors
    
    public ConfigurationManager GetConfigurationManager () {
        return manager;
    }

    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    // Private
    private final ConfigurationManager                          manager = new ConfigurationManager();
    private final Map<ProjectGuid, ProjectConfigurationEntry>   entries = new HashMap<>();
    
    // Static 
    private static final Pattern Dot = Pattern.compile("\\.");
    
} // class SolutionXmlWalker
