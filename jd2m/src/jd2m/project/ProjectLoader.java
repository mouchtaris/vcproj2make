package jd2m.project;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CSolution;
import jd2m.solution.ConfigurationManager;
import jd2m.solution.ProjectConfigurationEntry;
import jd2m.solution.PathResolver;
import jd2m.solution.ProjectEntry;
import jd2m.solution.ProjectEntryHolder;
import jd2m.solution.SolutionLoadedData;
import jd2m.solution.VariableEvaluator;
import jd2m.util.Name;
import jd2m.util.ProjectId;
import static jd2m.util.PathHelper.UnixifyPath;

import static jd2m.util.PathHelper.CreatePath;

public final class ProjectLoader {

    private ProjectLoader () {
    }

    /**
     *
     * @param solutionLoadedData
     * @return a mapping from solution configuration names to {@link CSolution}s
     *          for that solution configuration
     */
    public static Map<String, CSolution>
    LoadProjects (
            final SolutionLoadedData solutionLoadedData)
    {
        final Map<String, CSolution>                result   = new HashMap<String, CSolution>(5);
        final Map<ProjectId, Map<String, CProject>> projects = _loadProjectsFromProjectEntries(solutionLoadedData);

        final ConfigurationManager  configurationManger = solutionLoadedData.m();
        final String                solutionName        = solutionLoadedData.n();
        final PathResolver          pathResolver        = solutionLoadedData.r();
        final Path                  solutionDirectory   = pathResolver.GetSolutionDirectory();

        for (   final Entry<String, Map<ProjectId, ProjectConfigurationEntry>> solConfEntry:
                configurationManger.GetConfigurations().entrySet())
        {
            final String                                    solutionConfigurationName   = solConfEntry.getKey();
            final Map<ProjectId, ProjectConfigurationEntry> projectsInfos               = solConfEntry.getValue();
            final CSolution                                 csol                        = _makeSolution(solutionName,
                                                                                                        solutionDirectory,
                                                                                                        solutionConfigurationName,
                                                                                                        projectsInfos,
                                                                                                        projects);
            result.put(solutionConfigurationName, csol);
        }

        return result;
    }

    // ---------------------------------
    // Private
    /**
     *
     * @param solutionLoadedData
     * @return a mapping from a project-id to a mapping from project
     *          configuration name to a {@link CProject}
     */
    private static Map<ProjectId, Map<String, CProject>>
    _loadProjectsFromProjectEntries (
            final SolutionLoadedData solutionLoadedData)
    {
        final ProjectEntryHolder    holder      = solutionLoadedData.h();
        final VariableEvaluator     ve          = solutionLoadedData.e();
        final PathResolver          resolver    = solutionLoadedData.r();
        //
        final Map<ProjectId, Map<String, CProject>> result = new HashMap<ProjectId, Map<String, CProject>>(100);

        for (final ProjectEntry entry: holder) {
            final Path projectXmlPath   =   resolver.ProjectPath(entry);
            final ProjectId id          =   entry.GetIdentity();
            XmlAnalyserArguments args   =   new XmlAnalyserArguments(
                                                    entry.GetName(),
                                                    id,
                                                    CreatePath(projectXmlPath.toString()),
                                                    UnixifyPath(entry.GetLocation().toString()),
                                                    ve,
                                                    resolver
                                            );
            final Map<String, CProject> projectPerConfiguration = XmlAnalyser.ParseProjectXML(projectXmlPath, args);

            // Add all dependencies from the project-entry into every
            // configuration
            for (   final Entry<String, CProject> projectEntry:
                    projectPerConfiguration.entrySet())
            { // foreach project-configuration => c-project entry
                final CProject project = projectEntry.getValue();
                for (final ProjectId dep: entry.GetDependencies())
                    project.AddDependency(dep);
            }
            result.put(id, projectPerConfiguration);
        }

        return result;
    }

    private static CSolution
    _makeSolution ( final String solName,
                    final Path solutionDirectory,
                    final String configurationName,
                    final Map<ProjectId, ProjectConfigurationEntry> projectsInfos,
                    final Map<ProjectId, Map<String, CProject>> projects)
    {
        final CSolution result = new CSolution( solutionDirectory,
                                                new Name(solName),
                                                configurationName);

        for (   final Entry<ProjectId, ProjectConfigurationEntry> projectInfoEntry:
                projectsInfos.entrySet())
        {
            final ProjectId prjid = projectInfoEntry.getKey();
            //
            final ProjectConfigurationEntry _m_projInfo = projectInfoEntry.getValue();
            final boolean isBuildable = _m_projInfo.IsBuildable();
            final String projConfName = _m_projInfo.GetConfigurationName();
            //
            final Map<String, CProject> projectConfigurations =
                    projects.get(prjid);
            final CProject project = projectConfigurations.get(projConfName);
            //
            if (isBuildable)
                result.AddProject(project);
        }

        return result;
    }

}
