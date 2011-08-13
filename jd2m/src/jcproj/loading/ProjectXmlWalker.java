package jcproj.loading;

import jcproj.vcxproj.ProjectGuid;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.vcxproj.ClCompile;
import jcproj.vcxproj.ClCompileDefinition;
import jcproj.vcxproj.ClInclude;
import jcproj.vcxproj.Group;
import jcproj.vcxproj.Import;
import jcproj.vcxproj.ItemDefinition;
import jcproj.vcxproj.LinkDefinition;
import jcproj.vcxproj.Project;
import jcproj.vcxproj.ProjectConfiguration;
import jcproj.vcxproj.ProjectGuidFactory;
import jcproj.vcxproj.Property;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static jcproj.util.xml.XmlTreeVisitor.MakeChildrenIterator;
import static jcproj.util.xml.XmlTreeVisitor.GetChildSingleSubelementValue;
import static jcproj.util.xml.XmlTreeVisitor.GetSingleSubelementValue;
import static jcproj.util.xml.XmlTreeVisitor.GetAttributeValue;
import static jcproj.util.xml.XmlTreeVisitor.GetAttributeValueIfExists;
import static jcproj.util.xml.XmlTreeVisitor.GetChildIfExistsSingleSubelementValue;

/**
 *
 * 
 * @data Sunday 7th of August 2011
 * @author amalia
 */
public class ProjectXmlWalker {
    
    ///////////////////////////////////////////////////////
    
