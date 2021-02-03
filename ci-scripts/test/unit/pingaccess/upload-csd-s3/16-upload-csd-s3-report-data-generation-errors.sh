#!/bin/bash

# Source support libs referenced by the tested script
. "${PROJECT_DIR}"/profiles/aws/pingaccess/hooks/utils.lib.sh
. "${PROJECT_DIR}"/profiles/aws/pingaccess/hooks/util/upload-csd-s3-utils.sh

kubectl() {
  echo ""
}

cd() {
  echo ""
}

find() {
  echo "support-data-ping-pingaccess-1-20210125201530.zip"
}

skbn() {
  echo ""
}

collect-data() {
  return 1
}

oneTimeSetUp() {
  export HOOKS_DIR="${PROJECT_DIR}"/profiles/aws/pingaccess/hooks
  export VERBOSE=false
}

oneTimeTearDown() {
  unset HOOKS_DIR
  unset VERBOSE
}

testUploadPingAccessCsdReportDataGenerationErrors() {

  script_to_test="${PROJECT_DIR}"/profiles/aws/pingaccess/hooks/82-upload-csd-s3.sh
  result=$(. "${script_to_test}")

  assertEquals "Expected an exit code of 1 but the script returned with a different code with a result of:  $result" 1 $?

  # Integration tests rely on the zip file name being printed at the end
  last_line=$(echo "${result}" | tail -1)
  expected_log_msg="Return code was: 1"
  assertEquals "Expected $expected_log_msg to be the last line in the output but it was: ${last_line}" "${expected_log_msg}" "${last_line}"
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}