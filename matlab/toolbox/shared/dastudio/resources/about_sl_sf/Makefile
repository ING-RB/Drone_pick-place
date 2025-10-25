# File: toolbox/shared/dastudio/resources/about_sl_sf/Makefile
# Copyright 2020 The MathWorks, Inc.
# Purpose: move the images for the current release to a derived area where they will get packaged via retail.sdk
# Used by: matlab/toolbox/shared/dastudio/daabout.m
# Tested by: test/toolbox/slglue/system/aboutImages/tAboutImages.m
.PHONY: build clean
include $(MAKE_INCLUDE_DIR)/module_interface.mk

CURRENT_MATLAB_VERSION :=$(shell perl -e 'use XML::XPath; my $$p = XML::XPath->new(filename => "$(MWE_INSTALL)/VersionInfo.xml"); $$p = (($$p->findnodes("/MathWorks_version_info/release")))[0]; print $$p->string_value();')

build: derived/$(CURRENT_MATLAB_VERSION)

derived/$(CURRENT_MATLAB_VERSION):
	# Remove cruft from current and previous releases
	rm -rf derived/*

	# Create folder for current release. Ex: R2020b
	mkdir -p derived/$(CURRENT_MATLAB_VERSION)

	# Copy everything from the internal dir to current release
	$(info ==> Copying Simulink/Stateflow about images to derived area for release $(CURRENT_MATLAB_VERSION) )
	cp -p -P -f $(MWE_INSTALL)/toolbox/shared/dastudio/internal/about_sl_sf/generated_images/$(CURRENT_MATLAB_VERSION)/* derived/$(CURRENT_MATLAB_VERSION)

clean:
	rm -rf derived/*
