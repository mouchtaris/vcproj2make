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

public class Main {
    public static void main (final String[] args) throws IOException {
        SetupLoggers();
        
        System.out.println("hi')");
        final Path solutionFilePath = Paths.get("./../deltaide2make/Solution.xml");
        final Path solutionRoot     = Paths.get(
//                "C:\\Users\\TURBO_X\\Documents\\uni\\UOC\\CSD\\thesis_new\\deltaide\\IDE"
//                "/home/muhtaris/deltux/svn_deltaide/IDE"
                "/tmp/deltaide/IDE/"
        );
        Map<String, CSolution> solutions =
                ProjectLoader.LoadProjects(
                        SolutionLoader.LoadSolution(solutionFilePath,
                                                    solutionRoot)
                );

        for (final Entry<String, CSolution> solutionentry: solutions.entrySet())
            GenerateMakefelesFromCSolution( solutionentry.getValue(),
                                            "Blibliblo");
    }

    private static void SetupLoggers() {
        final Logger jd2mLogger = Logger.getLogger("jd2m");
        jd2mLogger.setLevel(Level.SEVERE);
    }

    private Main () {
    }
}