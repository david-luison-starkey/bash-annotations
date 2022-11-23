# TODO

* Optimisation (too many annotations leads to prolonged runtime, particularly due to `-o functrace`)
* Move regex patterns into separate files for less duplicated code and easier testability
* Add/improve docstrings
* Implement additional pre-defined annotations
* Comprehensive `bats` and custom integration tests (`bats` does not appear to play nice with `bash-annotations` implementation)
* Project specific logging
* Annotations execute in order of appearance for a given annotated type
* Determine minimum Bash version compatibility of project
