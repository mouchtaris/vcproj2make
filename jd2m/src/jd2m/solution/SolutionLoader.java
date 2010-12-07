package jd2m.solution;

import java.nio.file.Path;

public final class SolutionLoader {

    private SolutionLoader () {
    }

    public static SolutionLoadedData LoadSolution (
            final Path solutionFilePath,
            final Path solutionRootDireactory)
    {
        final ConfigurationManager configurationManager =
                new ConfigurationManager();
        final ProjectEntryHolder projectEntryHolder =
                new ProjectEntryHolder();
        final PathResolver pathResolver =
                new PathResolver(solutionRootDireactory, projectEntryHolder);
        final VariableEvaluator variableEvaluator =
                new VariableEvaluator(solutionRootDireactory.toString());
        final XmlAnalyserArguments args =
                new XmlAnalyserArguments(   configurationManager,
                                            projectEntryHolder,
                                            pathResolver);
        XmlAnalyser.ParseXML(solutionFilePath, args);

        final SolutionLoadedData result =
                new SolutionLoadedData( configurationManager,
                                        projectEntryHolder,
                                        pathResolver,
                                        variableEvaluator);

        return result;
    }

}
