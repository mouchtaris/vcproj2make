package jd2m.solution;

import java.nio.file.Path;

public final class SolutionLoader {

    private SolutionLoader () {
    }

    public static SolutionLoadedData LoadSolution (final Path solutionPath) {
        final ConfigurationManager configurationManager =
                new ConfigurationManager();
        final ProjectEntryHolder projectEntryHolder =
                new ProjectEntryHolder();
        final PathResolver pathResolver =
                new PathResolver(solutionPath, projectEntryHolder);
        XmlAnalyser.ParseXML(   solutionPath,
                                configurationManager,
                                projectEntryHolder);

        final SolutionLoadedData result =
                new SolutionLoadedData( configurationManager,
                                        projectEntryHolder,
                                        pathResolver);

        return result;
    }

}
