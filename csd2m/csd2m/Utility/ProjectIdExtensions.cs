namespace csd2m.Utility {
    static class ProjectIdExtensions {

        public static ProjectId GetOrCreateProjectId (string projid) {
            ProjectId result;

            if ( ProjectId.ProjectIdExists( projid ) )
                result = ProjectId.GetProjectId( projid );
            else
                result = ProjectId.CreateProjectId( projid );

            return result;
        }
    }
}
