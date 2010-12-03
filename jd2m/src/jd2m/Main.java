package jd2m;

import static jd2m.solution.XmlAnalyser.ParseXML;
import static jd2m.project.XmlAnalyser.ParseProjectXML;
import jd2m.cbuild.CProject;
import jd2m.solution.SolutionLoadedData;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        SolutionLoadedData data = ParseXML("./../deltaide2make/Solution.xml");
    }

    private Main () {
    }
}