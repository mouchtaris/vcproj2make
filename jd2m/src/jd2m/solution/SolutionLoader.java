package jd2m.solution;

import java.nio.file.Path;
import static jd2m.util.PathHelper.UnixifyPath;

public final class SolutionLoader {

    private SolutionLoader () {
    }

    public static SolutionLoadedData LoadSolution (
            final Path solutionFilePath,
            final Path solutionRootDireactory,
            final String solutionTargetDirectory)
    {
        final ConfigurationManager  configurationManager    = new ConfigurationManager();
        final ProjectEntryHolder    projectEntryHolder      = new ProjectEntryHolder();
        final PathResolver          pathResolver            = new PathResolver(solutionRootDireactory, projectEntryHolder);
        final VariableEvaluator     variableEvaluator       = new VariableEvaluator(solutionTargetDirectory);// TODO make util for appending "/" to  directories

        final XmlAnalyserArguments  args                    = new XmlAnalyserArguments( configurationManager,
                                                                                        projectEntryHolder,
                                                                                        pathResolver);
        XmlAnalyser.ParseXML(solutionFilePath, args);

        final SolutionLoadedData result = new SolutionLoadedData(   configurationManager,
                                                                    projectEntryHolder,
                                                                    pathResolver,
                                                                    variableEvaluator,
                                                                    "The Solution"); // TODO get solution name from XML analysis

        return result;
    }

}
