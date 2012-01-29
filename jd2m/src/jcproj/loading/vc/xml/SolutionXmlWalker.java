package jcproj.loading.vc.xml;

import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.cbuild.ConfigurationId;
import jcproj.cbuild.ConfigurationIdManager;
import jcproj.loading.vc.solution.ConfigurationManager;
import jcproj.loading.vc.solution.ProjectEntry;
import jcproj.loading.vc.solution.ProjectEntryConfiguration;
import jcproj.loading.vc.solution.ProjectEntryManager;
import jcproj.util.Patterns;
import jcproj.util.Predicate;
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

	public void VisitProjectConfigurationPlatforms (final Node projConfPlats) throws XmlWalkingException {
		for (Node pair : MakeChildrenIterator(projConfPlats))
			if (pair.getNodeType() == Node.ELEMENT_NODE)
				try {
					final String left = GetPairLeft(pair);
					final String[] lefts = Patterns.Dot().split(left, 0);
					if (lefts.length == 4) {
						assert lefts[2].equals("Build");
						assert lefts[3].equals("0");

						final ProjectGuid	projid	= projGuidManager.Get(lefts[0]);
						final ProjectEntry	entry	= GetEntry(projid);

						if (isIgnorable.HoldsFor(entry))
							Loagger.log(Level.INFO, "Ignoring entry {0}", entry);
						else {
							final ConfigurationId	solconfigid		= configIdManager.Get(ConfigurationId.ParseToId(GetPairRight(pair)));
							final ConfigurationId	projconfigid	= configIdManager.Get(lefts[1]);
							manager.RegisterProjectEntryUnder(solconfigid, entry, new ProjectEntryConfiguration(true, projconfigid));
						}
					}
				}
				catch (final RuntimeException ex) {
					throw new XmlWalkingException(pair, ex);
				}
	}

	///////////////////////////////////////////////////////

	public void VisitProject (final Node node) {
		final NamedNodeMap attrs = node.getAttributes();
		RegisterEntry(CreateEntry(attrs.getNamedItem("id").getNodeValue(), attrs.getNamedItem("path").getNodeValue()));
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// Accessors

	public ConfigurationManager GetConfigurationManager () {
		return manager;
	}

	///////////////////////////////////////////////////////
	// state
	private final ConfigurationManager		manager = new ConfigurationManager();
	private final ProjectEntryManager		entries = new ProjectEntryManager();
	private final ConfigurationIdManager	configIdManager;
	private final ProjectGuidManager		projGuidManager;
	private final Predicate<ProjectEntry>	isIgnorable;

	///////////////////////////////////////////////////////
	// constructors
	public SolutionXmlWalker (
			final ConfigurationIdManager	configIdManager,
			final ProjectGuidManager		projGuidManager,
			final Predicate<ProjectEntry>	isIgnorable) {
		this.configIdManager	= configIdManager;
		this.projGuidManager	= projGuidManager;
		this.isIgnorable		= isIgnorable;
	}

	///////////////////////////////////////////////////////
	// Private
	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// static utils
	private static final Logger Loagger = Logger.getLogger(SolutionXmlWalker.class.getCanonicalName());

	///////////////////////////////////////////////////////
	// Useful tracking of special events
	private ProjectEntry GetEntry (final ProjectGuid projguid) {
		return entries.Get(projguid);
	}

	private void RegisterEntry (final ProjectEntry entry) {
		entries.Register(entry);
	}

	private ProjectEntry CreateEntry (final String id, final String relpath) {
		return new ProjectEntry(projGuidManager.Create(id), relpath);
	}

} // class SolutionXmlWalker
