package jd2m.project;

import java.io.File;
import jd2m.solution.VariableEvaluator;
import jd2m.util.Name;
import jd2m.util.ProjectId;

final class XmlAnalyserArguments {
    // for validation
    final Name              name;
    final ProjectId         id;
    final File              location;
    final VariableEvaluator ve;

    XmlAnalyserArguments (  final Name              _name,
                            final ProjectId         _id,
                            final File              _location,
                            final VariableEvaluator _ve)
    {
        name        = _name;
        id          = _id;
        location    = _location;
        ve          = _ve;
    }
}
