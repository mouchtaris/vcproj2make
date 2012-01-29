package jcproj.loading.vc;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.cbuild.ConfigurationIdManager;
import jcproj.loading.vc.xml.SolutionXmlWalker;
import jcproj.loading.vc.xml.XmlWalkingException;
import jcproj.vcxproj.ProjectGuidManager;
import org.xml.sax.SAXException;

/**
 *
 * @date	Sunday 7th of August 2011
 * @author	amalia
 */
@SuppressWarnings("FinalClass")
public final class SolutionLoader {

	///////////////////////////////////////////////////////

	public static ConfigurationManager LoadSolution (final InputStream solution, final ProjectGuidManager projGuidManager)
			throws
				ParserConfigurationException,
				SAXException,
				IOException,
				XmlWalkingException
	{
		final ConfigurationIdManager configIdManager = new ConfigurationIdManager();
		final SolutionXmlWalker solutionXmlWalker = new SolutionXmlWalker(configIdManager, projGuidManager);
		solutionXmlWalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(solution));
		return solutionXmlWalker.GetConfigurationManager();
	}

	///////////////////////////////////////////////////////

	public static ConfigurationManager LoadSolution (final File solution, final ProjectGuidManager projGuidManager)
			throws
				ParserConfigurationException,
				SAXException,
				IOException,
				XmlWalkingException
	{
		final ConfigurationIdManager configIdManager = new ConfigurationIdManager();
		final SolutionXmlWalker solutionXmlWalker = new SolutionXmlWalker(configIdManager, projGuidManager);
		solutionXmlWalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(solution));
		return solutionXmlWalker.GetConfigurationManager();
	}

	///////////////////////////////////////////////////////

	private SolutionLoader() {
	}


} // class SolutionLoader
