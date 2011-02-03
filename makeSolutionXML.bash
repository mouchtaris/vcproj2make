#!/bin/dash

if [ -z "$1" ]
	then	echo 'Give the solution filepath'
		exit 1
fi

root_name='VisualStudioSolution'
echo "<$root_name>"
sed --regexp-extended --file 'deltaide2make/vcsol2xml.sed' "$1"
echo "</$root_name>"
