package jd2m;

import jd2m.solution.ConfigurationManager;
import jd2m.solution.SolutionLoadedData;
import static jd2m.solution.XmlAnalyser.ParseXML;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        SolutionLoadedData data =
                ParseXML("./../deltaide2make/Solution.xml");
    }

    private Main () {
    }
}