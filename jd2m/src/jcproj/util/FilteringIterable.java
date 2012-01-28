package jcproj.util;

import java.util.Iterator;

/**
 *
 * @date 14th of August 2011
 * @author muhtaris
 */
@SuppressWarnings("FinalClass")
public final class FilteringIterable<T> implements Iterable<T> {

	///////////////////////////////////////////////////////

	@Override
	public Iterator<T> iterator() {
		final Iterator<? extends T> iter = internal.iterator();

		return new Iterator<T>() {
			private T current;

			@Override
			@SuppressWarnings("NestedAssignment")
			public boolean hasNext () {
				while (iter.hasNext())
					if (pred.HoldsFor(current = iter.next()))
						return true;
				return false;
			}

			@Override
			public T next () {
				if (current == null)
					throw new RuntimeException("There is not next, or you are not checking if there is any (call hasNext() first...)");
				return current;
			}

			@Override
			public void remove () {
				iter.remove();
			}
		};
	}

	///////////////////////////////////////////////////////

	public FilteringIterable (Iterable<? extends T> internal, final Predicate<T> pred) {
		this.internal = internal;
		this.pred = pred;
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final Iterable<? extends T>	internal;
	private final Predicate<T>			pred;
}
