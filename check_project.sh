#!/bin/bash

# EMBA - EMBEDDED LINUX ANALYZER
#
# Copyright 2020-2022 Siemens AG
# Copyright 2020-2022 Siemens Energy AG
#
# EMBA comes with ABSOLUTELY NO WARRANTY. This is free software, and you are
# welcome to redistribute it under the terms of the GNU General Public License.
# See LICENSE file for usage of this software.
#
# EMBA is licensed under GPLv3
#
# Author(s): Michael Messner, Pascal Eckmann

# Description:  Check all shell scripts inside ./helpers, ./modules, emba.sh and itself with shellchecker

GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # no color

HELP_DIR="./helpers"
MOD_DIR="./modules"
CONF_DIR="./config"

SOURCES=()
MODULES_TO_CHECK_ARR=()

import_config_scripts() {
  HELPERS=$(find "$CONF_DIR" -iname "*.sh" 2>/dev/null)
  for LINE in $HELPERS; do
    if (file "$LINE" | grep -q "shell script"); then
      echo "$LINE"
      SOURCES+=("$LINE")
    fi
  done
}

import_helper() {
  HELPERS=$(find "$HELP_DIR" -iname "*.sh" 2>/dev/null)
  for LINE in $HELPERS; do
    if (file "$LINE" | grep -q "shell script"); then
      echo "$LINE"
      SOURCES+=("$LINE")
    fi
  done
}

import_module() {
  MODULES=$(find "$MOD_DIR" -iname "*.sh" 2>/dev/null)
  for LINE in $MODULES; do
    if (file "$LINE" | grep -q "shell script"); then
      echo "$LINE"
      SOURCES+=("$LINE")
    fi
  done
}

check()
{
  echo -e "\\n""$ORANGE""$BOLD""Embedded Linux Analyzer Shellcheck""$NC""\\n""$BOLD""=================================================================""$NC"
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo -e "\\n""$ORANGE""Shellcheck not found!""$NC""\\n""$ORANGE""Install shellcheck via 'apt-get install shellcheck'!""$NC\\n"
    exit 1
  fi

  echo -e "\\n""$GREEN""Run shellcheck on this script:""$NC""\\n"
  if shellcheck ./check_project.sh || [[ $? -ne 1 && $? -ne 2 ]]; then
    echo -e "$GREEN""$BOLD""==> SUCCESS""$NC""\\n"
  else
    echo -e "\\n""$ORANGE$BOLD==> FIX ERRORS""$NC""\\n"
    MODULES_TO_CHECK_ARR+=("check_project.sh")
  fi

  echo -e "\\n""$GREEN""Run shellcheck on installer:""$NC""\\n"
  if shellcheck ./installer.sh || [[ $? -ne 1 && $? -ne 2 ]]; then
    echo -e "$GREEN""$BOLD""==> SUCCESS""$NC""\\n"
  else
    echo -e "\\n""$ORANGE$BOLD==> FIX ERRORS""$NC""\\n"
    MODULES_TO_CHECK_ARR+=("installer.sh")
  fi

  echo -e "\\n""$GREEN""Load all files for check:""$NC""\\n"
  echo "./emba.sh"
  import_helper
  import_config_scripts
  import_module

  echo -e "\\n""$GREEN""Run shellcheck:""$NC""\\n"
  for SOURCE in "${SOURCES[@]}"; do
    echo -e "\\n""$GREEN""Run shellcheck on $SOURCE""$NC""\\n"
    if shellcheck -P "$HELP_DIR":"$MOD_DIR" -a ./emba.sh "$SOURCE" || [[ $? -ne 1 && $? -ne 2 ]]; then
      echo -e "$GREEN""$BOLD""==> SUCCESS""$NC""\\n"
    else
      echo -e "\\n""$ORANGE""$BOLD""==> FIX ERRORS""$NC""\\n"
      MODULES_TO_CHECK_ARR+=("$SOURCE")
    fi
  done
}

summary() {
  if [[ "${#MODULES_TO_CHECK_ARR[@]}" -gt 0 ]]; then
    echo -e "\\n\\n""$GREEN$BOLD""SUMMARY:$NC\\n"
    echo -e "Modules to check: ${#MODULES_TO_CHECK_ARR[@]}\\n"
    for MODULE in "${MODULES_TO_CHECK_ARR[@]}"; do
      echo -e "$ORANGE$BOLD==> FIX MODULE: ""$MODULE""$NC"
    done
    echo -e "$ORANGE""WARNING: Fix the errors before pushing to the EMBA repository!"
  fi
}

check
summary

