package jd2m.makefiles;

public final class MakefileUtilities {

    private MakefileUtilities () {
    }

    private static final StringBuilder SB = new StringBuilder(1 << 14);
    private static void _resetSB () {
        SB.delete(0, SB.length());
    }

    public static String ShellEscape (final String line) {
        _resetSB();

        SB.append('\'');
        SB.append(line.replaceAll("'", "'\\'"));
        SB.append('\'');

        return SB.toString();
    }

    public static String MakeEscape (final String line) {
        final String level0 = line.replaceAll("#", "\\#");
        final String level1 = level0.replaceAll("\\$", "$$");
        final String result = level1;
        return result;
    }
}
