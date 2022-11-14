# bash-annotations: Java-style annotations for Bash

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/david-luison-starkey/bash-annotations/blob/main/LICENSE)

## Introduction

`bash-annotations` provides interfaces for definiting `Java`-esque annotations that can then be used in your `Bash` scripts.

Declaring an annotation is as simple as writing a function and annotating it with an interface annotation (supplying any arguments to the interface annotation are required to define the inteded behaviour for your new annotation).  

The annotation can then be used to annotate any number of functions or variables (depending on the annotation's target type).

Logic is then evaluated at runtime.

## Table of contents
<!-- toc -->
- [Usage](#usage)
- [Interfaces](#interfaces)
- [Special variables](#special-variables)
- [Gotchas](#gotchas) 
- [Pre-defined annotations](#pre-defined-annotations)
## Usage

## Interfaces

## Special variables

`bash-annotations` special variables can be accessed when declaring custom annotations to allow for more versatile behaviour.

Special variables are:

| Variable | Value |
|----------|-------|
| annotated_function | Name of annotated function for @function | 
| annotated_variable | Name of annotated variable @function | 

### Gotchas
Special variables must not exist on the same line as any other variable or command substitution etc. (as conditional logic 
applies to escaping the '$' symbol, where special variables are escaped differently).

Backslashes can be used to split statements up over multiple lines to allow `bash-annotations` interfaces to parse lines correctly.

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

Indirection can be used to access values assigned to $annotated_variable too (not by using $annotated_variable directly).

```bash
@interface VARIABLE PRE
variable_annotation_value() {
    local access_variable_value_via_indirection="${annotated_variable}"
    if [[ "${!access_variable_value_via_indirection}" == "desired value" ]]; then
        echo "Success"
    else
        echo "Failure"
    fi
}
```

## Pre-defined annotations
`bash-annotations` comes with pre-defined, ready-to-use annotations.

Pre-defined annotations are located under `bash-annotations/src/annotations/`.

`functions/` and `variables/` sub-directories indicate an annotations intended target type.

