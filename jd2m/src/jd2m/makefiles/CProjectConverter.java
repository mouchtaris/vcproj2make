package jd2m.makefiles;

import java.util.Map.Entry;
import java.util.Set;
import java.util.Map;
import java.nio.file.Path;
import jd2m.util.ProjectId;
import jd2m.cbuild.CSolution;
import java.io.BufferedOutputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.HashSet;
import jd2m.cbuild.CProject;
import jd2m.util.SingleValueIterable;

import static jd2m.makefiles.MakefileUtilities.ShellEscape;
import static jd2m.util.PathHelper.StripExtension;
import static jd2m.util.PathHelper.GetExtension;
import static jd2m.util.PathHelper.CPP_EXTENSION;
import static jd2m.util.PathHelper.ToMonotonousPath;
import static jd2m.util.PathHelper.CreatePath;
import static jd2m.util.StringBuilder.GetStringBuilder;
import static jd2m.util.StringBuilder.ResetStringBuilder;;
import static jd2m.util.StringBuilder.ReleaseStringBuilder;
import static jd2m.makefiles.CSolutionConverter.MakeActualMakefileNameForProject;
import static jd2m.makefiles.MakefileUtilities.GetFullTargetPathForUnixProject;

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
    private static final String TARGET  = "TARGET";

    private static final String DOT = ".";
    private static final String OBJECT_EXTENSION = DOT +
                                        jd2m.util.PathHelper.OBJECT_EXTENSION;
    private static final String DEPEND_EXTENSION = DOT +
                                        jd2m.util.PathHelper.DEPEND_EXTENSION;

    private static final String _EMPTY_STRING = "";

    private static final String AllTargetName       = "all";
    private static final String ObjectsTargetName   = "objects";
    private static final String DirsTargetName      = "dirs";
    private static final String TargetTargetName    = "target";
    private static final String DepsTargetName      = "deps";
    private static final String CleanTargetName     = "clean";
    private static final String[] AllPhonyTargets = new String[] {
        AllTargetName, ObjectsTargetName, DirsTargetName,
        TargetTargetName, DepsTargetName, CleanTargetName};
    
    private static final String PHONY               = ".PHONY";

    private static final String PredefinedAllAndObjectsTarget =
            AllTargetName + ": " + DepsTargetName + " " + DirsTargetName +
                    " " + ObjectsTargetName + " " + TargetTargetName + "\n" +
            ObjectsTargetName + ": $(" + OBJECTS + ")";

    private static final String PredefinedTargetTargetHeader =
            TargetTargetName + ": $(" + TARGET + ")";

    private final PrintWriter       out;
    private final CProject          project;
    private final CSolution         solution;
    private final String            makefileName;
    private final Map<Path, Path>   producables;
    private final Set<Path>         producablesPaths;
    /** { DepName (unique) => [Commands...] , ... } */
    private final Map<String,
            Iterable<String>>       depsCommands;

    private CProjectConverter ( final PrintWriter   _out,
                                final CProject      _project,
                                final CSolution     _solution,
                                final String        _makefileName)
    {
        final int numberOfSources       = _project.GetNumberOfSources();
        final int numberOfDependencies  = _project.GetNumberOfDependencies();

        out                     = _out;
        project                 = _project;
        solution                = _solution;
        makefileName            = _makefileName;
        producables             = new HashMap<>(numberOfSources);
        producablesPaths        = new HashSet<>(numberOfSources);
        depsCommands            = new HashMap<>(numberOfDependencies);

        _u_populateProducables( _project.GetSources(),
                                _project.GetIntermediate(), producables,
                                producablesPaths);
        producablesPaths.add(_project.GetOutput());
        _u_populateDeps(_project.GetDependencies(), _solution, depsCommands,
                        numberOfDependencies, _makefileName);
    }

    public static void GenerateMakefileFromCProject (
                                                    final OutputStream outs,
                                                    final CProject project,
                                                    final CSolution solution,
                                                    final String makefileName)
    {
        final PrintWriter out = new PrintWriter(new BufferedOutputStream(outs));

        final CProjectConverter converter =
                new CProjectConverter(out, project, solution, makefileName);

        converter._writeHeader();
        converter._writeFlags();
        converter._writeVariables();
        converter._writeTargets();
        converter._writeFooter();

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
                                TransparentValuePreprocessor,
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
        _writeTargetVariable();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeSourcesVariable ()
    {
        _u_writeVariable(   out, SOURCES, _EMPTY_STRING,
                            TransparentValuePreprocessor, _EMPTY_STRING,
                            project.GetSources(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeObjectsVariable ()
    {
        _u_writeVariable(   out, OBJECTS, _EMPTY_STRING,
                            TransparentValuePreprocessor, OBJECT_EXTENSION,
                            producables.values(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeDependsVariable ()
    {
        _u_writeVariable(   out, DEPENDS, _EMPTY_STRING,
                            TransparentValuePreprocessor, DEPEND_EXTENSION,
                            producables.values(), true);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeTargetVariable ()
    {
        out.printf("%s = %s%n", TARGET, GetFullTargetPathForUnixProject(project));
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeTargets ()
    {
        _writeAllAndObjectsTarget();
        _writeTargetTarget();
        _writePhonyTarget();
        _writeCleanTarget();
        _writeDirsTarget();
        _writeDepsTarget();
        _writeEachTargetTarget();
        _writeEachDepTarget();
        _writeEachObjectTarget();
        _writeEachDirTarget();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeTargetTarget ()
    {
        out.println(PredefinedTargetTargetHeader);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeAllAndObjectsTarget ()
    {
        out.println(PredefinedAllAndObjectsTarget);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writePhonyTarget ()
    {
        _u_writeTarget( out, PHONY, TransparentValuePreprocessor,
                        java.util.Arrays.asList(AllPhonyTargets), null);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeCleanTarget ()
    {
        // TODO write a more sophisticated clean target
        _u_writeTarget( out, CleanTargetName, TransparentValuePreprocessor,
                        null, new SingleValueIterable<>("rm -r -f -v $("
                                + OBJECTS + ") $(" + DEPENDS + ") $("
                                + TARGET  + ")"));
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeDirsTarget ()
    {
        _u_writeTargetHeader(out, DirsTargetName, TransparentValuePreprocessor,
                        producablesPaths);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private static final String TARGET_VAR  = " $(" + TARGET + ")";
    private static final String OBJECTS_VAR = " $(" + OBJECTS + ")";
    private static final String LDFLAGS_VAR = " $(" + LDFLAGS + ")";
    private static final String ARFLAGS_VAR = " $(" + ARFLAGS + ")";
    private void _writeEachTargetTarget ()
    {
        _u_writeTargetName(out, TARGET_VAR);

        for (final ProjectId depId: project.GetDependencies()) {
            final CProject depProj = solution.GetProject(depId);
            final Path projResult = GetFullTargetPathForUnixProject(depProj);
            _u_writeTargetDependency(out, projResult.toString());
        }
        _u_writeTargetDependency(out, OBJECTS_VAR);
        out.println();
        
        final StringBuilder sb = GetStringBuilder();
        switch (project.GetType()) {
            case DynamicLibrary:
                sb.append("$(CXX) -shared").append(OBJECTS_VAR)
                        .append(LDFLAGS_VAR)
                        .append(" -o").append(TARGET_VAR);
                break;
            case StaticLibrary:
                sb.append("$(AR)").append(ARFLAGS_VAR)
                        .append(TARGET_VAR).append(OBJECTS_VAR);
                break;
            case Executable:
                sb.append("$(CXX)").append(OBJECTS_VAR)
                        .append(TARGET_VAR).append(LDFLAGS_VAR);
                break;
        }

        final String command = sb.toString();
        ReleaseStringBuilder();
        _u_writeTargetCommand(out, command);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeDepsTarget ()
    {
        _u_writeTarget( out,
                        DepsTargetName,
                        TransparentValuePreprocessor,
                        depsCommands.keySet(),
                        null);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeEachDepTarget ()
    {
        for (final Entry<String, Iterable<String>> dep: depsCommands.entrySet())
            _u_writeTarget( out,
                            dep.getKey(),
                            TransparentValuePreprocessor,
                            null,
                            dep.getValue());
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeEachObjectTarget ()
    {
        final StringBuilder sb = GetStringBuilder();
        
        for (final Entry<Path, Path> producable: producables.entrySet()) {
            final Path sourcePath = producable.getKey();
            final Path producablePath = producable.getValue();
            final String producablePathString = producablePath.toString();
            final Path objectPath = CreatePath( producablePathString +
                                                OBJECT_EXTENSION);
            final Path dependsPath = CreatePath(producablePathString +
                                                DEPEND_EXTENSION);
            //
            final String objectPathString = objectPath.toString();
            _u_writeTargetHeader(   out,
                                    objectPathString,
                                    TransparentValuePreprocessor,
                                    new SingleValueIterable<>(sourcePath));
            //
            ResetStringBuilder();
            sb.append("$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MD -c -o")
                    .append(objectPath).append(" -MF ").append(dependsPath)
                    .append(" ").append(sourcePath);
            final String command = sb.toString();
            _u_writeTargetCommand(out, command);
        }

        ReleaseStringBuilder();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private void _writeEachDirTarget ()
    {
        final StringBuilder sb = GetStringBuilder();
        for (final Path path: producablesPaths) {
            ResetStringBuilder();
            final String pathString = path.toString();
            sb.append("mkdir -p -v ").append(pathString);
            final String command = sb.toString();
            //
            _u_writeTarget( out, pathString,
                            TransparentValuePreprocessor, null,
                            new SingleValueIterable<>(command));
        }
        ReleaseStringBuilder();
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    private final static String DEPENDS_VAR = "$(" + DEPENDS + ")";
    private void _writeFooter ()
    {
        out.println("-include " + DEPENDS_VAR);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    // -------------------------------------
    // Utilities
    private static void _u_writeVariableValue ( final PrintWriter out,
                                                final String valuePrefix,
                                                final String value,
                                                final String valueSuffix)
    {
        out.printf("\t%s%s%s \\%n", valuePrefix, value, valueSuffix);
    }
    private static void _u_writeVariableValues (final PrintWriter out,
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
    private static void _u_writeVariable (  final PrintWriter out,
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

    private static void _u_endOfVariable (final PrintWriter out) {
        out.println();
    }

    // ----

    private static void _u_writeTargetName (
                                        final PrintWriter out,
                                        final String targetName)
    {
        out.printf("%s: ", targetName);
    }
    private static void _u_writeTargetDependency (
                                        final PrintWriter out,
                                        final String dependency)
    {
        out.printf("%s ", dependency);
    }
    private static void _u_writeTargetHeader (
                                        final PrintWriter out,
                                        final String targetName,
                                        final ValuePreprocessor vp,
                                        final Iterable<?> dependencies)
    {
        _u_writeTargetName(out, targetName);
        if (dependencies != null)
            for (final Object dep: dependencies)
                _u_writeTargetDependency(out, vp.process(dep.toString()));
        out.println();
    }
    private static void _u_writeTargetCommand (
                                        final PrintWriter out,
                                        final Object command)
    {
        out.printf("\t%s%n", command);
    }
    private static void _u_writeTarget (final PrintWriter out,
                                        final String targetName,
                                        final ValuePreprocessor vp,
                                        final Iterable<?> dependencies,
                                        final Iterable<?> commands)
    {
        _u_writeTargetHeader(out, targetName, vp, dependencies);
        if (commands != null)
            for (final Object command: commands)
                _u_writeTargetCommand(out, command);
    }

    // -----ToMonotonousPath
    // non-makefile-writing related utilities
    private static Path _u_producablePathProcess (final Path path) {
        final String level0 = ToMonotonousPath(path.toString());
        final String level1 = level0.replaceAll("\\|", "___");
        final Path result = CreatePath(level1);
        return result;
    }
    private static void _u_populateProducables (
                                            final Iterable<Path> sources,
                                            final Path intermediate,
                                            final Map<Path, Path> producables,
                                            final Set<Path> producablesPaths)
    {
        for (final Path source: sources) {
            final String srcTrans = _u_producablePathProcess(source).toString();
            assert GetExtension(srcTrans).equals(CPP_EXTENSION);
            final String basenameString = StripExtension(srcTrans);
            final Path producablePath = intermediate.resolve(basenameString);
            final Path producablePathProcessed = _u_producablePathProcess(
                    producablePath);
            producables.put(source, producablePathProcessed);
            producablesPaths.add(producablePathProcessed.getParent());
        }
    }

    private static void _u_populateDeps (
                            final Iterable<ProjectId> deps,
                            final CSolution csolution,
                            final Map<String, Iterable<String>> depsCommands,
                            final int numberOfDependencies,
                            final String makefileName)
    {   
        for (final ProjectId depId: deps) {
            final CProject depProject = csolution.GetProject(depId);
            final String depName = depProject.GetName().StringValue();
            //
            final Path projectLocation = depProject.GetLocation();
            final Path projectDirectory = projectLocation.getParent();
            assert projectDirectory != null;
            //
            final StringBuilder sb = GetStringBuilder();
            sb.append("cd ")
                    .append(ShellEscape(projectDirectory.toString()))
                    .append(" && make -f ")
                    .append(ShellEscape(MakeActualMakefileNameForProject(
                                    depProject, makefileName)));
            final String command = sb.toString();
            ReleaseStringBuilder();
            //
            final Object previous = depsCommands
                    .put(depName, new SingleValueIterable<String>(command));
            assert previous == null;
        }
        assert depsCommands.size() == numberOfDependencies;
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
