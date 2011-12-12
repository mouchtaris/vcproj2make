package jcproj;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.loading.ConfigurationManager;
import jcproj.loading.ProjectConfigurationEntry;
import jcproj.loading.ProjectLoader;
import jcproj.loading.SolutionLoader;
import jcproj.loading.xml.XmlWalkingException;
import jcproj.vcxproj.xml.Project;
import jcproj.vcxproj.ProjectGuidFactory;
import org.xml.sax.SAXException;

/**
 *
 * @author amalia
 */
public class Main {
    
	@SuppressWarnings("UseOfSystemOutOrSystemErr")
    public static void main (final String[] args) {
        Logger.getLogger("jcproj").setLevel(Level.INFO);
        ProjectGuidFactory.SingletonCreate();
        
        if (args.length == 0)
            System.out.println("solutionPathname");
        else {
            final String solutionPathname = args[0];
            final Path solutionPath = Paths.get(solutionPathname);
            final Path solutionBasedir = solutionPath.getParent();

            final ConfigurationManager confmanager;
            try {
                confmanager = SolutionLoader.LoadSolution(Files.newInputStream(solutionPath));
            } catch (ParserConfigurationException ex) {
                Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                return;
            } catch (SAXException ex) {
                Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                return;
            } catch (XmlWalkingException ex) {
                Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                return;
            } catch (IOException ex) {
                Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                return;
            }

            final List<Project> projects = new LinkedList<Project>();

            for (final Map.Entry<String, Set<ProjectConfigurationEntry>> entries : confmanager.GetProjectConfigurationEntries().entrySet())
                for (final ProjectConfigurationEntry entry : entries.getValue())
                    try {
                        projects.add(ProjectLoader.LoadProject(Files.newInputStream(solutionBasedir.resolve(entry.GetRelativePath()))));
                    } catch (final ParserConfigurationException ex) {
                        Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (final SAXException ex) {
                        Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (final XmlWalkingException ex) {
                        Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (final IOException ex) {
                        Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
                    }

            System.out.println(projects);
        }
    }

    private Main() {
    }
    
}
