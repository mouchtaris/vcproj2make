package jd2m.util;

/**
 *
 * @author muhtaris
 */
public final class StringBuilder {

    private StringBuilder () {
    }

    private static final java.lang.StringBuilder SB =
            new java.lang.StringBuilder(1024);

    public static java.lang.StringBuilder GetStringBuilder () {
        return SB;
    }

    public static void ResetStringBuilder () {
        SB.delete(0, SB.length());
    }
}
