### Project
/^((\t|[ ])*)Project\("([^"]+)"\) *= *"([^"]+)" *, *"([^"]+)" *, *"([^"]+)"[ ]*\x0d?$/{
# 1->whitespace, 3->parentref, 4->Name, 5->path, 6->ID
	s//\1<Project\n\1\t\tid="\6"\n\1\t\tpath="\5"\n\1\t\tname="\4"\n\1\t\tparentref="\3"\n\1\t>/gp
	d
}
/^((\t|[ ])*)EndProject *\x0d?$/{
	s,,\1</Project>,gp
	d
}
### ProjectSection
/^((\t|[ ])*)ProjectSection\(([^)]+)\) *= *(pre|post)Project *\x0d?$/{
	s//\1<ProjectSection type="\3">/gp
	d
}
/^((\t|[ ])*)EndProjectSection *\x0d?$/{
	s,,\1</ProjectSection>,gp
	d
}
### Pair
/^((\t|[ ])*)([}{0123456789a-zA-Z.\\\|"-]*) *= *([}{0-9a-zA-Z.\\\|"-]*) *\x0d?$/{
	# Save original pattern space
	h
	# Bring left-value to pattern space
	s,,\3,g
	# Escape any double quotes
	s,",\&quot;,g
	# Append escaped left value to hold space and get right-value to pattern space
	H;g;
	# ... select first line
	s,^(.*)\n(.*)$,\1,g
	# ... reapply RegExp
	s/^((\t|[ ])*)([}{0123456789a-zA-Z.\\\|"-]*) *= *([}{0-9a-zA-Z.\\\|"-]*) *\x0d?$/\4/g
	# ... escape any double quotes
	s,",\&quot;,g
	# ... append escaped right value to hold space 
	H
	# Bring original pattern to pattern space and extract inital whitespace
	g
	# ... select first line
	s,(.*)\n(.*)\n(.*),\1,g
	# ... reapply RegExp
	s/^((\t|[ ])*)([}{0123456789a-zA-Z.\\\|"-]*) *= *([}{0-9a-zA-Z.\\\|"-]*) *\x0d?$/\1/g
	# ... append initial whitespace to hold space
	H
	# Add result components to hold space
	s,^.*$,<Pair left=",g;H
	s,^.*$," right=",g;H
	s,^.*$," />,g;H
	# Pattern space at this point:
	# 1. (unusable) original pattern
	# 2. piece 3: left value escaped
	# 3. piece 5: right value escaped
	# 4. piece 1: initial whitespace
	# 5. piece 2: first
	# 6. piece 4: middle
	# 7. piece 6: last
	# ---
	# Compose result
	g
	s,^(.*)\n(.*)\n(.*)\n(.*)\n(.*)\n(.*)\n(.*)$,\4\5\2\6\3\7,g
	p
	d
}
### Global
/^((\t|[ ])*)Global *\x0d?$/{
	s//\1<Global>/gp
	d
}
/^((\t|[ ])*)EndGlobal *\x0d?$/{
	s,,\1</Global>,gp
	d
}
### GlobalSection
/^((\t|[ ])*)GlobalSection\(([^)]+)\) *= *(pre|post)Solution *\x0d?$/{
	s//\1<GlobalSection type="\3">/gp
	d
}
/^((\t|[ ])*)EndGlobalSection *\x0d?$/{
	s,,\1</GlobalSection>,gp
	d
}

### Ignore patterns
#/^(\t|[ ])*ProjectSection\(WebsiteProperties\) *= *preProject *\x0d?$/d
#/^(\t|[ ])*Debug\.AspNetCompiler\.Debug *= *"True" *\x0d?$/d
#/^(\t|[ ])*Release\.AspNetCompiler\.Debug *= *"False" *\x0d?$/d
##
#/^(\t|[ ])*ProjectSection\(SolutionItems\) *= *preProject *\x0d?$/d
#/^(\t|[ ])*Debug\|Win32 *= *Debug\|Win32/d
#/^(\t|[ ])*Release\|Win32 *= *Release\|Win32/d
##
/^(\t| )*Microsoft Visual Studio Solution File, Format Version 9\.00 *\x0d?$/d
/^(\t| )*#.*$/d
# UTF-8 bit order
/^\xef\xbb\xbf\x0d?$/d

s/.*/ERROR: Unrecognised line: &/g

