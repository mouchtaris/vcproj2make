package jd2m.makefiles;

import java.util.Map;
import java.nio.file.Path;
import jd2m.util.ProjectId;
import jd2m.cbuild.CSolution;
import java.io.BufferedOutputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.HashMap;
import jd2m.cbuild.CProject;

import static jd2m.makefiles.MakefileUtilities.ShellEscape;
import static jd2m.util.PathHelper.StripExtension;
import static jd2m.util.PathHelper.GetExtension;
import static jd2m.util.PathHelper.CPP_EXTENSION;
import static jd2m.util.PathHelper.ToMonotonousPath;

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

    private static final String SOURCES = "SOURCES";
    private static final String OBJECTS = "OBJECTS";
    private static final String DEPENDS = "DEPENDS";

    private static final String DOT = ".";
    private static final String OBJECT_EXTENSION = DOT +
                                        jd2m.util.PathHelper.OBJECT_EXTENSION;
    private static final String DEPEND_EXTENSION = DOT +
                                        jd2m.util.PathHelper.DEPEND_EXTENSION;

    private static final String _EMPTY_STRING = "";
    
    private final PrintStream       out;
    private final CProject          project;
    private final CSolution         solution;
    private final Map<Path, Path>   producables;
    private CProjectConverter ( final PrintStream   _out,
                                final CProject      _project,
                                final CSolution     _solution)
    {
        out                     = _out;
        project                 = _project;
        solution                = _solution;
        producables             = new HashMap<>(_project.GetNumberOfSources());

        _u_populateProducables( _project.GetSources(),
                                _project.GetIntermediate(), producables);
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
        converter._writeVariables();

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
                                ShellEscaperValuePreprocessor,
                                _EMPTY_STRING,
                                project.GetDefinitions(), false);
        _u_writeVariableValues( out,
                                InclusionPrefix,
                                ShellEscaperValuePreprocessor,
                                _EMPTY_STRING,
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
                            TransparentValuePreprocessor,
                            _EMPTY_STRING,
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
                                    dependencyOutputString,
                                    _EMPTY_STRING);
            // Add the generated library to the linking inputs with -l
            _u_writeVariableValue(  out, LibraryLinkingPrefix,
                                    ShellEscape(dependencyTarget),
                                    _EMPTY_STRING);
            // Write --rpath related flags
            _u_writeVariableValue(  out, XLinkerExtraOptionPrefix,
                                    ShellEscape(XLinkerRPathOption),
                                    _EMPTY_STRING);
            _u_writeVariableValue(  out, XLinkerExtraOptionPrefix,
                                    ShellEscape(dependencyOutputString),
                                    _EMPTY_STRING);
        }
        //
        // Write addition-libraries related LDFLAGS
        _u_writeVariableValues(     out,
                                    LibraryLinkingPrefix,
                                    ShellEscaperValuePreprocessor,
                                    _EMPTY_STRING,
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

    private void _writeVariables ()
    {
        _writeSourcesVariable();
        _writeObjectsVariable();
        _writeDependsVariable();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeSourcesVariable ()
    {
        _u_writeVariable(   out, SOURCES, _EMPTY_STRING,
                            ShellEscaperValuePreprocessor, _EMPTY_STRING,
                            project.GetSources(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeObjectsVariable ()
    {
        _u_writeVariable(   out, OBJECTS, _EMPTY_STRING,
                            ShellEscaperValuePreprocessor, OBJECT_EXTENSION,
                            producables.values(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeDependsVariable ()
    {
        _u_writeVariable(   out, DEPENDS, _EMPTY_STRING,
                            ShellEscaperValuePreprocessor, DEPEND_EXTENSION,
                            producables.values(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    // -------------------------------------
    // Utilities
    private static void _u_writeVariableValue ( final PrintStream out,
                                                final String valuePrefix,
                                                final String value,
                                                final String valueSuffix)
    {
        out.printf("\t%s%s%s \\%n", valuePrefix, value, valueSuffix);
    }
    private static void _u_writeVariableValues (final PrintStream out,
                                                final String valuePrefix,
                                                final ValuePreprocessor vp,
                                                final String valueSuffix,
                                                final Iterable<?> values)
    {
        for (final Object value: values)
            _u_writeVariableValue(  out, valuePrefix,
                                    vp.process(value.toString()),
                                    valueSuffix);
    }
    private static void _u_writeVariable (  final PrintStream out,
                                            final String variableName,
                                            final String valuePrefix,
                                            final ValuePreprocessor vp,
                                            final String valueSuffix,
                                            final Iterable<?> values,
                                            final boolean finalWriting)
    {
        out.printf("%s = \\%n", variableName);
        _u_writeVariableValues(out, valuePrefix, vp, valueSuffix, values);
        if (finalWriting)
            out.println();
    }

    private static void _u_endOfVariable (final PrintStream out) {
        out.println();
    }

    // -----
    // non-makefile-writing related utilities
    private static void _u_populateProducables (
                                            final Iterable<Path> sources,
                                            final Path intermediate,
                                            final Map<Path, Path> producables)
    {
        for (final Path source: sources) {
            final String srcTrans = ToMonotonousPath(source.toString());
            assert GetExtension(srcTrans).equals(CPP_EXTENSION);
            final String basenameString = StripExtension(srcTrans);
            final Path producablePath = intermediate.resolve(basenameString);
            producables.put(source, producablePath);
        }
    }

    // -----
    
    private interface ValuePreprocessor {
        String process (String value);
    }
    private final static ValuePreprocessor ShellEscaperValuePreprocessor =
            new ValuePreprocessor() {
                @Override
                public String process (final String value) {
                    return ShellEscape(value);
                }
            };
    private final static ValuePreprocessor TransparentValuePreprocessor =
            new ValuePreprocessor() {
                @Override
                public String process (final String value) {
                    return value;
                }
            };
}
