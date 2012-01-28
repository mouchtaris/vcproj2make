package jcproj.loading;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 *
 * @date (of rebirth) 14th August 2011
 * @author muhtaris
 */
@SuppressWarnings("FinalClass")
public final class VariableEvaluator {

	///////////////////////////////////////////////////////
	// Public fields

	public static final String OutDir			= "OutDir";
	public static final String ConfigurationName= "ConfigurationName";
	public static final String SolutionDir		= "SolutionDir";
	public static final String ProjectName		= "ProjectName";

	///////////////////////////////////////////////////////
	// Public methods

	public VariableEvaluator (final String solutionDirectory) {
		persistent.put(SolutionDir, solutionDirectory);
		AddGlobalVariable("ACE_ROOT");		// TODO move to app
		AddGlobalVariable("DELTAIDEDEPS");
		AddGlobalVariable("DELTA");
		AddGlobalVariable("TAO_ROOT");
	}

	///////////////////////////////////////////////////////

	public void SetOutDir (final String value) {
		final String previous = resettable.put(OutDir, value);
		assert previous == null;
	}

	///////////////////////////////////////////////////////

	public void SetConfigurationName (final String value) {
		final String previous = resettable.put(ConfigurationName, value);
		assert previous == null;
	}

	///////////////////////////////////////////////////////

	public void SetProjectName (final String value) {
		final String previous = resettable.put(ProjectName, value);
		assert previous == null;
	}

	///////////////////////////////////////////////////////

	public void Reset () {
		resettable.clear();
	}

	///////////////////////////////////////////////////////

	public void AddGlobalVariable (final String name) {
		final boolean added = globals.add(name);
		assert added;
	}

	///////////////////////////////////////////////////////

	public String Evaluate (final String variable) {
		final String result = resettable.get(variable);
		assert result != null || globals.contains(variable);
		return result;
	}

	///////////////////////////////////////////////////////


	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State

	private final Map<String, String>	resettable	= new HashMap<String, String>(20);
	private final Map<String, String>	persistent	= new HashMap<String, String>(20);
	private final Set<String>			globals		= new HashSet<String>(20);
}
