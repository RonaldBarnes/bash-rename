# CANCELLED:
## bash Pathname Expansion makes desired outcome impossible


# bash-rename
A file rename script for bash, supporting wildcards.  Syntax similar to DOS - rename files via wildcards.

Parses input for options & parameters, handles Pathname Expansion, and once parameters are cleaned, passes them to the "mv" command.

# NOTE: It is impossible to achieve the desired results with Pathname Expansion enabled, and it is not desirable to disable it: This project is cancelled.

## Pathname Expansion details:

Suppose an existing directory with 3 files:
* file1.html
* file2.htm
* file3.htm

Next, consider the following attempt to rename the htm files as html files (works for all commands run in bash, not just `ren`):

Basic usage: `ren *.htm *.html`

What the target script receives is **ALL THREE** file names, because the wildcards are expanded ***PRIOR*** to the script receiving them as parameters.

The following is impossible to determine a desired result from:

`ren file1.html file2.htm file3.htm` when one considers all permutations that could occur.


The same reason why `mv *.htm *.html`, for exampe, will not work in bash.


It is possible to achieve something close to the desired result by enclosing all parameters in quotes, thusly:

`ren "*.htm" "*.html"`

But that loses the "muscle memory" of the old DOS `ren` command, and forgetting the quotes could have quite poor consequences.

Also recall that `*` is a valid file name in Linux file systems.


Hence, the project has been cancelled; at least a lot was learned about bash, Pathname Expansion, and more.


Run with -h to get usage.  Run with -h -vv to get full usage.
