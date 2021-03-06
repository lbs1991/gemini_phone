# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ====================================================================
#
# Define the main configuration variables, and read the host-specific
# configuration file that is normally generated by build/host-setup.sh
#
# ====================================================================

# Detect the NDK installation path by processing this Makefile's location.
# This assumes we are located under $NDK_ROOT/build/core/main.mk
#
NDK_ROOT := $(lastword $(MAKEFILE_LIST))
NDK_ROOT := $(strip $(NDK_ROOT:%build/core/main.mk=%))
ifeq ($(NDK_ROOT),)
    # for the case when we're invoked from the NDK install path
    NDK_ROOT := .
else
    # get rid of trailing slash
    NDK_ROOT := $(NDK_ROOT:%/=%)
endif
ifdef NDK_LOG
    $(info Android NDK: NDK installation path auto-detected: '$(NDK_ROOT)')
endif

include $(NDK_ROOT)/build/core/init.mk

# ====================================================================
#
# Read all application configuration files
#
# Each 'application' must have a corresponding Application.mk file
# located in apps/<name> where <name> is a liberal name that doesn't
# contain any space in it, used to uniquely identify the
#
# See docs/ANDROID-MK.TXT for their specification.
#
# ====================================================================

NDK_ALL_APPS :=
NDK_APPS_ROOT := $(NDK_ROOT)/apps

# Get the list of apps listed under apps/*
NDK_APPLICATIONS := $(wildcard $(NDK_APPS_ROOT)/*)
NDK_ALL_APPS     := $(NDK_APPLICATIONS:$(NDK_APPS_ROOT)/%=%)

# Check that APP is not empty
APP := $(strip $(APP))
ifndef APP
  $(call __ndk_info,\
    The APP variable is undefined or empty.)
  $(call __ndk_info,\
    Please define it to one of: $(NDK_ALL_APPS))
  $(call __ndk_info,\
    You can also add new applications by writing an Application.mk file.)
  $(call __ndk_info,\
    See docs/APPLICATION-MK.TXT for details.)
  $(call __ndk_error, Aborting)
endif

# Check that all apps listed in APP do exist
_bad_apps := $(strip $(filter-out $(NDK_ALL_APPS),$(APP)))
ifdef _bad_apps
  $(call __ndk_info,\
    APP variable defined to unknown applications: $(_bad_apps))
  $(call __ndk_info,\
    You might want to use one of the following: $(NDK_ALL_APPS))
  $(call __ndk_error, Aborting)
endif

# Check that all apps listed in APP have an Application.mk

$(foreach _app,$(APP),\
  $(eval _application_mk := $(strip $(wildcard $(NDK_ROOT)/apps/$(_app)/Application.mk))) \
  $(call ndk_log,Parsing $(_application_mk))\
  $(if $(_application_mk),\
    $(eval include $(BUILD_SYSTEM)/add-application.mk)\
  ,\
    $(call __ndk_info,\
      Missing file: apps/$(_app)/Application.mk !)\
    $(call __ndk_error, Aborting)\
  )\
)

# clean up environment, just to be safe
$(call clear-vars, $(NDK_APP_VARS))

ifeq ($(strip $(NDK_ALL_APPS)),)
  $(call __ndk_info,\
    The NDK could not find a proper application description under apps/*/Application.mk)
  $(call __ndk_info,\
    Please follow the instructions in docs/NDK-APPS.TXT to write one.)
  $(call __ndk_error, Aborting)
endif

# now check that APP doesn't contain an unknown app name
# if it does, we ignore them if there is at least one known
# app name in the list. Otherwise, abort with an error message
#
_unknown_apps := $(filter-out $(NDK_ALL_APPS),$(APP))
_known_apps   := $(filter     $(NDK_ALL_APPS),$(APP))

NDK_APPS := $(APP)

$(if $(_unknown_apps),\
  $(if $(_known_apps),\
    $(call __ndk_info,WARNING:\
        Removing unknown names from APP variable: $(_unknown_apps))\
    $(eval NDK_APPS := $(_known_apps))\
   ,\
    $(call __ndk_info,\
        The APP variable contains unknown app names: $(_unknown_apps))\
    $(call __ndk_info,\
        Please use one of: $(NDK_ALL_APPS))\
    $(call __ndk_error, Aborting)\
  )\
)

$(call __ndk_info,Building for application '$(NDK_APPS)')

# Where all app-specific generated files will be stored
NDK_APP_OUT := $(NDK_ROOT)/out/apps

include $(BUILD_SYSTEM)/build-all.mk