    public Project GetProject () {
        return project;
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitDocument (final Node document) {
        VisitRoot(document.getFirstChild());
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitRoot (final Node root) {
        final NamedNodeMap  attrs   = root.getAttributes();
        
        assert root.getNodeName().equals("Project");
        assert attrs.getNamedItem("DefaultTargets").getNodeValue().equals("Build");
        assert attrs.getNamedItem("ToolsVersion").getNodeValue().equals("4.0");
        assert attrs.getNamedItem("xmlns").getNodeValue().equals("http://schemas.microsoft.com/developer/msbuild/2003");
        
        for (final Node node : MakeChildrenIterator(root))
            if (node.getNodeType() == Node.ELEMENT_NODE)
                switch (node.getNodeName()) {
                    case "ItemGroup":
                        VisitItemGroup(node);
                        break;
                    case "PropertyGroup":
                        VisitPropertyGroup(node);
                        break;
                    case "Import":
                        VisitImport(node);
                        break;
                    case "ImportGroup":
                        VisitImportGroup(node);
                        break;
                    case "ItemDefinitionGroup":
                        VisitItemDefinitionGroup(node);
                        break;
                    default:
                        Loagger.log(Level.WARNING, "Ignoring element of type {0} while parsing <Project>", node.getNodeName());
                }
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitItemGroup (final Node group) {
        final String label = GetAttributeValueIfExists(group, "Label");
        final String condition = GetAttributeValueIfExists(group, "Condition");
        
        // Dispatch according to the first item. The rest are supposed to be the same
        for (final Node node : MakeChildrenIterator(group))
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                switch (node.getNodeName()) {
                    case "ProjectConfiguration":
                        project.AddItemGroup(MakeProjectConfigurationsItemGroup(label, condition, group));
                        break;
                    case "ClCompile":
                    case "ClInclude":
                        VisitClCompileOrClIncludeElements(label, condition, group);
                        break;
                    case "ProjectReference":
                        VisitProjectReferences(label, condition, group);
                        break;
                    case "ResourceCompile":
                    case "None":
                        // ignore
                        break;
                    default:
                        Loagger.log(Level.WARNING, "Ignoring a whole <ItemGroup> \"{1}\" of <{0}>s", new Object[]{node.getNodeName(),label});
                }
                break;
            }
    }
    
    ///////////////////////////////////////////////////////
    
    public Group<ProjectConfiguration> MakeProjectConfigurationsItemGroup (final String label, final String condition, final Node groupnode) {
        final Group<ProjectConfiguration> group = new Group<>(ProjectConfiguration.class, label, condition);
        
        for (final Node node : MakeChildrenIterator(groupnode))
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                assert node.getNodeName().equals("ProjectConfiguration");
                
                final String include = node.getAttributes().getNamedItem("Include").getNodeValue();
                
                final String configuration = GetChildSingleSubelementValue(node, "Configuration");
                final String platform = GetChildSingleSubelementValue(node, "Platform");
                assert configuration != null;
                assert platform != null;
                
                group.Add(new ProjectConfiguration(include, configuration, platform));
                
                Loagger.log(Level.INFO, "Added <ProjectConfiguration>: include={0}, configuration={1}, platform={2}", new Object[]{include, configuration, platform});
            }
        
        return group;
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitClCompileOrClIncludeElements (final String label, final String condition, final Node groupnode) {
        for (final Node node : MakeChildrenIterator(groupnode))
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                final String include = GetAttributeValue(node, "Include");
                assert include != null;
                
                switch (node.getNodeName()) {
                    case "ClCompile": {
                        final ClCompile clcompile = new ClCompile(include);

                        for (final Node child : MakeChildrenIterator(node))
                            if (child.getNodeType() == Node.ELEMENT_NODE)
                                switch (child.getNodeName()) {
                                    case "ExcludedFromBuild": {
                                        final String compilecondition = GetAttributeValue(child, "Condition");
                                        clcompile.AddExcludeFromBuildCondition(compilecondition);
                                        break;
                                    }
                                    case "PrecompiledHeader": {
                                        final String precompiledheadercondition = GetAttributeValue(child, "Condition");
                                        if (GetSingleSubelementValue(node).equals("Create"))
                                            clcompile.AddPrecompiledHeaderCreationCondition(precompiledheadercondition);
                                        break;
                                    }
                                    case "FileType":
                                    case "CompileAsManaged":
                                        // ignore
                                        break;
                                    default:
                                        Loagger.log(Level.WARNING, "Ignoring element <{0}> in <ClCompile> in group \"{1}\"", new Object[]{child.getNodeName(),label});
                                }
                        
                        Loagger.log(Level.INFO, "Adding ClCompile {0}", clcompile.GetInclude());
                        project.AddClCompile(clcompile);
                        break;
                    }
                    case "ClInclude": {
                        final ClInclude clinclude = new ClInclude(Objects.requireNonNull(GetAttributeValue(node, "Include")));
                        
                        Loagger.log(Level.INFO, "Added ClInclude={0}", clinclude.GetInclude());
                        project.AddClInclude(clinclude);
                        break;
                    }
                    default:
                        Loagger.log(Level.WARNING, "Ignoring element <{0}> in ItemGroup \"{1}\" \"{2}\"", new Object[]{node.getNodeName(), label, condition});
                }
            }
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitProjectReferences (final String label, final String condition, final Node groupnode) {
        for (final Node node : MakeChildrenIterator(groupnode))
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                assert node.getNodeName().equals("ProjectReference");
                final String relpath = GetAttributeValue(node, "Include");
                assert relpath != null;
                final String projidstr = GetChildSingleSubelementValue(node, "Project");
                assert projidstr != null;
                final ProjectGuid projid = ProjectGuidFactory.GetSingleton().Get(projidstr);
                
                Loagger.log(Level.INFO, "Adding project reference {0} {1}", new Object[]{relpath,projid});
                project.AddProjectReference(projid, relpath);
            }
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitPropertyGroup (final Node groupnode) {
        final String label = GetAttributeValueIfExists(groupnode, "Label");
        final String condition = GetAttributeValueIfExists(groupnode, "Condition");

        final Group<Property> group = new Group<>(Property.class, label, condition);
        
        for (final Node node : MakeChildrenIterator(groupnode))
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                final String id = node.getNodeName();
                final String value = GetSingleSubelementValue(node);
                
                group.Add(new Property(id, value));
                
                Loagger.log(Level.INFO, "Adding property (from group \"{0}\", condition={3}) {1}={2}", new Object[]{label,id,value,condition});
            }
        
        project.AddPropertyGroup(group);
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitImport (final Node node) {
        final String project_ = GetAttributeValue(node, "Project");
        assert project_ != null;
        
        project.AddImport(new Import(project_));
        
        Loagger.log(Level.INFO, "Added import of {0}", project_);
    }
    
    ///////////////////////////////////////////////////////

    public void VisitImportGroup (final Node groupnode) {
        final String label = GetAttributeValue(groupnode, "Label");
        assert label != null;
        final String condition = GetAttributeValueIfExists(groupnode, "Condition");
        
        final Group<Import> group = new Group<>(Import.class, label, condition);
        
        for (final Node node : MakeChildrenIterator(groupnode))
            if (node.getNodeType() == Node.ELEMENT_NODE)
                if (node.getNodeName().equals("Import")) {
                    final String project_ = GetAttributeValue(node, "Project");
                    group.Add(new Import(project_));

                    Loagger.log(Level.INFO, "Added import \"{0}\" from ImportGroup \"{1}\"", new Object[]{project_, label});
                }
                else    
                    Loagger.log(Level.WARNING, "Ignoring element {0} in ImportGroup \"{1}\"", new Object[]{node.getNodeName(), label});
                
        
        project.AddImportGroup(group);
    }
    
    ///////////////////////////////////////////////////////
    
    public void VisitItemDefinitionGroup (final Node nodegroup) {
        final String label = GetAttributeValueIfExists(nodegroup, "Label");
        final String condition = GetAttributeValueIfExists(nodegroup, "Condition");
        
        final Group<ItemDefinition> group = new Group<>(ItemDefinition.class, label, condition);
        
        for (final Node node : MakeChildrenIterator(nodegroup))
            if (node.getNodeType() == Node.ELEMENT_NODE)
                switch (node.getNodeName()) {
                    case "ClCompile":
                        group.Add(new ClCompileDefinition(
                                GetChildIfExistsSingleSubelementValue(node, "PrecompiledHeader"),
                                GetChildIfExistsSingleSubelementValue(node, "WarningLevel"),
                                GetChildIfExistsSingleSubelementValue(node, "Optimization"),
                                GetChildIfExistsSingleSubelementValue(node, "PreprocessorDefinitions"),
                                GetChildIfExistsSingleSubelementValue(node, "PrecompiledHeaderFile"),
                                GetChildIfExistsSingleSubelementValue(node, "ObjectFileName"),
                                GetChildIfExistsSingleSubelementValue(node, "FunctionLevelLinking"),
                                GetChildIfExistsSingleSubelementValue(node, "IntrinsicFunctions")));
                        break;
                    case "Link":
                        group.Add(new LinkDefinition(
                                GetChildIfExistsSingleSubelementValue(node, "SubSystem"),
                                GetChildIfExistsSingleSubelementValue(node, "GenerateDebugInformation"),
                                GetChildIfExistsSingleSubelementValue(node, "AdditionalDependencies")));
                        break;
                    case "ResourceCompile":
                        // ignore
                        break;
                    default:
                        Loagger.log(Level.WARNING, "Ignoring ItemDefinition \"{0}\" in group \"{1}\"", new Object[]{node.getNodeName(), label});
                }
        
        project.AddItemDefinitionGroup(group);
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final Project       project =   new Project();
    //
    private final static Logger Loagger =   Logger.getLogger(ProjectXmlWalker.class.getName());
    
} // class ProjectXmlWalker
