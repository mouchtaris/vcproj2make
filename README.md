# Visual Studio projects to Makefiles

This project aimed to be an automated way of transcribing project building information
from the visual studio project file format to makefiles.

## General architecture
The general architecture is that all VS files are first parsed into data structures
that reflect the VS project files packed information. Then, from these structures,
a more generic project description format is used (`cproj`). Finally, using cproj
data structures as input, any kind of build-system generator can be used. In this
project, a makefile generator is provided.

### cproj
All packages under cproj.\* are related to loading VS project files and translating
them to the generic CProj format.

### jd2m
Packages under jd2m.\* are specific to the [delta language VS project files](http://www.ics.forth.gr/hci/files/plang/Delta/Delta.html#si_download) and not of any use to the general
VS-to-make translation process. Nevertheless, they provide good reference and testing
for the actual project core.

In addition, there may still be some generic-purpose functionality left over
in there, as the factoring-out of core-functionality was not carried out
throughout.

## Status
This project is heavily outdated and un-maintained but it has very good potential
to be revived and maybe even be useful.

There are lots of bad practices happening in the code, from the lack of documentation
to the use of weird software patterns or even unnecessary architectural layers.

This project is currently not being reviewed for maintenance. Maybe in the future it will.

## Functional status
This project should be functional for VS2010 project and solution files and later.

Last time it was under development, it had been severely tested with translating
[this project files](http://www.ics.forth.gr/hci/files/plang/Delta/Delta.html#si_download)
into makefiles, and the result was successful. The Delta Language build specifications
are (were at the time of testing) quite complicated (preprocessor definitions, use of visual studio project-property-"script" files, etc), and therefore it is considered
that this project works well for the mainstream cases.

This project has not been tested again and there are currently no instructions about how to
build and how to translate VS solutions. There may be one day, or appear suddenly if there is public interest.

In the mean-time, there is a sample translation process as a test/example
in `cproj.Main`.

