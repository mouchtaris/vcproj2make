package jcproj.loading;

import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.vcxproj.Project;
import org.xml.sax.SAXException;

/**
 *
 * 
 * @data Sunday 7th of August 2011
 * @author amalia
 */
public final class ProjectLoader {
    
        ///////////////////////////////////////////////////////
    
    public static Project LoadProject (final InputStream proj)
            throws  ParserConfigurationException,
                    SAXException,
                    IOException {
        final ProjectXmlWalker xmlwalker = new ProjectXmlWalker();
        xmlwalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(proj));
        return xmlwalker.GetProject();
    }
    
    ///////////////////////////////////////////////////////
    
} // class ProjectLoader
