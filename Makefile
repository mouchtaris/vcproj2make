SHELL = /bin/bash

FIRST_PROJECT = Tools/DeltaAnsiVMDebug/Project
SECOND_PROJECT = Tools/DeltaAnsiCompiler/Project
THIRD_PROJECT = Tools/DeltaConsoleDebugger

OTHER_MAKE_DEBUG = 'BliblibloDebug|Win32.mk'
OTHER_MAKE_RELEASE = 'BliblibloRelease|Win32.mk'

MAKE = make #-j 4

all:
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) all && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) all && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) all && popd && \
		true ; } 2>&1 | tee build_Makefile_all_debug.log
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) all && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) all && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) all && popd && \
		true ; } 2>&1 | tee build_Makefile_all_release.log
clean:
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) clean && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) clean && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) clean && popd && \
		true ; } 2>&1 | tee build_Makefile_clean_debug.log
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) clean && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) clean && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) clean && popd && \
		true ; } 2>&1 | tee build_Makefile_clean_release.log
rclean:
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) rclean && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) rclean && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_DEBUG) rclean && popd && \
		true ; } 2>&1 | tee build_Makefile_rclean_debug.log
	{ pushd $(FIRST_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) rclean && popd && \
		pushd $(SECOND_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) rclean && popd && \
		pushd $(THIRD_PROJECT) && $(MAKE) -f $(OTHER_MAKE_RELEASE) rclean && popd && \
		true ; } 2>&1 | tee build_Makefile_rclean_release.log

