package jd2m.makefiles;

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

    public static void GenerateMakefelesFromCSolution (
                                                final CSolution csolution,
                                                final String    makefileName)
        throws IOException
    {
        for (final CProject cproject: csolution) {
            final Path makefileDirectory = cproject.GetLocation().getParent();
            assert makefileDirectory != null;
            final Path makefilePath = makefileDirectory.resolve(
                    makefileName + cproject.GetConfiguration() + ".mk");
            GenerateMakefileFromCProject(
                    makefilePath.newOutputStream(   CREATE,
                                                    WRITE,
                                                    TRUNCATE_EXISTING),
                    cproject);
        }
    }
}
