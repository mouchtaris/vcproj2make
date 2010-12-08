package jd2m.util;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

/**
 * Can only be used once ({@link #iterator} method called only once).
 * @author muhtaris
 * @param <T>
 */
public final class PremadeIteratorWrapperIterable<T> implements Iterable<T> {

    public interface UsageListener {
        void PremadeIteratorWrapperIterableBeingUsed ();
    }

    private boolean used = false;
    private List<UsageListener> _listeners = new LinkedList<>();
    private final Iterator<T> _iterator;
    public PremadeIteratorWrapperIterable (final Iterator<T> iterator) {
        _iterator = iterator;
        _listeners.add(new UsageListener() {
            @Override
            public void PremadeIteratorWrapperIterableBeingUsed () {
                used = true;
            }
        });
    }

    public void AddListener (final UsageListener listener) {
        _listeners.add(listener);
    }

    @Override
    public Iterator<T> iterator () {
        if (used)
            throw new RuntimeException("Iterable already used");
        _fireUsageEvent();
        return _iterator;
    }

    // -------------------------------------------------
    // Private
    private void _fireUsageEvent () {
        for (final UsageListener listener: _listeners)
            listener.PremadeIteratorWrapperIterableBeingUsed();
    }
}
