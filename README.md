# QEMU builtbot

Builds QEMU for Windows. 

[![Build Status](https://dev.azure.com/nekomimiswitch/General/_apis/build/status/qemu-buildbot?branchName=master)](https://dev.azure.com/nekomimiswitch/General/_build/latest?definitionId=88&branchName=master)

## Notes

* Run on a Debian stretch installation (container is OK)
* The build takes ~1hrs on a single Xeon E5 core (assuming network is good)
* `MAKE_FLAGS` is by default `-j` which enables all cores, and this might result in an OOM; set to `-j4` or something smaller
* `build-stage1.sh` must be executed under root; `build-stage2.sh` can be executed under any user
* `SOURCE_BASE_DIR` and `BUILD_ARTIFACTS_DIR` must be writable by the stage2 user; all existing files will be removed in the 2 directories
