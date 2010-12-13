using System.Collections.Generic;
using System;

namespace csd2m.Utility {
    sealed class ProjectId {
        private static readonly IDictionary<string, ProjectId> _Instances =
                new Dictionary<string, ProjectId>(70);
        private static ProjectId _tryGet (string projid) {
            ProjectId result;
            bool exists = _Instances.TryGetValue( projid, out result );
            if ( !exists )
                result = null;
            return result;
        }

        public static bool ProjectIdExists (string projid) {
            bool result = _tryGet( projid ) != null;
            return result;
        }

        public static ProjectId GetProjectId (string projid) {
            ProjectId result = _tryGet( projid );
            if ( result == null )
                throw new Exception( "projid:" + projid + " does not exist" );
            return result;
        }

        public static ProjectId CreateProjectId (string projid) {
            ProjectId result = _tryGet( projid );
            if ( result != null )
                throw new Exception( "projid:" + projid + " already exists" );
            result = new ProjectId( projid );
            return result;
        }

        ////////////////////////////////////////////////////////////////
        private readonly string _value;
        private ProjectId (string value) {
            _value = value;
        }

        ////////////////////////////////////////////////////////////////
        public override string ToString () {
            return "ID[" + _value + "]";
        }

        public bool Equals (ProjectId other) {
            bool result = _value.Equals( other._value );
            return result;
        }
        public override bool Equals (object obj) {
            bool result = false;
            var other = obj as ProjectId;
            if ( other != null )
                result = Equals( other );
            return result;
        }

        public override int  GetHashCode () {
            int result = _value.GetHashCode();
            return result;
        }

        ////////////////////////////////////////////////////////////////
        public string StringValue {
            get { return _value; }
            private set { }
        }

        ////////////////////////////////////////////////////////////////
        public static bool operator == (ProjectId me, ProjectId other) {
            bool result = me.Equals( other );
            return result;
        }
        public static bool operator != (ProjectId me, ProjectId other) {
            bool result = !(me == other);
            return result;
        }

        public static explicit operator string (ProjectId pid) {
            string result = pid.StringValue;
            return result;
        }

    }
}
