using System;
using csd2m.Utility;

namespace csd2m {
    class Program {
        public delegate void Writer (string format, params object[] arg);
        public delegate void WriterS (object value);
        static void Main (string[] args) {
            WriterS wr = Console.WriteLine;
            wr( ProjectIdExtensions.GetOrCreateProjectId("hello") );
            wr( Configuration.Projects + "jimmis" );
            wr( Configuration.Projects + "jammis" );
            wr( Configuration.Projects["jimmis"] != Configuration.Projects["jammis"] );
        }
    }
}
