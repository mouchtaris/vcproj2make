package jd2m.makefiles;

import java.io.BufferedOutputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import jd2m.cbuild.CProject;

import static jd2m.makefiles.MakefileUtilities.ShellEscape;

/**
 * Converts a {@link jd2m.cbuild.CProject} to a makefile.
 * @author muhtaris
 */
public final class CProjectConverter {

    private static final String CPPFLAGS    = "CPPFLAGS";
    private static final String LDFLAGS     = "LDFLAGS";

    private static final String DefinitionPrefix                    = "-D";
    private static final String InclusionPrefix                     = "-I";
    private static final String AdditionalLibraryDirectoryPrefix    = "-L";

    
    public static void GenerateMakefileFromCProject (   final OutputStream outs,
                                                        final CProject project)
    {
        final PrintStream out = new PrintStream(new BufferedOutputStream(outs));

        _writeHeader(out, project);
        _writeFlags(out, project);

        out.flush();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private static void _writeHeader (  final PrintStream out,
                                        final CProject project)
    {
        out.println("SHELL = /bin/bash");
        out.println();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    private static void _writeFlags (   final PrintStream out,
                                        final CProject project)
    {
        _writeCppFlags(out, project);
        _writeLdFlags(out, project);
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    private static void _writeCppFlags (final PrintStream out,
                                        final CProject project)
    {
        _u_writeVariable(       out,
                                CPPFLAGS,
                                DefinitionPrefix,
                                ShellEscaperValueProcessor,
                                project.GetDefinitions(), false);
        _u_writeVariableValues( out,
                                InclusionPrefix,
                                ShellEscaperValueProcessor,
                                project.GetIncludeDirectories());
        _u_endOfVariable(out);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private static void _writeLdFlags ( final PrintStream out,
                                        final CProject project)
    {
        _u_writeVariable(   out,
                            LDFLAGS,
                            AdditionalLibraryDirectoryPrefix,
                            ShellEscaperValueProcessor,
                            project.GetLibraryDirectories(),
                            false);

    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    // -------------------------------------
    // Utilities
    private static void _u_writeVariableValues (final PrintStream out,
                                                final String valuePrefix,
                                                final ValueProcessor vp,
                                                final Iterable<?> values)
    {
        for (final Object value: values)
            out.printf("\t%s%s \\%n", valuePrefix, vp.process(value.toString()));
    }
    private static void _u_writeVariable (  final PrintStream out,
                                            final String variableName,
                                            final String valuePrefix,
                                            final ValueProcessor vp,
                                            final Iterable<?> values,
                                            final boolean finalWriting)
    {
        out.printf("%s = \\%n", variableName);
        _u_writeVariableValues(out, valuePrefix, vp, values);
        if (finalWriting)
            out.println();
    }

    private static void _u_endOfVariable (final PrintStream out) {
        out.println();
    }

    // -----
    
    private interface ValueProcessor {
        String process (String value);
    }
    private final static ValueProcessor ShellEscaperValueProcessor =
            new ValueProcessor() {
                @Override
                public String process(final String value) {
                    return ShellEscape(value);
                }
            };
}
