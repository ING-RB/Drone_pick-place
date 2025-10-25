# Copyright 2017-2020 The MathWorks, Inc.
# File: matlab/simulink/internal/tools/validate_action.mk
# Abstract:
#   since actions data is situated in <!CDATA[ section
#   XML parser can't validate actions against XML schema
#   validate_action extract <actions>...</actions> fragments
#   and validate them against actions.xsd schema
#

include $(SANDBOX_ROOT)/resources/internal/makerules/private/resource_baseder_defn.mk

# mwdebug.mk is used to get at HIDE define
include $(MAKE_INCLUDE_DIR)/mwdebug.mk

VALIDATE_ACTION =  $(SANDBOX_ROOT)/toolbox/shared/diagnostic/validation/validate_action.pl

# Validation<actions>elements rules
define VALIDATE_ACTION_RULES
 $(if $(findstring $1,$(EN_XML_FILES)),$(HIDE) perl $(VALIDATE_ACTION) $1)
endef

# EXTENDED_VALIDATION_RULES must be set in-order to execute custom 
# rules on the xml files.
EXTENDED_VALIDATION_RULES = $(VALIDATE_ACTION_RULES)

