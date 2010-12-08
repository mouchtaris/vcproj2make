package jd2m;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import jd2m.cbuild.CSolution;
import jd2m.project.ProjectLoader;
import jd2m.solution.SolutionLoader;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        final Path solutionFilePath = Paths.get("./../deltaide2make/Solution.xml");
        final Path solutionRoot     = Paths.get(
//                "C:\\Users\\TURBO_X\\Documents\\uni\\UOC\\CSD\\thesis_new\\deltaide\\IDE"
                "/home/muhtaris/deltux/svn_deltaide/IDE"
        );
        Map<String, CSolution> solutions =
                ProjectLoader.LoadProjects(
                        SolutionLoader.LoadSolution(solutionFilePath,
                                                    solutionRoot)
                );
        System.out.println(solutions);
    }

    private Main () {
    }
}