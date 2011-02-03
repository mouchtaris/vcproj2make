package jd2m;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Collection;
import jd2m.source.ByteFiltererSourceConverter;
import jd2m.source.SourceConverter;

class WindowsSourcesConvertTask {

    public final Collection<String> FilesToModify =
            java.util.Collections.unmodifiableCollection(java.util.Arrays.asList(new String[]{
                    "../Tools/Delta/ResourceLoaderLib/Src/RcParser.cpp"
            }));

    private final Path SolutionBaseDir;
    public WindowsSourcesConvertTask (final Path solutionBaseDir) {
        SolutionBaseDir = solutionBaseDir;
    }

    public void DoConversion () throws IOException {
        final SourceConverter sc = new ByteFiltererSourceConverter('\r');
        for (final String filepath: FilesToModify) {
            final String fullpath = SolutionBaseDir.resolve(filepath).toString();
            sc.Convert(fullpath, fullpath);
        }
    }
}
