package jcproj.util;

import java.lang.ref.WeakReference;
import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

public class Patterns {

	///////////////////////////////////////////////////////
	//
	public static Pattern Pipe () {
		return Get("Pipe");
	}

	public static Pattern Dot () {
		return Get("Dot");
	}

	///////////////////////////////////////////////////////
	//
	private static WeakReference<Map<String, WeakReference<Pattern>>> patterns = new WeakReference<Map<String, WeakReference<Pattern>>>(null);

	private static Pattern Get (final String what) {
		try {
			Map<String, WeakReference<Pattern>> patternsMap = patterns.get();
			if (patternsMap == null) {
				patternsMap = CreateMapOfReferences();
				patterns = new WeakReference<Map<String, WeakReference<Pattern>>>(patternsMap);
			}

			WeakReference<Pattern> patternRef = patternsMap.get(what);
			if (patternRef == null) {
				patternRef = new WeakReference<Pattern>(null);
				patternsMap.put(what, patternRef);
			}

			Pattern pattern = patternRef.get();
			if (pattern == null) {
				pattern = CreatePattern(what);
				patternsMap.put(what, new WeakReference<Pattern>(pattern));
			}

			return pattern;
		} catch (InvocationTargetException ex) {
			throw new AssertionError("", ex);
		} catch (NoSuchMethodException ex) {
			throw new AssertionError("", ex);
		} catch (SecurityException ex) {
			throw new AssertionError("", ex);
		} catch (IllegalArgumentException ex) {
			throw new AssertionError("", ex);
		} catch (IllegalAccessException ex) {
			throw new AssertionError("", ex);
		}
	}

	private static Map<String, WeakReference<Pattern>> CreateMapOfReferences () {
		return new HashMap<String, WeakReference<Pattern>>(10);
	}
	private static Pattern CreatePattern (final String what) throws NoSuchMethodException, IllegalAccessException, IllegalArgumentException, InvocationTargetException {
		return (Pattern) Patterns.class.getDeclaredMethod("Create" + what).invoke(null);
	}

	private static Pattern CreatePipe () {
		return Pattern.compile("\\|");
	}
	private static Pattern CreateDot () {
		return Pattern.compile("\\.");
	}
	///////////////////////////////////////////////////////
	// private
	private Patterns () {}
}
