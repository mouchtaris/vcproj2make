package jcproj.loading.vc.xml;

import java.util.HashMap;
import java.util.Map;
import jcproj.cbuild.ConfigurationId;
import jcproj.cbuild.ConfigurationIdManager;
import jcproj.loading.vc.solution.ConfigurationManager;
import jcproj.loading.vc.solution.ProjectConfigurationEntry;
import jcproj.util.Patterns;
import jcproj.util.xml.XmlTreeVisitor;
import jcproj.vcxproj.ProjectGuid;
import jcproj.vcxproj.ProjectGuidManager;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static jcproj.util.xml.XmlTreeVisitor.GetPairLeft;
import static jcproj.util.xml.XmlTreeVisitor.GetPairRight;
import static jcproj.util.xml.XmlTreeVisitor.GetPairValue;
import static jcproj.util.xml.XmlTreeVisitor.MakeChildrenIterator;

/**
 *
 * @date Sunday 7th August 2011
 * @author amalia
 */
public class SolutionXmlWalker {

	///////////////////////////////////////////////////////

	public void VisitDocument (final Node doc) throws XmlWalkingException {
		VisitRoot(doc.getFirstChild());
	}

	///////////////////////////////////////////////////////

	public void VisitRoot (final Node root) throws XmlWalkingException {
		assert root.getNodeName().equals("VisualStudioSolution");

		boolean visitedGlobal = false;

		for (Node child : MakeChildrenIterator(root))
			if (child.getNodeType() == Node.ELEMENT_NODE) {
				final String childnodename = child.getNodeName();
				if (childnodename.equals("Project"))
					VisitProject(child);
				else
				if (childnodename.equals("Global")) {
					assert !visitedGlobal;
					visitedGlobal = true;
					VisitGlobal(child);
				}
				else
					throw new XmlWalkingException(root, child);
			}
	}

	///////////////////////////////////////////////////////

	public void VisitGlobal (final Node global) throws XmlWalkingException {
		assert global.getNodeType() == Node.ELEMENT_NODE;
		assert global.getNodeName().equals("Global");


		boolean visitedSolutions			= false;
		boolean visitedProjects				= false;
		boolean visitedSolutionProperties	= false;

		for (Node node : MakeChildrenIterator(global))
			if (node.getNodeName().equals("GlobalSection")) {
				final String type = node.getAttributes().getNamedItem("type").getNodeValue();
				if (type.equals("SolutionConfigurationPlatforms")) {
					assert !visitedSolutions;
					visitedSolutions = true;
					VisitSolutionConfigurationPlatforms(node);
				}
				else
				if (type.equals("ProjectConfigurationPlatforms")) {
					assert !visitedProjects;
					visitedProjects = true;
					VisitProjectConfigurationPlatforms(node);
				}
				else
				if (type.equals("SolutionProperties")) {
					assert !visitedSolutionProperties;
					visitedSolutionProperties = true;
					VisitSolutionProperties(node);
				}
				else
				if (type.equals("NestedProjects"))
					// tots ignors
					{}
				else
					throw new XmlWalkingException(global, node);
			}

		assert visitedSolutions && visitedProjects;
	}

	///////////////////////////////////////////////////////

	public void VisitSolutionProperties (final Node solProps) throws XmlWalkingException {
		// typical ignorer
		for (Node pair : MakeChildrenIterator(solProps))
			if (pair.getNodeType() == Node.ELEMENT_NODE) {
				final String left = XmlTreeVisitor.GetPairLeft(pair);
				if (left.equals("HideSolutionNode"))
						// ignore
					{}
				else
					throw new XmlWalkingException(solProps, pair);
			}
	}

	///////////////////////////////////////////////////////

	public void VisitSolutionConfigurationPlatforms (final Node solConfPlats) {
		for (Node pair : MakeChildrenIterator(solConfPlats))
			if (pair.getNodeType() == Node.ELEMENT_NODE)
				manager.RegisterSolutionConfiguration(configIdManager.Register(ConfigurationId.Parse(GetPairValue(pair))));
	}

	///////////////////////////////////////////////////////

	public void VisitProjectConfigurationPlatforms (final Node projConfPlats) {
		for (Node pair : MakeChildrenIterator(projConfPlats))
			if (pair.getNodeType() == Node.ELEMENT_NODE) {
				final String left = GetPairLeft(pair);
				final ConfigurationId solconfigid = configIdManager.Get(ConfigurationId.ParseToId(GetPairRight(pair)));

				final String[] lefts = Patterns.Dot().split(left, 0);
				if (lefts.length == 4) {
					assert lefts[2].equals("Build");
					assert lefts[3].equals("0");

					final ProjectGuid	projid			= projGuidManager.Get(lefts[0]);
					final String		projconfigid	= lefts[1];

					manager.RegisterProjectEntryUnder(solconfigid, entries.get(projid).clone(projconfigid, true));
				}
			}
	}

	///////////////////////////////////////////////////////

	public void VisitProject (final Node node) {
		final NamedNodeMap attrs = node.getAttributes();
		final ProjectGuid projid = projGuidManager.Create(attrs.getNamedItem("id").getNodeValue());
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
	// state
	private final ConfigurationManager							manager = new ConfigurationManager();
	private final Map<ProjectGuid, ProjectConfigurationEntry>	entries = new HashMap<ProjectGuid, ProjectConfigurationEntry>(100);
	private final ConfigurationIdManager						configIdManager;
	private final ProjectGuidManager							projGuidManager;

	///////////////////////////////////////////////////////
	// constructors
	public SolutionXmlWalker (
			final ConfigurationIdManager	configIdManager,
			final ProjectGuidManager		projGuidManager) {
		this.configIdManager	= configIdManager;
		this.projGuidManager	= projGuidManager;
	}

} // class SolutionXmlWalker
