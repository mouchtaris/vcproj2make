namespace csd2m.Utility {
    struct ProjectName {
        private readonly string _value;
        public ProjectName (string value) {
            _value = value;
        }

        public string StringValue {
            get { return _value; }
            private set { }
        }

        public override string ToString () {
            string result = "Name[" + _value + "]";
            return result;
        }

        public bool Equals (ProjectName other) {
            bool result = _value.Equals( other._value );
            return result;
        }
        public override bool Equals (object obj) {
            bool result = false;
            var other = obj as ProjectName?;
            if ( other != null )
                result = Equals( other );
            return result;
        }

        public override int GetHashCode () {
            int result = _value.GetHashCode( );
            return result;
        }

        ////////////////////////////////////////////////////////////////
        public static bool operator == (ProjectName me, ProjectName other) {
            bool result = me.Equals( other );
            return result;
        }
        public static bool operator != (ProjectName me, ProjectName other) {
            bool result = !(me == other);
            return result;
        }

        public static explicit operator string (ProjectName me) {
            string result = me.StringValue;
            return result;
        }
    }
}
