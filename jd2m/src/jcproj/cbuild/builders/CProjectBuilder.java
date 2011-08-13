package jcproj.cbuild.builders;

import java.nio.file.Path;
import java.util.LinkedList;
import java.util.List;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;
import jd2m.cbuild.CProperties;
import jd2m.util.Name;
import jd2m.util.ProjectId;

public final class CProjectBuilder {
    private boolean used = false;
    public CProject MakeProject () {
        if (used)
            throw new RuntimeException("Cannot reuse builder");
        if (_location       == null     ||
            _name           == null     ||
            _id             == null     ||
            _configuration  == null     ||
            _target         == null     ||
            _targetExt      == null     ||
            _output         == null     ||
            _intermediate   == null     ||
            _api            == null     ||
            _type           == null
        )
            throw new RuntimeException("Builder not complete");

        used = true;
        final CProject result = new CProject(_location, _name, _id,
                _configuration, _target, _targetExt, _output, _intermediate,
                _api, _type);
        for (final ProjectId depId: _deps)
            result.AddDependency(depId);
        result.AddProperties(_props);
        for (final Path src: _sources)
            result.AddSource(src);

        return result;
    }

    private final List<CProperties> _props = new LinkedList<CProperties>();
    private Path                    _location;
    private Name                    _name;
    private ProjectId               _id;
    private String                  _configuration;
    private String                  _target;
    private String                  _targetExt;
    private Path                    _output;
    private Path                    _intermediate;
    private Path                    _api;
    private CProjectType            _type;
    private final List<ProjectId>   _deps = new LinkedList<ProjectId>();
    private final List<Path>        _sources = new LinkedList<Path>();

    public void AddProperty (final CProperties p)   { _props.add(p);    }
    public void SetLocation (final Path l       )   { _location = l;    }
    public void SetName     (final Name n       )   { _name = n;        }
    public void SetId       (final ProjectId id )   { _id = id;         }
    public void SetConfiguration (final String c)   { _configuration =c;}
    public void SetTarget   (final String trg   )   { _target = trg;    }
    public void SetExt      (final String ext   )   { _targetExt = ext; }
    public void SetOutput   (final Path out     )   { _output = out;    }
    public void SetIntermediate (final Path intm)   { _intermediate = intm; }
    public void SetApiDirectory (final Path api )   { _api = api;       }
    public void SetType     (final CProjectType t)  { _type = t;        }
    public void AddDependency(final ProjectId dep)  { _deps.add(dep);   }
    public void AddSource   (final Path src     )   { _sources.add(src);}

    public Path GetOutput   ()  { return _output; }
}
