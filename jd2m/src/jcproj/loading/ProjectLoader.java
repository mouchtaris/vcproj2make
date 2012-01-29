package jcproj.loading;

import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.loading.xml.ProjectXmlWalker;
import jcproj.loading.xml.XmlWalkingException;
import jcproj.vcxproj.ProjectGuidManager;
import jcproj.vcxproj.xml.Project;
import org.xml.sax.SAXException;

/**
 *
 *
 * @data Sunday 7th of August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class ProjectLoader {

		///////////////////////////////////////////////////////

	public static Project LoadProject (final InputStream proj, final ProjectGuidManager projGuidManager)
			throws	ParserConfigurationException,
					SAXException,
					IOException,
					XmlWalkingException {
		final ProjectXmlWalker xmlwalker = new ProjectXmlWalker(projGuidManager);
		xmlwalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(proj));
		return xmlwalker.GetProject();
	}

	///////////////////////////////////////////////////////

	private ProjectLoader() {}

} // class ProjectLoader
