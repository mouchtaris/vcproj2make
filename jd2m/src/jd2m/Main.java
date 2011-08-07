package jd2m;

import java.io.IOException;
import java.util.Map.Entry;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import jd2m.cbuild.CSolution;
import jd2m.project.ProjectLoader;
import jd2m.solution.SolutionLoader;

import static jd2m.makefiles.CSolutionConverter.GenerateMakefelesFromCSolution;
import static jd2m.cbuild.CPropertiesTransformationApplicator.ApplyToSolution;

public class Main {

    public static void main (final String[] args) throws Throwable {
        MakeMakefiles(args);
    }

    public static void MakeMakefiles (final String[] args) throws IOException {
        SetupLoggers();
        
        System.out.println("hi')");
        final Path solutionFilePath = Paths.get(
//                "./../deltaide2make/Solution.xml"
                args[0]
        );
        final Path solutionRoot     = Paths.get(
//                "C:\\Users\\TURBO_X\\Documents\\uni\\UOC\\CSD\\thesis_new\\deltaide\\IDE"
//                "/home/muhtaris/deltux/svn_deltaide/IDE"
//                "/tmp/deltaide/IDE/"
                args[1]
        );
        final String solutionTargetDirectory = args[2];
        Map<String, CSolution> solutions =
                ProjectLoader.LoadProjects(
                        SolutionLoader.LoadSolution(solutionFilePath,
                                                    solutionRoot,
                                                    solutionTargetDirectory)
                );

        final WxLibrariesCPropertiesTrasformation trans =
                new WxLibrariesCPropertiesTrasformation();

        for (final Entry<String, CSolution> solutionentry: solutions.entrySet())
        {
            final CSolution csolution = solutionentry.getValue();
            ApplyToSolution(trans, csolution);
            
            GenerateMakefelesFromCSolution(csolution, "Blibliblo");
        }

        new WindowsSourcesConvertTask(solutionRoot).DoConversion();
        new EvilFilesRemoverTask(solutionRoot).DoKilling();
    }

    private static void SetupLoggers() {
        final Logger jd2mLogger = Logger.getLogger("jd2m");
        jd2mLogger.setLevel(Level.INFO);
    }

    private Main () {
    }

    private static final String HELP = ""
            + "command solutionFilePath solutionRoot";

    public static class help {
        public static void main (final String[] args) {
            System.out.println(HELP);
        }
    }
}