package jd2m.util;

public final class Name {
    private final String _value;
    public Name (final String value) {
        _value = value;
    }

    @Override
    public boolean equals (Object obj) {
        boolean result = false;
        if ( obj != null && getClass() == obj.getClass() ) {
            final Name other = (Name) obj;
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
        return "Name{" + _value + '}';
    }
}
