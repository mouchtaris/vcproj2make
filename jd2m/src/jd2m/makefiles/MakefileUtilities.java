package jd2m.makefiles;

import java.io.File;
import java.nio.file.Path;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;

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

    public static Path GetFullTargetPathForUnixProject (final CProject proj) {
        final CProjectType type = proj.GetType();
        final Path output       = proj.GetOutput();
        final String target     = proj.GetTarget();
        Path result;
        switch (type) {
            case DynamicLibrary:
                result = output.resolve("lib" + target + ".so");
                break;
            case StaticLibrary:
                result = output.resolve(target + ".a");
                break;
            case Executable:
                result = output.resolve(target);
                break;
            default:
                throw new AssertionError("wat");
        }

        return result;
    }
}
