/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jcproj;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.loading.ConfigurationManager;
import jcproj.loading.ProjectConfigurationEntry;
import jcproj.loading.ProjectLoader;
import jcproj.loading.SolutionLoader;
import jcproj.vcxproj.Project;
import jcproj.vcxproj.ProjectGuidFactory;

/**
 *
 * @author TURBO_X
 */
public class Main {
    
    public static void main (final String[] args) throws Throwable {
        Logger.getLogger("jcproj").setLevel(Level.WARNING);
        ProjectGuidFactory.SingletonCreate();
        
        final String solutionPathname = args[0];
        final Path solutionPath = Paths.get(solutionPathname);
        assert Files.exists(solutionPath);
        assert Files.isRegularFile(solutionPath);
        final Path solutionBasedir = solutionPath.getParent();
        
        final ConfigurationManager confmanager = SolutionLoader.LoadSolution(Files.newInputStream(solutionPath));
        
        final List<Project> projects = new LinkedList<>();
        
        for (final Map.Entry<String, Set<ProjectConfigurationEntry>> entries : confmanager.GetProjectConfigurationEntries().entrySet())
            for (final ProjectConfigurationEntry entry : entries.getValue())
                projects.add(ProjectLoader.LoadProject(Files.newInputStream(solutionBasedir.resolve(entry.GetRelativePath()))));
        
        System.out.println(projects);
    }
    
}
