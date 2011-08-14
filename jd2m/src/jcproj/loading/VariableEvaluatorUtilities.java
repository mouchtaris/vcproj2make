package jcproj.loading;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *
 * @date (of refactoring other things into here) 14th of August 2011
 * @author muhtaris
 */
public final class VariableEvaluatorUtilities {
    
    ///////////////////////////////////////////////////////
    public static String EvaluateString (final VariableEvaluator evaluator, final String str)
    {
        final StringBuffer sb = new StringBuffer(100);
        final Matcher m = VariablePatter.matcher(str);
        while (m.find()) {
            final String matchingString = m.group();
            final String variableName = matchingString.substring(2, matchingString.length()-1);
            final String replacement = evaluator.Evaluate(variableName);
            final String literal = Matcher.quoteReplacement(replacement != null? replacement : matchingString);
            m.appendReplacement(sb, literal);
        }
        m.appendTail(sb);
        final String result = sb.toString();

        assert result != null;
        return result;
    }
    
    
    ///////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////
    // Private
    private VariableEvaluatorUtilities () {
    }
    
    ///////////////////////////////////////////////////////
    // One-time instances
    
    private final static Pattern VariablePatter = Pattern.compile("[\\$%]\\([a-zA-Z_]+\\)");
    
}
