package jd2m.project;

import java.nio.file.Path;
import jd2m.solution.PathResolver;
import jd2m.solution.VariableEvaluator;
import jd2m.util.Name;
import jd2m.util.ProjectId;

final class XmlAnalyserArguments {
    // for validation
    final Name              name;
    final ProjectId         id;
    final Path              location;
    final String            relativeLocation;   // always unix path
    final VariableEvaluator ve;
    final PathResolver      pathResolver;

    XmlAnalyserArguments (  final Name              _name,
                            final ProjectId         _id,
                            final Path              _location,
                            final String            _relativeLocation,
                            final VariableEvaluator _ve,
                            final PathResolver      _pathResolver)
    {
        name                = _name;
        id                  = _id;
        location            = _location;
        relativeLocation    = _relativeLocation;
        ve                  = _ve;
        pathResolver        = _pathResolver;
    }
}
