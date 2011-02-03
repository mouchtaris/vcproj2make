package jd2m;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Collection;
import java.util.logging.Level;
import java.util.logging.Logger;

class EvilFilesRemoverTask {

    public final Collection<String> FilesToKill =
            java.util.Collections.unmodifiableCollection(java.util.Arrays.asList(new String[]{
                    "../Tools/Delta/DeltaCompiler/Include/unistd.h",
                    "../Tools/Delta/ResourceLoaderLib/Include/unistd.h"
            }));

    private final Path SolutionBaseDir;
    EvilFilesRemoverTask (final Path solutionBaseDir) {
        SolutionBaseDir = solutionBaseDir;
    }

    public void DoKilling () throws IOException {
        for (final String filepath: FilesToKill) {
            final Path fullpath = SolutionBaseDir.resolve(filepath);
            try {
                fullpath.delete();
            }
            catch (final IOException ex) {
                LOG.log(Level.WARNING, "Removing file {0}: was not found",
                        fullpath);
            }
        }
    }

    private static final Logger LOG = Logger.getLogger(EvilFilesRemoverTask.class.getName());
}
