using System;
using csd2m.Utility;

namespace csd2m {
    class Program {
        static void Main (string[] args) {
            Console.WriteLine( ProjectIdExtensions.GetOrCreateProjectId("hello") );
        }
    }
}
