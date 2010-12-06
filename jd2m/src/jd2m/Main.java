package jd2m;

import java.nio.file.Paths;
import jd2m.solution.SolutionLoader;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        final String pathStr = "./../deltaide2make/Solution.xml";
        SolutionLoader.LoadSolution(Paths.get(pathStr));
    }

    private Main () {
    }
}