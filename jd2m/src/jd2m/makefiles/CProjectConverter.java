package jd2m.makefiles;

import java.nio.file.Path;
import jd2m.util.ProjectId;
import jd2m.cbuild.CSolution;
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
    private static final String CXXFLAGS    = "CXXFLAGS";
    private static final String ARFLAGS     = "ARFLAGS";

    private static final String DefinitionPrefix                = "-D";
    private static final String InclusionPrefix                 = "-I";
    private static final String AdditionalLibraryDirectoryPrefix= "-L";
    private static final String LibraryLinkingPrefix            = "-l";
    private static final String XLinkerExtraOptionPrefix        = "-Xlinker ";

    private static final String XLinkerRPathOption  = "--rpath";

    private static final String PredefinedCXXFLAGS  = CXXFLAGS +
                                                    " = -ansi -pedantic -Wall";
    private static final String PredefinedARFLAGS   = ARFLAGS + " = crv";
    
    private final PrintStream   out;
    private final CProject      project;
    private final CSolution     solution;
    private CProjectConverter ( final PrintStream   _out,
                                final CProject      _project,
                                final CSolution     _solution)
    {
        out        = _out;
        project    = _project;
        solution   = _solution;
    }

    public static void GenerateMakefileFromCProject (
                                                    final OutputStream outs,
                                                    final CProject project,
                                                    final CSolution solution)
    {
        final PrintStream out = new PrintStream(new BufferedOutputStream(outs));

        final CProjectConverter converter =
                new CProjectConverter(out, project, solution);

        converter._writeHeader();
        converter._writeFlags();

        out.flush();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeHeader ()
    {
        out.println("SHELL = /bin/bash");
        out.println();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    private void _writeFlags ()
    {
        _writeCppFlags();
        _writeLdFlags();
        _writeCxxAndArFlags();
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    private void _writeCppFlags ()
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

    private void _writeLdFlags ()
    {
        _u_writeVariable(   out,
                            LDFLAGS,
                            AdditionalLibraryDirectoryPrefix,
                            ShellEscaperValueProcessor,
                            project.GetLibraryDirectories(),
                            false);
        //
        // Write dependency-related LDFLAGS
        for (final ProjectId projId: project.GetDependencies()) {
            final CProject  dependency      = solution.GetProject(projId);
            final Path      dependencyOutput= dependency.GetOutput();
            final String    dependencyTarget= dependency.GetTarget();
            final String    dependencyOutputString =dependencyOutput.toString();
            // Add dependency output directory to library directories with -L
            _u_writeVariableValue(  out,
                                    AdditionalLibraryDirectoryPrefix,
                                    ShellEscape(dependencyOutputString));
            // Add the generated library to the linking inputs with -l
            _u_writeVariableValue(  out, LibraryLinkingPrefix,
                                    ShellEscape(dependencyTarget));
            // Write --rpath related flags
            _u_writeVariableValue(  out, XLinkerExtraOptionPrefix,
                                    ShellEscape(XLinkerRPathOption));
            _u_writeVariableValue(  out, XLinkerExtraOptionPrefix,
                                    ShellEscape(dependencyOutputString));
        }
        //
        // Write addition-libraries related LDFLAGS
        _u_writeVariableValues(     out,
                                    LibraryLinkingPrefix,
                                    ShellEscaperValueProcessor,
                                    project.GetAdditionalLibraries());
        //
        _u_endOfVariable(out);
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeCxxAndArFlags ()
    {
        out.println(PredefinedCXXFLAGS);
        out.println(PredefinedARFLAGS);
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    // -------------------------------------
    // Utilities
    private static void _u_writeVariableValue ( final PrintStream out,
                                                final String valuePrefix,
                                                final String value)
    {
        out.printf("\t%s%s \\%n", valuePrefix, value);
    }
    private static void _u_writeVariableValues (final PrintStream out,
                                                final String valuePrefix,
                                                final ValueProcessor vp,
                                                final Iterable<?> values)
    {
        for (final Object value: values)
            _u_writeVariableValue(  out, valuePrefix,
                                    vp.process(value.toString()));
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
