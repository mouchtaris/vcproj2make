package jcproj.loading.vc.xml;

import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.vcxproj.ProjectGuid;
import jcproj.vcxproj.ProjectGuidManager;
import jcproj.vcxproj.xml.ClCompile;
import jcproj.vcxproj.xml.ClCompileDefinition;
import jcproj.vcxproj.xml.ClInclude;
import jcproj.vcxproj.xml.Group;
import jcproj.vcxproj.xml.Import;
import jcproj.vcxproj.xml.ItemDefinition;
import jcproj.vcxproj.xml.LibDefinition;
import jcproj.vcxproj.xml.LinkDefinition;
import jcproj.vcxproj.xml.PostBuildEvent;
import jcproj.vcxproj.xml.PreBuildEvent;
import jcproj.vcxproj.xml.Project;
import jcproj.vcxproj.xml.ProjectConfiguration;
import jcproj.vcxproj.xml.Property;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static jcproj.util.xml.XmlTreeVisitor.GetAttributeValue;
import static jcproj.util.xml.XmlTreeVisitor.GetAttributeValueIfExists;
import static jcproj.util.xml.XmlTreeVisitor.GetChildIfExistsSingleSubelementValue;
import static jcproj.util.xml.XmlTreeVisitor.GetChildSingleSubelementValue;
import static jcproj.util.xml.XmlTreeVisitor.GetSingleSubelementValue;
import static jcproj.util.xml.XmlTreeVisitor.MakeChildrenIterator;

/**
 *
 *
 * @data Sunday 7th of August 2011
 * @author amalia
 */
public class ProjectXmlWalker {

	private interface AttributeName {
		public static final String Include			= "Include";
		public static final String Configuration	= "Configuration";
		public static final String Platform			= "Platform";
		public static final String Condition		= "Condition";
		public static final String Label			= "Label";
	}

	///////////////////////////////////////////////////////

	public Project GetProject () {
		return project;
	}

	///////////////////////////////////////////////////////

	public void VisitDocument (final Node document) throws XmlWalkingException {
		VisitRoot(document.getFirstChild());
	}

	///////////////////////////////////////////////////////

