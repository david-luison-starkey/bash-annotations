# bash-annotations: Java-style annotations for Bash

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/david-luison-starkey/bash-annotations/blob/main/LICENSE)

---
## Table of contents
<!-- toc -->
- [Introduction](#introduction)
- [Usage](#usage)
- [Interfaces](#interfaces)
- [How does it work?](#how-does-it-work)
- [Special variables](#special-variables)
- [Gotchas](#gotchas) 
- [Pre-defined annotations](#pre-defined-annotations)
- [TODO](#todo)
---
## Introduction

`bash-annotations` provides functions for definiting `Java`-esque annotations that can then be used in your `Bash` scripts.

Declaring an annotation is as simple as annotating a function with `@interface` or `@inject`. This produces an annotation version of that function (following the convention @ + the function name).

The annotation form of the function can then be used to annotate other functions or variables (depending on the annotation's target type).

`bash-annotations` was developed with `Bash` version `5.0.17`. No effort has been made to ensure the project is compatible with older versions of `Bash` (although more recent features, such as associative arrays, are not used by the project).

---
## Usage

Start by sourcing `bash-annotations.bash` into a script. This provides the foundation on which `bash-annotations` operates.

The desired interface can then be sourced (or use the project-specific `import()`) from `interfaces/`. @inject or @interface can then be used to annotate your functions, in turn creating custom annotations.

`bash-annotations` annotations are designed to be placed above their target types.

Intervening lines between an annotation and its target ignore comments and other annotations. 

Empty lines and any other content interfere with an annotation's ability to locate its target, causing the annotation (either custom or interface) to return a non-zero exit code.

Correct usage:
```bash
@one
# @two 
@three
# This is a function. 
#
# It takes no arguments.
# 
# It does very little.
target_function() {
    echo "Hello world"
}
```
Incorrect usage:
```bash
@annotation

declare variable="100"

```

## Interfaces

`bash-annotations` provides two functions that act as interfaces, abstracting complexity and affording the easy creation of custom annotations.

Both interfaces take arguments that determine the behaviour of the annotation they are declaring. 

Arguments must be upper-case (to avoid namespace clashes with `function`, and for stylistic reasons, mimicking `Java` `ENUMs`).

All annotations evaluate lazily - annotation behaviour won't occur until a function or variable is called (not when declared/initialised).

## @interface

@interface creates annotations that act like `zsh` hook functions (https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions; https://github.com/rcaloras/bash-preexec).

Annotations created with @interface can target functions or variables, and be set to trigger before, after, or before and after the annotated type is called. 

@interface takes two arguments, target type and trigger condition.

Target type argument can be either: FUNCTION or VARIABLE

Trigger condition argument can be either: PRE, POST, or PREPOST

```bash
@interface FUNCTION POST
cleanup() {
    rm "temporary_file.txt"
}

@cleanup
create_temp_file() {
    touch "temporary_file.txt"
}

create_type_file

# Rest of script
```
```bash
declare -xgi VARIABLE_COUNT=0

@interface VARIABLE PREPOST
call_count() {
    VARIABLE_COUNT=$((VARIABLE_COUNT + 1))
}

@call_count
declare variable="Counting"

echo "${variable}: "
echo "${VARIABLE_COUNT}"
cd ../
echo "${variable}: "
echo "${VARIABLE_COUNT}"
```

Output:
```
Counting:
2
Counting:
4
```

## @inject

@inject, as the name suggests, creates an annotation that will inject its body into the annotated function.

Annotations created via @inject can only annotate functions.

Annotations created with @inject can inject their body before, after, or before and after the annotated function's body.

@inject takes one argument, the injection location.

Injection location argument can be either: PRE, POST, or PREPOST

The first time an injection annotation detects its target function being invoked, then the listener function (which performs the injection) is consumed, and the target function is re-declared with the newly injected code.

Variables declared within an injection annotation may be accessed by an annotated function (by referencing their namespace, even if local scope). 

```bash
@inject PRE
injection() {
    cd "${HOME}"
}

@injection
target_function() {
    pwd
}

target_function
declare -f target_function
```

Output: 
```
/home/${user}
target_function()
{
  cd "${HOME}";
  pwd 
}
```
---
## How does it work?

Interface functions create a copy of the functions they annotate (@ + the function name). The original function is unaffected and may be used as per normal `Bash` function use.

The annotation is built by interface functions with the ability to find the type they themselves annotate. 

When an annotation is used to annotate a type, a function with a unique namespace is added to the `${BASH_ANNOTATIONS_FUNCTION_ARRAY}`.

Functions in this array are looped through by `bash_annotations_trap_controller()` stored in the DEBUG `trap`.

`${BASH_COMMAND}` and `history` are used to listen for a function's trigger condition/s. 

Pre, post, or pre and post trigger conditions are determined by an interface function (@inject always uses a pre trigger condition).

These features are all determined at runtime via introspection. Unfortunately - but perhaps unsurprisingly - this leads to extended script execution.

---
## Special variables

`bash-annotations` special variables can be used when declaring custom annotations.

Special variables are:

| Interface | Variable | Value |
|-----------|----------|-------|
| @interface | annotated_function | Name of the annotated function | 
| @interface | annotated_variable | Name of the annotated variable | 
| @inject | inject_annotated_function | Name of annotated function (to be injected) |

Special variables are unique to each annotation and its target.

---
## Gotchas

* Annotations with a POST trigger condition will not be invoked if the annotated type is called at the very end of the script (as the POST listeners require some other command being invoked to detect the prior invocation of the target type).

* While @interface annotations that target functions and @inject annotations work together (any number and combination of @interface FUNCTION and @inject annotations can be used on the same target function), @inject annotations do not play nicely with @inferface annotations that target variables within either the annotation itself, or the function the @inject annotation targets. As such, using @inject annotations with @interface VARIABLE annotations should be avoided. @interface FUNCTION and @interface VARIABLE annotations do not interfere with each other however and can be used on/within the same function.

* Special variables must not exist on the same line as any other variable or command substitution etc. (as conditional logic applies to escaping the '$' symbol, where special variables are escaped differently). Backslashes can be used to split statements up over multiple lines to allow `bash-annotations` interfaces to parse lines correctly. This applies to both @inject and @interface.

```bash
@interface FUNCTION POST
function_annotation() {
    if $(declare -F \
    "${annotated_function}") && \
    [[ "${BASH_VERSION}" =~ "5.0" ]]; then 
        echo "Success"
    else
        echo "Failure"
    fi
}
```
* Similarly, positional parameter variables must not exist on the same line as any other variable or command substition. Special variables and positional parameter variables can exist on the same line as each other however. This applies to both @inject and @interface.
```bash
@inject PRE
injection() {
    local argument="${1}"; echo "${inject_annotated_function}";
    echo "${argument}"
}

@injection "First argument"
target_function() {
    :
}

target_function
```
Output:
```
target_function
First argument
```

* Special variable values can be accessed directly within functions created by @interface and @inject. Functions annotated by @interface are unable to reference special variables in the annoating function's scope. Functions annotated by @inject can access "${inject_annotated_function}" by first assigning this variable to another variable within the annotation function, then referencing this variable in the injected function. 

```bash
@inject PRE
make_special_variable_accessible() {
    local access_variable_value="${inject_annotated_function}"
}

@make_special_variable_accessible
target_function() {
    echo "${access_variable_value}"
}

target_function
```
Output:
```
target_function
```

* No logging or error messaging exist at present. Errors (such as an annotation failing to find a target type) will fail silently, however all functions in `bash-annotations` return either a 0 or 1 exit code based on success or failure.

* @interface annotations persist for the duration of the script they are called in. This means that any checks made by these annotations (listening for their trigger conditions) are performed continuously, leading to extended script execution time. For this reason, it is recommended that @inject is favoured over @interface for function annotations (while @interface must be used for annotating variables).
---
## Pre-defined annotations
`bash-annotations` comes with pre-defined, ready-to-use annotations.

Pre-defined annotations are located under `bash-annotations/src/annotations/`.

`functions/` and `variables/` sub-directories indicate an annotations intended target type.

User defined annotations can be stored within `bash-annotations/src/` to make use of the `import()` function.

---
## TODO

* Optimisation (too many annotations leads to prolonged runtime, particularly due to `-o functrace`)
* Move regex patterns into separate files for less duplicated code and easier testability
* Add/improve docstrings
* Implement additional pre-defined annotations
* Comprehensive `bats` and custom integration tests (`bats` does not appear to play nice with `bash-annotations` implementation)
* Project specific logging

---
