package jd2m.util;

/**
 *
 * @author muhtaris
 */
public final class StringBuilder {

    private StringBuilder () {
    }

    private static boolean SBLocked = false;
    private static final java.lang.StringBuilder SB =
            new java.lang.StringBuilder(1024);

    /** returns a the instance of the string builder, resetted, and locks it.
     *
     * @return
     */
    public static java.lang.StringBuilder GetStringBuilder ()
    {
        if (SBLocked)
            throw new RuntimeException("StringBuilder locked"); // TODO proper error handling
        SBLocked = true;
        ResetStringBuilder();
        return SB;
    }

    public static void ReleaseStringBuilder () {
        assert SBLocked;
        SBLocked = false;
    }

    public static void ResetStringBuilder () {
        SB.delete(0, SB.length());
    }
}
