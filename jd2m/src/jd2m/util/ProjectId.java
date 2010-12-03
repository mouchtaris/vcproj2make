package jd2m.util;
 // TODO: check the string ID format

import java.util.HashMap;
import java.util.Map;



public final class ProjectId {
    public static final short ID_LENGTH = 38;

    public static boolean IsValid (final String value) {
        //        "{F6459465-11D4-4CFD-99B9-5D8BDC5B598C}"
        boolean b0 = value.length()               == ID_LENGTH;
        boolean b1 = value.charAt(0)              == '{';
        boolean b2 = value.charAt(ID_LENGTH - 1)  == '}';
        boolean b3 = value.charAt(9)              == '-';
        boolean b4= value.charAt(14)             == '-';
        boolean b5 = value.charAt(19)             == '-';
        boolean b6 = value.charAt(24)             == '-';
        return b0 && b1 && b2 && b3 && b4 && b5 && b6;
    }

    private static Map<String, ProjectId> Instances = new HashMap<>(100);
    public static ProjectId CreateNew (final String value) {
        final ProjectId newInstance = new ProjectId(value);
        final Object previous = Instances.put(value, newInstance);
        assert previous == null;
        return newInstance;
    }
    public static ProjectId Get (final String value) {
        final ProjectId result = Instances.get(value);
        assert result != null;
        return result;
    }
    public static ProjectId GetOrCreate (final String value) {
        ProjectId result = Instances.get(value);
        if (result == null) {
            result = new ProjectId(value);
            final Object previous = Instances.put(value, result);
            assert previous == null;
        }
        return result;
    }
    
    private final String _value;
    private ProjectId (final String value) {
        assert IsValid(value);
        _value = value;
    }
    
    @Override
    public boolean equals (Object obj) {
        boolean result = false;
        if ( obj != null && getClass() == obj.getClass() ) {
            final ProjectId other = (ProjectId) obj;
            result = _value.equals(other._value);
        }
        return result;
    }

    @Override
    public int hashCode () {
        int hash = 3;
        hash = 41 * hash + _value.hashCode();
        return hash;
    }

    @Override
    public String toString () {
        return "ID{" + _value + '}';
    }
}
