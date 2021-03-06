package jcproj.cbuild;

import java.util.List;

import static jcproj.cbuild.CProject.CreatePropertiesList;

/**
 *
 * @author muhtaris
 */
@SuppressWarnings("FinalClass")
public final class CPropertiesTransformationApplicator {

	private CPropertiesTransformationApplicator () {
	}

	public static void ApplyToSolution (final CPropertiesTransformation trans,
										final CSolution solution)
	{
		for (final CProject project: solution.GetCProjectIterable())
			ApplyToProject(trans, project);
	}

	public static void ApplyToProject (	final CPropertiesTransformation trans,
										final CProject project)
	{
		final List<CProperties> props = project.GetProps();
		// for debugging and asserting
		final int oldSize = props.size();

		final List<CProperties> replacements = CreatePropertiesList();
		for (final CProperties prop: props)
			replacements.add(trans.ApplyIfApplicableTo(prop));

		final int replacementsSize = replacements.size();
		assert replacementsSize == oldSize;

		props.clear();
		assert props.isEmpty();

		props.addAll(replacements);
		assert props.size() == oldSize;
	}
}
