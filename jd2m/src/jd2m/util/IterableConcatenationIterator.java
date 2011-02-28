package jd2m.util;

import java.util.Collection;
import java.util.Deque;
import java.util.Iterator;
import java.util.LinkedList;


/**
 * @param <T>
 * @date 2010-06-06 15:16
 * @author TURBO_X
 */
public final class IterableConcatenationIterator<T> implements Iterator<T> {
    // state
    private final Deque<Iterable<? extends T>> iterables;
    //
    /**
     * the given collection is used as-is, without copying.
     * @param _iterables
     */
    public IterableConcatenationIterator(final Deque<Iterable<? extends T>> _iterables) {
        iterables = _iterables;
    }
    public IterableConcatenationIterator() {
        this(new LinkedList<Iterable<? extends T>>());
    }
    //
    public static <T> IterableConcatenationIterator<T> create(final Iterable<? extends T> ite) {
        final IterableConcatenationIterator<T> result = new IterableConcatenationIterator<T>();
        return result.add(ite);
    }
    public static <T> IterableConcatenationIterator<T> create(final Iterable<? extends T> ite1, final Iterable<? extends T> ite2) {
        final IterableConcatenationIterator<T> result = new IterableConcatenationIterator<T>();
        return result.add(ite1).add(ite2);
    }
    public static <T> IterableConcatenationIterator<T> create(final Iterable<? extends T>[] ites) {
        final IterableConcatenationIterator<T> result = new IterableConcatenationIterator<T>();
        return result.add(java.util.Arrays.asList(ites));
    }
    public static <T, I extends Iterable<? extends T>> IterableConcatenationIterator<T> create(final Collection<I> col) {
        final IterableConcatenationIterator<T> result = new IterableConcatenationIterator<T>();
        return result.add(col);
    }
    /**
     * The given collection i added by the add() method.
     * @param <T>
     * @param ites
     * @return
     */
    public static <T> IterableConcatenationIterator<T> createFromIterableCollection(final Collection<? extends Iterable<? extends T>> ites) {
        final IterableConcatenationIterator<T> result = new IterableConcatenationIterator<T>();
        return result.add(ites);
    }

    /**
     *
     * @param ite
     * @return this
     */
    public IterableConcatenationIterator<T> add(final Iterable<? extends T> ite) {
        final IterableConcatenationIterator<T> proxy = this;
        //
        final boolean inserted_successfully = proxy.iterables.offerLast(ite);
        assert inserted_successfully;
        return proxy;
    }
    /**
     * The given collection is addAll()-ed in the given collection (copied, in
     * other words, probably with O(n) cost as it's iterated over).
     * @param ites
     * @return this
     */
    public IterableConcatenationIterator<T> add(final Collection<? extends Iterable<? extends T>> ites) {
        final IterableConcatenationIterator<T> proxy = this;
        //
        try {
            final boolean inserted_successfully = proxy.iterables.addAll(ites);
            assert inserted_successfully;
        } catch (final Exception ex) {
            assert false;
        }
        return proxy;
    }

    @Override
    public boolean hasNext() {
        Iterator<? extends T> curr;
        for (curr = _getCurrentIterator(); curr != null && !curr.hasNext(); curr = _advanceIterators())
            {}
        return curr != null? curr.hasNext() : false;
    }

    @Override
    public T next() {
        final Iterator<? extends T> curr = _getCurrentIterator();
        return curr != null? curr.next() : null;
    }

    @Override
    public void remove() {
        final Iterator<? extends T> curr = _getCurrentIterator();
        if (curr != null)
            curr.remove();
    }

    // internal iterating state and operations //////////////////////
    private Iterator<? extends T> _currentIterator;
    private Iterator<? extends T> _getCurrentIterator() {
        if (_currentIterator == null) {
            final Iterable<? extends T> iterable = iterables.pollFirst();
            _currentIterator = iterable != null? iterable.iterator() : null;
        }
        return _currentIterator;
    }
    private Iterator<? extends T> _advanceIterators() {
        _currentIterator = null;
        return _getCurrentIterator();
    }
}
