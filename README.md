# bash-annotations: Java-style annotations for Bash

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/david-luison-starkey/bash-annotations/blob/main/LICENSE)

# Table of contents
<!-- toc -->
- [Introduction](#introduction)
- [Usage](#usage)
- [Interfaces](#interfaces)
- [How does it work?](#how-does-it-work)
- [Variables](#variables)
- [Gotchas](#gotchas) 
# Introduction

Create and use annotations (similar to Java annotations or Python decorators) for Bash scripts.

`bash-annotations` was developed with Bash version `5.0.17`. 

No effort has been made to ensure the project is compatible with older versions of Bash (although more recent features, such as associative arrays, are not used by the project).

# Usage

Begin by sourcing `bash-annotations.bash` into the desired script.

Once `bash-annotations.bash` is sourced the `import` function is available to concisely source files from within the `/bash-annotations/src/` directory structure.

```bash
# The directory bash-annotations.bash is located is the base directory used for import()
# Arguments passed to import are appended to the bash-annotations.bash path
# No leading forward slash is required 

# Import can take multiple arguments 
import interfaces/inject.bash interfaces/interface.bash
```

`bash-annotations` provides two functions that act as interfaces, abstracting complexity, and affording the easy creation of custom annotations.

* **@interface** creates annotations that trigger before and/or after their target annotated type is called.
* **@inject** creates annotations that are able to inject their body into their target annotated function.

Once a function is annotated with either @interface or @inject, an annotation version of that function can then be used (which will be declared at runtime). 

The format for annotations is:
* "@" + the function's namespace.

```bash
@interface FUNCTION PRE
func() {
    :
}

@func
```
Annotations can take positional parameters like regular Bash functions.

Interface functions and the annotations they declare are designed to be placed above their target types. Comments and other annotations may exist between an annotation and its target without affecting functionality. 

Empty lines and any other content interfere with an annotation's ability to locate its target, causing the annotation (either custom or interface) to do nothing.

*Correct usage*:
```bash
@one
# @two -- commented out, will not execute
@three
# This is a function. 
# It takes no arguments.
# It does very little.
target_function() {
    echo "Hello world"
}
```
*Incorrect usage*:
```bash
@annotation

declare variable="100"
```
Any number of @inject and @interface annotations can be used on the same function (see Gotchas for @inject/@interface VARIABLE incompatibility and annotation order of execution). 

Functions used to create annotations remain usable in their non-annotation form.
# Interfaces

Both @inject and @interface functions take arguments that determine the behaviour of the annotation they are declaring. 

Arguments must be upper-case (to avoid namespace clashes with the `function` keyword, and for stylistic reasons, mimicking Java `ENUMs`).

All annotations evaluate lazily - annotation behaviour won't occur until a function or variable is called (not when declared/initialised).

## @interface

Annotations created with @interface can target functions or variables, and be set to trigger before, after, or before and after the annotated type is called. Once triggered, the body of the annotation is executed.

@interface takes two arguments, target type and trigger condition.

Target type arguments: 
* FUNCTION
* VARIABLE

Trigger condition argument: 
* PRE
* POST
* PREPOST

```bash
@interface FUNCTION POST
cleanup() {
    rm "temporary_file.txt"
    ls
}

@cleanup
create_temp_file() {
    touch "temporary_file.txt"
    ls
}

create_type_file
```
```bash
declare -xgi VARIABLE_COUNT=0

@interface VARIABLE POST
call_count() {
    VARIABLE_COUNT=$((VARIABLE_COUNT + 1))
}

@call_count
declare variable="Counting"

echo "${variable}: "
echo "${VARIABLE_COUNT}"
echo "${variable}: "
echo "${VARIABLE_COUNT}"
```

*Output*:
```
Counting:
1
Counting:
2
```

## @inject

@inject, as the name suggests, creates an annotation that will inject its body into the annotated function.

Annotations created via @inject can only annotate functions.

Annotations created with @inject can inject their body before, after, or before and after the annotated function's body.

@inject takes one argument, the injection location.

Injection location argument: 
* PRE
* POST
* PREPOST

Injection annotations are consumed the first time its target function is called (so that injection only occurs once). Injection annotations trigger immediately before the annotated function is called.


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
# How does it work?

Annotations created by interface functions are declared with the following characteristics:
* Annotations retain their base function's body
* Annotations are able to detect any function or variable they annotate
* Once an annotated type is detected, an annotation creates a function with a unique namespace, its target type's namespace (to listen for when the target type is called), and the annotation's base function body. This function is then added to the `${BASH_ANNOTATIONS_FUNCTION_ARRAY}`. 

Functions in `${BASH_ANNOTATIONS_FUNCTION_ARRAY}` are iterated through by `bash_annotations_trap_controller()` stored in the DEBUG `trap`, checking for each function's trigger condition.

`${BASH_COMMAND}` and `history` are used to listen for pre and post trigger conditions. 

These features are all determined at runtime. 

# Variables

## Special variables
`bash-annotations` special variables can be accessed by annotation functions.

Special variables are:

| Interface | Variable | Value |
|-----------|----------|-------|
| @interface | annotated_function | Name of the annotated function | 
| @interface | annotated_variable | Name of the annotated variable | 
| @inject | inject_annotated_function | Name of annotated function (to be injected) |

Special variables are unique to each annotation (given a given annotations target).

```bash
@interface FUNCTION PRE
echo_annotated_function() {
    echo "This is what I've annotated: ${annotated_function}"
}

@echo_annotated_function
annotated() {
    :
}

annotated
```
*Output*:
```
This is what I've annotated: annotated
```

Functions annotated by @inject can also access `${inject_annotated_function}` by first assigning this variable to another variable within the annotation function, then referencing this variable in the injected function. 

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
*Output*:
```
target_function
```
## Accessing injected variables

A function annotated by an @inject annotation can access variables present in the annotation, as they will eventually be injected into that function. As such, potential for namespace clashes exist and should be accounted for.

An @inject annotation's positional parameters that are assigned to variables are also accessible by an annotated function.
```bash
@inject PRE
get() {
    local url="${1}"
    local response=$(curl -s -I "${url}" | grep "HTTP" | cut -d ' ' -f 2)
}

@get "www.google.com"
check_status_code() {
    echo "The response from "${url}" was:" 
    echo "${response}"
}

check_status_code
```
*Output*:
```
The response from www.google.come was:
200
```
# Gotchas

* When `bash-annotations.bash` is sourced the DEBUG `trap` is set and will override any previously DEBUG configuration.

* Annotations with a POST trigger condition will not be invoked if the annotated type is called at the very end of the script (as the POST listener require some other command being invoked to detect the prior invocation of the target type).

* @inject annotations do not play nicely with @inferface annotations that target variables within either the annotation itself, or the function the @inject annotation targets. As such, using @inject annotations with @interface VARIABLE annotations should be avoided. @interface FUNCTION and @interface VARIABLE annotations do not interfere with each other however and can be used on/within the same function.

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
*Output*:
```
target_function
First argument
```

* @interface annotations persist for the duration of the script they are called in. This means that any checks made by these annotations (listening for their trigger conditions) are performed continuously, leading to extended script execution time. For this reason, it is recommended that @inject is favoured over @interface for function annotations (while @interface must be used for annotating variables).

* Annotations execute in reverse order of appearance (meaning that for any given annotated target, the last annotation will execute first and the first annotation will execute last).

* No logging or error messaging exist at present. Errors (such as an annotation failing to find a target type) will fail silently, however all functions in `bash-annotations` return either a 0 or 1 exit code based on success or failure.