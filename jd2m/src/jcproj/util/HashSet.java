package jcproj.util;

import java.util.AbstractSet;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * @date 13th of December 2011
 * @author TURBO_X
 */
public class HashSet<T> extends AbstractSet<T> {

	@Override
	public Iterator<T> iterator () {
		return map.keySet().iterator();
	}

	@Override
	public int size () {
		return map.size();
	}

	@Override
	@SuppressWarnings("element-type-mismatch")
	public boolean removeAll (final Collection<?> c) {
		boolean modified = false;
		for (final Object o: c)
			modified |= remove(o);
		return modified;
	}

	@Override
	public boolean add (final T e) {
		final boolean modified = !map.containsKey(e);
		if (modified)
			map.put(e, e);
		return modified;
	}

	@Override
	public void clear () {
		map.clear();
	}

	@Override
	@SuppressWarnings("element-type-mismatch")
	public boolean contains (final Object o) {
		return map.containsKey(o);
	}

	@Override
	public boolean isEmpty () {
		return super.isEmpty();
	}

	@Override
	@SuppressWarnings("element-type-mismatch")
	public boolean remove (final Object o) {
		final Object removedObject = map.remove(o);
		final boolean removed = removedObject != null;
		assert removed && removedObject.equals(o);
		return removed;
	}

	public T pop (final T o) {
		T resolt = null;
		if (map.containsKey(o)) {
			resolt = map.get(o);
			assert resolt.equals(o);
			final boolean removed = remove(o);
			assert removed;
		}
		return resolt;
	}

	///////////////////////////////////////////////////////
	// Constructors
	public HashSet (int capacity) {
		map = new HashMap<T, T>(capacity);
	}

	///////////////////////////////////////////////////////
	// State
	private final Map<T, T> map;
}
