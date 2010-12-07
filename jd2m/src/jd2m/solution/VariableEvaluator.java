package jd2m.solution;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class VariableEvaluator {
    public static final String OutDir           = "OutDir";
    public static final String ConfigurationName= "ConfigurationName";
    public static final String SolutionDir      = "SolutionDir";
    public static final String ProjectName      = "ProjectName";
    
    private final Map<String, String> _values = new HashMap<>(20);

    public VariableEvaluator (final String solutionDirectory) {
        _values.put(SolutionDir, solutionDirectory);
    }

    public void SetOutDir (final String value) {
        _values.put(OutDir, value);
    }

    public void SetConfigurationName (final String value) {
        _values.put(ConfigurationName, value);
    }

    public void SetProjectName (final String value) {
        _values.put(ProjectName, value);
    }

    public void Reset () {
        _values.remove(OutDir);
        _values.remove(ConfigurationName);
        _values.remove(ProjectName);
    }


    public String Evaluate (final String variable) {
        final String result = _values.get(variable);
        assert  result != null                  ||
                variable.equals("ACE_ROOT")     ||
                variable.equals("DELTAIDEDEPS");
        return result;
    }
    
    // ----------------------
    // ----- Utilities ------
    public String EvaluateString (final String str)
    {
        final StringBuffer sb = new StringBuffer(100);
        final Matcher m = _u_variablePattern.matcher(str);
        while (m.find()) {
            final String matchingString = m.group();
            final String variableName =
                    matchingString.substring(2, matchingString.length()-1);
            final String replacement = Evaluate(variableName);
            final String literal = Matcher.quoteReplacement(
                    replacement != null? replacement : matchingString);
            m.appendReplacement(sb, literal);
        }
        m.appendTail(sb);
        final String result = sb.toString();

        return result;
    }

    // -----------------------------------
    // Private
    private final static Pattern _u_variablePattern = Pattern.compile(
            "[\\$%]\\([a-zA-Z_]+\\)");
}
