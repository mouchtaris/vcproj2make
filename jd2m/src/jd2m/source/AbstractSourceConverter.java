package jd2m.source;

import java.io.CharArrayWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;

public abstract class AbstractSourceConverter implements SourceConverter {

    @Override
    public void Convert (final File in, final File out) throws IOException {
        final FileReader fin = new FileReader(in);
        final FileWriter fout = new FileWriter(out);
        Convert(fin, fout);
        fin.close();
        fout.flush();
        fout.close();
    }

    @Override
    public void Convert (final String in, final String out) throws IOException {
        if (in.equals(out)) {
            final CharArrayWriter myout = new CharArrayWriter(1 << 13);
            final Reader myin = new FileReader(new File(in));
            Convert(myin, myout);
            final Writer fout = new FileWriter(new File(out));
            final char[] chars = myout.toCharArray();
            fout.write(chars);
            fout.close();
        }
        else
            Convert(new File(in), new File(out));
    }
}
