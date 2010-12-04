package jd2m.cbuild.builders;

import java.io.File;
import java.util.LinkedList;
import java.util.List;
import jd2m.cbuild.CProject;
import jd2m.cbuild.CProjectType;
import jd2m.cbuild.CProperties;
import jd2m.util.ProjectId;

public final class CProjectBuilder {
    private boolean used = false;
    public CProject MakeProject () {
        if (used)
            throw new RuntimeException("Cannot reuse builder");
        if (_location       == null     ||
            _name           == null     ||
            _id             == null     ||
            _target         == null     ||
            _targetExt      == null     ||
            _output         == null     ||
            _intermediate   == null     ||
            _api            == null     ||
            _type           == null
        )
            throw new RuntimeException("Builder not complete");

        used = true;
        final CProject result = new CProject(_location, _name, _id, _target,
                _targetExt, _output, _intermediate, _api, _type);
        for (final String depId: _deps)
            result.AddDependency(depId);
        result.AddProperties(_props);
        for (final File src: _sources)
            result.AddSource(src);

        return result;
    }

    private final List<CProperties> _props = new LinkedList<>();
    private File              _location;
    private String            _name;
    private ProjectId         _id;
    private String            _target;
    private String            _targetExt;
    private File              _output;
    private File              _intermediate;
    private File              _api;
    private CProjectType      _type;
    private final List<String>      _deps = new LinkedList<>();
    private final List<File>        _sources = new LinkedList<>();

    public void AddProperty (final CProperties p)   { _props.add(p);    }
    public void SetLocation (final File l       )   { _location = l;    }
    public void SetName     (final String n     )   { _name = n;        }
    public void SetId       (final ProjectId id )   { _id = id;         }
    public void SetTarget   (final String trg   )   { _target = trg;    }
    public void SetExt      (final String ext   )   { _targetExt = ext; }
    public void SetOutput   (final File out     )   { _output = out;    }
    public void SetIntermediate (final File intm)   { _intermediate = intm; }
    public void SetApiDirectory (final File api )   { _api = api;       }
    public void SetType     (final CProjectType t)  { _type = t;        }
    public void AddDependency(final String dep  )   { _deps.add(dep);   }
    public void AddSource   (final File src     )   { _sources.add(src);}

}
