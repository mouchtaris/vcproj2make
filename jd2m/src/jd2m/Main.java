package jd2m;

import static jd2m.solution.XmlAnalyser.ParseXML;
import static jd2m.project.XmlAnalyser.ParseProjectXML;
import jd2m.cbuild.CProject;
import jd2m.solution.SolutionLoadedData;

public class Main {
    public static void main (final String[] args) {
        System.out.println("hi')");
        switch (1) {
            case 0:
                SolutionLoadedData data =
                        ParseXML("./../deltaide2make/Solution.xml");
                break;

            case 1:
                CProject ParseProjectXML =
                        ParseProjectXML("../../../../thesis_new/deltaide/Base/BaseLibrary/BaseLibrary.vcproj");
                break;
        }
    }

    private Main () {
    }
}