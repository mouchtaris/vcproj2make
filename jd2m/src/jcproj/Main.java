package jcproj;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.ParserConfigurationException;
import jcproj.cbuild.ConfigurationId;
import jcproj.loading.vc.ProjectLoader;
import jcproj.loading.vc.solution.ConfigurationManager;
import jcproj.loading.vc.solution.ProjectEntry;
import jcproj.loading.vc.solution.ProjectEntryConfiguration;
import jcproj.loading.vc.solution.SolutionLoader;
import jcproj.loading.vc.xml.XmlWalkingException;
import jcproj.vcxproj.ProjectGuidManager;
import jcproj.vcxproj.xml.Project;
import org.xml.sax.SAXException;

/**
 *
 * @author amalia
 */
public class Main {

	@SuppressWarnings("UseOfSystemOutOrSystemErr")
	public static void main (final String[] args) throws ParserConfigurationException, SAXException, XmlWalkingException, IOException {
		Logger.getLogger("jcproj").setLevel(Level.INFO);
		ProjectGuidManager projGuidManager = new ProjectGuidManager();

		if (args.length == 0)
			System.out.println("solutionPathname");
		else {
			final String solutionPathname = args[0];
			final Path solutionPath = Paths.get(solutionPathname);
			final Path solutionBasedir = solutionPath.getParent();

			final ConfigurationManager confmanager;
			try {
				confmanager = SolutionLoader.LoadSolution(Files.newInputStream(solutionPath), projGuidManager);
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

			for (final Map.Entry<ConfigurationId, Map<ProjectEntry, ProjectEntryConfiguration>> configuration : confmanager.GetConfiguration().entrySet())
				for (final Map.Entry<ProjectEntry, ProjectEntryConfiguration> entryconfig: configuration.getValue().entrySet())
					try {
						projects.add(ProjectLoader.LoadProject(Files.newInputStream(solutionBasedir.resolve(entryconfig.getKey().GetRelativePath())), projGuidManager));
					} catch (final ParserConfigurationException ex) {
						throw ex;
					} catch (final SAXException ex) {
						throw ex;
					} catch (final XmlWalkingException ex) {
						throw ex;
					} catch (final IOException ex) {
						throw ex;
					}

			System.out.println(projects);
		}
	}

	private static final Logger Loagger = Logger.getLogger(Main.class.getCanonicalName());
	private Main() {
	}

}
