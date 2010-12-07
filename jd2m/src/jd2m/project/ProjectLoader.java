package jd2m.project;

import java.io.File;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CSolution;
import jd2m.solution.PathResolver;
import jd2m.solution.ProjectEntry;
import jd2m.solution.ProjectEntryHolder;
import jd2m.solution.SolutionLoadedData;
import jd2m.util.ProjectId;

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
        final Map<String, CSolution> result = new HashMap<>(5);
        final Map<ProjectId, Map<String, CProject>> projects =
                _loadProjectsFromProjectEntries(solutionLoadedData);
        System.out.println(projects);
        // TODO continue here
        throw new RuntimeException("Not complete");
//        return result; artificial error, because this method is not complete
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
        final ProjectEntryHolder holder = solutionLoadedData.h();
        //
        final Map<ProjectId, Map<String, CProject>> result = new HashMap<>(100);

        for (final ProjectEntry entry: holder) {
            final PathResolver resolver = solutionLoadedData.r();
            final Path projectXmlPath   = resolver.ProjectPath(entry);
            final ProjectId id          = entry.GetIdentity();
            XmlAnalyserArguments args   =
                    new XmlAnalyserArguments(entry.GetName(), id,
                            new File(projectXmlPath.toString()));
            final Map<String, CProject> projectPerConfiguration =
                    XmlAnalyser.ParseProjectXML(projectXmlPath, args);

            result.put(id, projectPerConfiguration);
        }

        return result;
    }
}