	public void VisitRoot (final Node root) throws XmlWalkingException {
		final NamedNodeMap attrs = root.getAttributes();

		assert root.getNodeName().equals("Project");
		assert attrs.getNamedItem("DefaultTargets").getNodeValue().equals("Build");
		assert attrs.getNamedItem("ToolsVersion").getNodeValue().equals("4.0");
		assert attrs.getNamedItem("xmlns").getNodeValue().equals("http://schemas.microsoft.com/developer/msbuild/2003");

		for (final Node node : MakeChildrenIterator(root))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				final String nodename = node.getNodeName();
				if (nodename.equals(NodesNames.ItemGroup))
					VisitItemGroup(node);
				else
				if (nodename.equals(NodesNames.PropertyGroup))
					VisitPropertyGroup(node);
				else
				if (nodename.equals(NodesNames.Import))
					VisitImport(node);
				else
				if (nodename.equals(NodesNames.ImportGroup))
					VisitImportGroup(node);
				else
				if (nodename.equals(NodesNames.ItemDefinitionGroup))
					VisitItemDefinitionGroup(node);
				else
					throw new XmlWalkingException(root, node);
			}
	}

	///////////////////////////////////////////////////////

	public void VisitItemGroup (final Node group) throws XmlWalkingException {
		final String label = GetAttributeValueIfExists(group, "Label");
		final String condition = GetAttributeValueIfExists(group, "Condition");

		// Dispatch according to the first item. The rest are supposed to be the same
		for (final Node node : MakeChildrenIterator(group))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				final String nodename = node.getNodeName();
				if (nodename.equals(NodesNames.ProjectConfiguration))
					project.AddItemGroup(MakeProjectConfigurationsItemGroup(label, condition, group));
				else
				if (nodename.equals(NodesNames.ClCompile) ||
					nodename.equals(NodesNames.ClInclude))
					VisitClCompileOrClIncludeElements(label, condition, group);
				else
				if (nodename.equals(NodesNames.ProjectReference))
					VisitProjectReferences(label, condition, group);
				else
				if (nodename.equals(NodesNames.ResourceCompile)||
					nodename.equals(NodesNames.None))
					// ignore
					{}
				else
					throw new XmlWalkingException(group, node);
				break;
			}
	}

	///////////////////////////////////////////////////////

	public Group<ProjectConfiguration> MakeProjectConfigurationsItemGroup (final String label, final String condition, final Node groupnode) {
		final Group<ProjectConfiguration> group = new Group<ProjectConfiguration>(ProjectConfiguration.class, label, condition);

		for (final Node node : MakeChildrenIterator(groupnode))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				assert NodesNames.ProjectConfiguration.equals(node.getNodeName());

				final String include = node.getAttributes().getNamedItem(AttributeName.Include).getNodeValue();

				final String configuration = GetChildSingleSubelementValue(node, AttributeName.Configuration);
				final String platform = GetChildSingleSubelementValue(node, AttributeName.Platform);
				assert configuration != null;
				assert platform != null;

				group.Add(new ProjectConfiguration(include, configuration, platform));

				Loagger.log(Level.INFO, "Added <ProjectConfiguration>: include={0}, configuration={1}, platform={2}", new Object[]{include, configuration, platform});
			}

		return group;
	}

	///////////////////////////////////////////////////////

	public void VisitClCompileOrClIncludeElements (final String label, final String condition, final Node groupnode) throws XmlWalkingException{
		for (final Node node : MakeChildrenIterator(groupnode))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				final String include = GetAttributeValue(node, AttributeName.Include);
				assert include != null;

				final String nodename = node.getNodeName();
				if (nodename.equals(NodesNames.ClCompile)) {
					final ClCompile clcompile = new ClCompile(include);

					for (final Node child : MakeChildrenIterator(node))
						if (child.getNodeType() == Node.ELEMENT_NODE) {
							final String childnodename = child.getNodeName();
							if (childnodename.equals(NodesNames.ExcludedFromBuild)) {
								final String compilecondition = GetAttributeValue(child, AttributeName.Condition);
								clcompile.AddExcludeFromBuildCondition(compilecondition);
								break;
							}
							else
							if (childnodename.equals(NodesNames.PrecompiledHeader)) {
								final String precompiledheadercondition = GetAttributeValue(child, AttributeName.Condition);
								if (GetSingleSubelementValue(node).equals("Create"))
									clcompile.AddPrecompiledHeaderCreationCondition(precompiledheadercondition);
								break;
							}
							else
							if (childnodename.equals(NodesNames.FileType) ||
								childnodename.equals(NodesNames.CompileAsManaged))
								// ignore
							{}
							else
								throw new XmlWalkingException(node, child);
						}

					Loagger.log(Level.INFO, "Adding ClCompile {0}", clcompile.GetInclude());
					project.AddClCompile(clcompile);
					break;
				}
				else
				if (nodename.equals(NodesNames.ClInclude)) {
					final ClInclude clinclude = new ClInclude(Objects.requireNonNull(GetAttributeValue(node, AttributeName.Include)));

					Loagger.log(Level.INFO, "Added ClInclude={0}", clinclude.GetInclude());
					project.AddClInclude(clinclude);
					break;
				}
				else
					throw new XmlWalkingException(groupnode, node);
			}
	}

	///////////////////////////////////////////////////////

	public void VisitProjectReferences (final String label, final String condition, final Node groupnode) {
		for (final Node node : MakeChildrenIterator(groupnode))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				assert node.getNodeName().equals(NodesNames.ProjectReference);
				final String relpath = GetAttributeValue(node, AttributeName.Include);
				assert relpath != null;
				final String projidstr = GetChildSingleSubelementValue(node, NodesNames.Project);
				assert projidstr != null;
				final ProjectGuid projid = projGuidManager.Get(projidstr);

				Loagger.log(Level.INFO, "Adding project reference {0} {1}", new Object[]{relpath,projid});
				project.AddProjectReference(projid, relpath);
			}
	}

	///////////////////////////////////////////////////////

	public void VisitPropertyGroup (final Node groupnode) {
		final String label = GetAttributeValueIfExists(groupnode, AttributeName.Label);
		final String condition = GetAttributeValueIfExists(groupnode, AttributeName.Condition);

		final Group<Property> group = new Group<Property>(Property.class, label, condition);

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
		final String project_ = GetAttributeValue(node, NodesNames.Project);
		assert project_ != null;

		project.AddImport(new Import(project_));

		Loagger.log(Level.INFO, "Added import of {0}", project_);
	}

	///////////////////////////////////////////////////////

	public void VisitImportGroup (final Node groupnode) throws XmlWalkingException {
		final String label = GetAttributeValue(groupnode, AttributeName.Label);
		assert label != null;
		final String condition = GetAttributeValueIfExists(groupnode, AttributeName.Condition);

		final Group<Import> group = new Group<Import>(Import.class, label, condition);

		for (final Node node : MakeChildrenIterator(groupnode))
			if (node.getNodeType() == Node.ELEMENT_NODE)
				if (NodesNames.Import.equals(node.getNodeName())) {
					final String project_ = GetAttributeValue(node, NodesNames.Project);
					group.Add(new Import(project_));

					Loagger.log(Level.INFO, "Added import \"{0}\" from ImportGroup \"{1}\"", new Object[]{project_, label});
				}
				else
					throw new XmlWalkingException(groupnode, node);


		project.AddImportGroup(group);
	}

	///////////////////////////////////////////////////////

	public void VisitItemDefinitionGroup (final Node nodegroup) throws XmlWalkingException {
		final String label = GetAttributeValueIfExists(nodegroup, AttributeName.Label);
		final String condition = GetAttributeValueIfExists(nodegroup, AttributeName.Condition);

		final Group<ItemDefinition> group = new Group<ItemDefinition>(ItemDefinition.class, label, condition);

		for (final Node node : MakeChildrenIterator(nodegroup))
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				final String nodename = node.getNodeName();
				if (nodename.equals(NodesNames.ClCompile))
					group.Add(new ClCompileDefinition(
							GetChildIfExistsSingleSubelementValue(node, NodesNames.PrecompiledHeader),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.WarningLevel),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.Optimization),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.PreprocessorDefinitions),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.PrecompiledHeaderFile),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.ObjectFileName),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.FunctionLevelLinking),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.IntrinsicFunctions)));
				else
				if (nodename.equals(NodesNames.Link))
					group.Add(new LinkDefinition(
							GetChildIfExistsSingleSubelementValue(node, NodesNames.SubSystem),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.GenerateDebugInformation),
							GetChildIfExistsSingleSubelementValue(node, NodesNames.AdditionalDependencies)));
				else
				if (nodename.equals(NodesNames.Lib))
					group.Add(new LibDefinition(
							GetChildIfExistsSingleSubelementValue(node, NodesNames.AdditionalLibraryDirectories)));
				else
				if (nodename.equals(NodesNames.PostBuildEvent))
					group.Add(new PostBuildEvent(
							GetChildIfExistsSingleSubelementValue(node, NodesNames.Command)));
				else
				if (nodename.equals(NodesNames.PreBuildEvent))
					group.Add(new PreBuildEvent(
							GetChildIfExistsSingleSubelementValue(node, NodesNames.Command)));
				else
				if (nodename.equals(NodesNames.ResourceCompile) ||
						nodename.equals(NodesNames.Midl) ||
						nodename.equals(NodesNames.Bscmake))
					// ignore
					{}
				else
					throw new XmlWalkingException(nodegroup, node);
			}

		project.AddItemDefinitionGroup(group);
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// constructors
	public ProjectXmlWalker (final ProjectGuidManager projGuidManager) {
		this.projGuidManager = projGuidManager;
	}

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final Project				project =	new Project();
	private final ProjectGuidManager	projGuidManager;
	//
	private final static Logger Loagger =	Logger.getLogger(ProjectXmlWalker.class.getName());

} // class ProjectXmlWalker
