package jcproj.loading;

import jcproj.loading.xml.SolutionXmlWalker;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.loading.xml.XmlWalkingException;
import org.xml.sax.SAXException;

/**
 *
 * @date    Sunday 7th of August 2011
 * @author  amalia
 */
@SuppressWarnings("FinalClass")
public final class SolutionLoader {

    ///////////////////////////////////////////////////////
    
    public static ConfigurationManager LoadSolution (final InputStream solution)
            throws
            ParserConfigurationException,
            SAXException,
            IOException, 
            XmlWalkingException
    {
        final SolutionXmlWalker solutionXmlWalker = new SolutionXmlWalker();
        solutionXmlWalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(solution));
        return solutionXmlWalker.GetConfigurationManager();
    }
    
    ///////////////////////////////////////////////////////
    
    public static ConfigurationManager LoadSolution (final File solution)
            throws  ParserConfigurationException,
                    SAXException,
                    IOException, 
                    XmlWalkingException
    {
        final SolutionXmlWalker solutionXmlWalker = new SolutionXmlWalker();
        solutionXmlWalker.VisitDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(solution));
        return solutionXmlWalker.GetConfigurationManager();
    }
    
    ///////////////////////////////////////////////////////

    private SolutionLoader() {
    }
    
    
} // class SolutionLoader
