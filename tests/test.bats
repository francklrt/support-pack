#!/usr/bin/env bats
#
# Test suite for support-pack.
# Run this test suite in the current directory with:
#
#   $ bats .
#

# Use this to debug from bats.
# Example:
#   echo "Hello" | printer
#
printer()
{
    sed 's/^/# /' >&3
}

# Test setup executed by bats before any test.
#
setup()
{
    rm -rf testdir
    mkdir testdir
    cd testdir
    SUPPORT_PACK="../../support-pack.sh"
    CONFDIR=".."
}

# Test teardown executed by bats after any test.
#
teardown()
{
    cd ..
    rm -rf testdir
}

# Most test in this test suite will run the support-pack command using a
# test-specific conf file in this directory. The run_conf commands does this and
# extract the resulting archive in the current directory for inspection.
#
run_conf()
{
    local conf="${1}"
    run ${SUPPORT_PACK} ${CONFDIR}/${conf} -o ./support-pack.tar.gz
    tar -xf support-pack.tar.gz
}

# Generates an archive with a single support-pack.txt file.
@test "Empty conf" {
    run_conf empty.conf
    [ -f support-pack.txt ]
}

# Generates an archive with a hello.txt file and check its content.
@test "Hello conf" {
    run_conf hello.conf
    [ -f support-pack.txt ]
        cat  <<EOF | cmp - support-pack.txt
[INFO ] Exec command "echo hello"
[INFO ] Created file "hello.txt"
EOF

    [ -f hello.txt ]
    cat  <<EOF | cmp - hello.txt
[SUPPORT-PACK] >>>> echo hello
hello

EOF
}

# Test a command that fails and check that support-pack.txt contains traces of
# this.
@test "Failed command conf" {
    run_conf failed_command.conf
    [ -f support-pack.txt ]
    cat  <<EOF | cmp - support-pack.txt
[INFO ] Exec command "command_that_fails"
[ERROR] "command_that_fails" returned a non-zero error code: 1
	-> This is an error
[INFO ] Created file "command_that_fails.txt"
EOF

    [ -f command_that_fails.txt ]
    cat  <<EOF | cmp - command_that_fails.txt
[SUPPORT-PACK] >>>> command_that_fails

EOF
}

# If a conf file does not redirect command outputs to log files, the output is
# catched by the support-pack.txt file.
@test "Output to stdout conf" {
    run_conf output_to_stdout.conf
    [ -f support-pack.txt ]
    cat  <<EOF | cmp - support-pack.txt
echo outside of log file
EOF
}

# If a conf file does not redirect command outputs to log files, stderr output
# is catched by the support-pack.txt file.
@test "Output to stderr conf" {
    run_conf output_to_stderr.conf
    [ -f support-pack.txt ]
    cat  <<EOF | cmp - support-pack.txt
echo outside of log file
EOF
}
