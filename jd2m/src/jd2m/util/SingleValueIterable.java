package jd2m.util;

import java.util.Iterator;

/**
 *
 * @author muhtaris
 */
public final class SingleValueIterable<T> implements Iterable<T> {

    private final T _value;
    public SingleValueIterable (final T value) {
        _value = value;
    }

    @Override
    public Iterator<T> iterator () {
        return new Iterator<T>() {
            private boolean consumed = false;
            
            @Override
            public boolean hasNext() {
                final boolean result = !consumed;
                return result;
            }

            @Override
            public T next() {
                T result = null;
                if (!consumed) {
                    consumed = true;
                    result = _value;
                }
                return result;
            }

            @Override
            public void remove() {
                throw new UnsupportedOperationException("Not supported.");
            }
        };
    }

}
