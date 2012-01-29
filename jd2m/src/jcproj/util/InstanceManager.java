package jcproj.util;

import java.util.HashMap;
import java.util.Map;

public class InstanceManager<K, T extends Identifiable<? extends K>> {

	///////////////////////////////////////////////////////
	// State
	private final Map<K, T> instances;

	///////////////////////////////////////////////////////
	// Constructors
	public InstanceManager (final int initialCapacity) {
		instances = new HashMap<K, T>(initialCapacity);
	}

	///////////////////////////////////////////////////////
	//
	public <U extends T> U Register (final U idable) throws InstanceAlreadyRegisteredException {
		final K id = idable.GetId();

		if (instances.containsKey(id))
			throw new InstanceAlreadyRegisteredException(idable.toString());

		instances.put(id, idable);
		return idable;
	}

	public boolean Has (final K id) {
		return instances.containsKey(id);
	}

	public T Get (final K id) throws InstanceNotFoundException {
		final T result = instances.get(id);

		if (result == null)
			throw new InstanceNotFoundException(id.toString());

		return result;
	}

}
