#!/usr/bin/env bash

component_define \
  "rectangle" \
  "Rectangle" \
  "Keyboard window snapping; choose this or AeroSpace, not both" \
  "Window Management" \
  "false" \
  "false" \
  "" \
  "cask" \
  "rectangle" \
  "" \
  "" \
  "" \
  "" \
  ""

component_conflict "rectangle" "aerospace"
