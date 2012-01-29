package jcproj.util;

import java.util.HashMap;
import java.util.Map;

public class InstanceManager<T extends Identifiable> {

	///////////////////////////////////////////////////////
	// state
	private final Map<String, T> instances = new HashMap<String, T>(20);

	///////////////////////////////////////////////////////
	//
	public <U extends T> U Register (final U idable) throws InstanceAlreadyRegisteredException {
		final String id = idable.GetId();

		if (instances.containsKey(id))
			throw new InstanceAlreadyRegisteredException(id);

		instances.put(id, idable);
		return idable;
	}

	public boolean Has (final String id) {
		return instances.containsKey(id);
	}

	public T Get (final String id) throws InstanceNotFoundException {
		final T result = instances.get(id);

		if (result == null)
			throw new InstanceNotFoundException(id);

		return result;
	}

}
