shell = /bin/bash

FIRST_PROJECT = Tools/Delta/DLLs/VirtualMachineComponents/Project
OTHER_MAKE = 'BliblibloDebug|Win32.mk'

all:
	{ cd $(FIRST_PROJECT) && make -f $(OTHER_MAKE) all ; } 2>&1 | tee build_Makefile_all.log
clean:
	{ cd $(FIRST_PROJECT) && make -f $(OTHER_MAKE) clean ; } 2>&1 | tee build_Makefile_clean.log

