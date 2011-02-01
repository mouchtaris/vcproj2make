package jd2m.source;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;

public interface SourceConverter {
    void Convert (final Reader in, final Writer out) throws IOException;
    void Convert (final File in, final File out) throws IOException;
    void Convert (final String in, final String out) throws IOException;
}
