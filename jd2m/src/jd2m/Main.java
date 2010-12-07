package jd2m;

import java.nio.file.Path;
import java.nio.file.Paths;
import jd2m.project.ProjectLoader;
import jd2m.solution.SolutionLoader;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        final Path solutionFilePath = Paths.get("./../deltaide2make/Solution.xml");
        final Path solutionRoot     = Paths.get("C:\\Users\\TURBO_X\\Documents\\uni\\UOC\\CSD\\thesis_new\\deltaide\\IDE");
        ProjectLoader.LoadProjects(SolutionLoader.LoadSolution(solutionFilePath,
                                                               solutionRoot));
    }

    private Main () {
    }
}