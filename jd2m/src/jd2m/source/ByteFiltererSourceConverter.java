package jd2m.source;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;

public class ByteFiltererSourceConverter extends AbstractSourceConverter {

    private final char cutit;
    public ByteFiltererSourceConverter (final char _cutit) {
        cutit = _cutit;
    }

    private final char[] buf = new char[1 << 13];
    @Override
    public void Convert (final Reader in, final Writer out) throws IOException {
        int bytesread;
        while ((bytesread = in.read(buf)) != -1) {
            assert bytesread >= 0;
            
            int fallingSpace = 0;
            int i = 0;
            while (i < bytesread - fallingSpace) {
                buf[i] = buf[i + fallingSpace];
                if (buf[i] == cutit)
                    ++fallingSpace;
                else
                    ++i;
            }

            out.write(buf, 0, bytesread - fallingSpace);
        }
    }

}
