package jd2m.makefiles;

import java.nio.file.Files;
import java.io.IOException;
import java.nio.file.Path;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CSolution;

import static jd2m.makefiles.CProjectConverter.GenerateMakefileFromCProject;
import static java.nio.file.StandardOpenOption.CREATE;
import static java.nio.file.StandardOpenOption.WRITE;
import static java.nio.file.StandardOpenOption.TRUNCATE_EXISTING;

/**
 * Writes to files by default.
 * @author muhtaris
 */
public class CSolutionConverter {

    public static String MakeActualMakefileNameForProject (
                                                    final CProject cproject,
                                                    final String makefileName)
    {
        final String result =makefileName + cproject.GetConfiguration() + ".mk";
        return result;
    }

    public static Path MakeMakefilePathForProject  (final CProject cproject,
                                                    final String makefileName)
    {
        final Path makefileDirectory = cproject.GetLocation().getParent();
        assert makefileDirectory != null;
        final String actualMakefileName = MakeActualMakefileNameForProject(
                                            cproject, makefileName);
        final Path makefilePath = makefileDirectory.resolve(actualMakefileName);
        return makefilePath;
    }

    public static void GenerateMakefelesFromCSolution (
                                                final CSolution csolution,
                                                final String    makefileName)
        throws IOException
    {
        for (final CProject cproject: csolution) {
            final Path makefilePath = MakeMakefilePathForProject(
                                                                cproject,
                                                                makefileName);
            GenerateMakefileFromCProject(
                    Files.newOutputStream(makefilePath, CREATE,
                                                        WRITE,
                                                        TRUNCATE_EXISTING),
                    cproject,
                    csolution,
                    makefileName);
        }
    }
}
