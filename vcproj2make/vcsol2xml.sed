/^OFF ( *)Project\("([^"]+)"\) *= *"([^"]+)" *, *"([^"]+)" *, *"([^"]+)"[ ]*\x0d?$/{
	s//\1<Project\n\1\t\tid="\5"\n\1\t\tpath="\4"\n\1\t\tname="\3"\n\1\t\tparentref="\2"\n\1\t>/gp
}
/^OFF ((\t|[ ])*)ProjectSection\(ProjectDependencies\) *= *postProject *\x0d?$/{
	s//\1<ProjectSection type="Dependencies">/gp
}
/^OFF ((\t|[ ])*)(\{[0123456789abcdefABCDEF-]*\}) *= *(\{[0123456789abcdefABCDEF-]*\}) *\x0d?$/{
	s,,<idpair left="\3" right="\4" />,gp
}
