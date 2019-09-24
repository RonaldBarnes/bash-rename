#!/bin/bash 

## A rename program similar to DOS - rename files via wildcards.
##
## Parses input for options & parameters, handles Pathname Expansion, and 
## once parameters are cleaned, passes them to the "mv" command.
##
## (c) Ronald Barnes 2019
##
## Basic usage: rename.sh "*.htm" "*.html"
##
## The quotes around the final parameter are required IF there
## are existing files that match that pattern.
##
## The quotes around the first parameter are not usually required.
##
## If shopt is used to set nullglob on (shopt -s nullglob), then
## the final parameter MUST be quoted, else the non-matching wildcard
## pattern will be nullified and not passed to this script.
##
## nullglob is unset (off) by default in Ubuntu and many (most?) other
## distributions.
##
## Alias this command to "ren" or "rn" as preferred.
##
##
## Run with -h to get usage.  Run with -h -vv to get full usage.




## Script version number:
version=0.6.0

## Search pattern: may include wildcard if quotes on 1st parameter but if
## no quotes, Pathname Expansion will "eat" the wildcard(s):
searchPattern=
## Replace pattern: may include wildcard if: quotes on 2nd parameter OR no
## quotes, but also no files in pwd matching wildcard pattern (since 
## Pathname Expansion will "eat" the wildcard(s)):
replacePattern=

## Array to hold non-option arguments, i.e. file(s) to rename:
declare -a filesToRename

## Setting for no-operation / dry-run:
## Zero == true, 1 == false
noop=1

## Prompt for each mv/move/rename (passed to mv command)
interactiveMode=

## Verbose mode (passed to mv command):
verboseMode=

## Verbosity level: each -v increments by 1.  Used to give more verbosity
## when outputting usage:
typeset -i verbosityLevel=0

## arrayIndex just cycles through parameters ($@) and acts as index to array
## of all parameters passed to this script:
typeset -i arrayIndex=0

## Count of wildcards (* only) in search term for parsing & matching &
## building replace string:
typeset -i wildcardsSearchCount

## Count of wildcards (* only) in replace term for parsing & matching &
## building replace string:
typeset -i wildcardsReplaceCount

## Save IFS (Internal Field Separator) since it may get changed:
## IFS: The  default  value  is  ``<space><tab><new‐line>''.
origIFS=$IFS




## ##################################################################
function usage()
	{
cat <<EOF

Usage:
------
$(basename $0) [options] "searchPattern" "replacePattern"

Description:

A rename utility that operates on wildcards.

Options supported:
  -h  Help (this usage message)
  -i  Interactive mode - prompts for each rename / move (passed to "mv")
  -n  No-Op aka --dry-run: does everything except call the mv command
  -v  Verbose - passChanges not staged for commit:ed as option to "mv" command
      Also, this script accepts multiple invocations of -v which increases 
      output for debugging and full "usage" / --help text
  --version
      Gives the version of the script.
      Not to be mixed with parameters; use alone to see version info and exit.

Example - rename all file extensions of ".htm" to ".html":

  $(basename $0) "*.htm" "*.html"

Quoting parameters is not always required, but in the above example, if there
are files matching *.html in the pwd (present working directory), then the
quotes around the final parameter ARE REQUIRED.

For best results, quote the searchPattern and the replacePattern.

Re-run $(basename $0) with "-vvh" option(s) for more detailed help.
EOF

	## Check for user requesting more usage details:
	if [[ $verbosityLevel -gt 1 ]]; then
cat <<EOF

For best results, quote the searchPattern and the replacePattern.

Otherwise the wildcard pattern "*.html" will be expanded by Pathname expansion
to a list of matching files and this script will receive them as further 
parameters and think they need renaming too.


If shopt is used to set nullglob on (shopt -s nullglob), then
the final parameter MUST be quoted, else the non-matching wildcard
pattern will be nullified and not passed to this script.

nullglob is unset (off) by default in Ubuntu and many (most?) other
distributions. Running shopt nullglob to see its setting on this system:
$(shopt nullglob)


Alias this command to "ren" or "rn" as preferred.

When invoking the "mv" command, the --no-clobber option is always passed.
This prevents over-writing of destination files.

EOF
	fi
	}


## ##################################################################
## Log messages depending on verbosityLevel (invoked via -v[v...])
function logMessage()
	{
	## logMessage msgVerbosityLevel messageString
	if [[ $1 -le ${verbosityLevel} ]]; then
		messageWords=${@}
		## echo all words passed to function EXCEPT 1st (msgVerbosityLevel)
		## and the space following it:
		messageWords=${messageWords#* }
		## messageWords=${@#* }
		## echo all words passed to function EXCEPT 1st (msgVerbosityLevel)
		## and the space following it:
		#echo ${@:2}
		echo ${messageWords}
	fi
	}


## ##################################################################
function onExit()
	{
	## Trap exit and ensure Pathname Expansion is re-enabled:
	logMessage 2 "Setting Pathname Expansion ON."
	set +f
	## Ensure IFS (Internal Field Separator) is back to original value:
	IFS=$origIFS
	}


## ##################################################################
function countWildcards()
	{
	## typeset implies "local":
	typeset -i kounter=0
	local var=$1

	if [[ $var == "" ]]; then
		logMessage 0 "ERROR: countWildcards() called without parameter."
		exit $E_BADARGS
	fi

	while [[ $var == *"*"* ]]; do
		((kounter++))
		## Remove one "*" via Pattern substitution:
		var=${var/\*//}
	done

	## Use "echo" to capture a return value via "x=$(function y x)"
	echo $kounter
	## Use "return" to capture a return value via "x=$?"
	return $kounter
	}




## ##################################################################
## process any options passed to this script:
while getopts "hiqnv-" userParam; do
#	echo "OPTINDex=${OPTIND} and item=$userParam"
	case ${userParam} in
		h)
			usage
			exit
			;;
		i)
			echo "Interactive (not yet supported)"
			interactiveMode="--interactive"
			;;
		n)
			noop=0
			echo "no-op aka dry-run selected."
			;;
		q)
			echo "Quiet is not supported by mv."
			;;
		v)
			## increase level of verbosity if giving this script's usage:
			(( verbosityLevel++ ))
			echo "verbosityLevel=${verbosityLevel}"
			verboseMode="--verbose"
			;;
		## Next, check for long-form options:
		## Doesn't work - not supported. If there's only ONE though, can work:
		-)
			if [[ ${!OPTIND} == "--version" ]]; then
				echo "$(basename $0) Version ${version}"
			else
				logMessage 0 "Unknown option ${!OPTIND}."
			fi
			exit
			;;
	esac
done


## Remove options processed from $@, leaving only the file pattern(s):
shift $((OPTIND-1))



## Ensure we still have enough to perform a valid operation:
if [[ "$#" -lt 2 ]]; then
	logMessage 0 "Invalid parameter count (only $# given, need at least 2)."
	logMessage 0 "Run $(basename $0) -h for usage (-vv for detailed usage)."
	exit $E_BADARGS
fi




## Trapping exit condition to re-enable Pathname Expansion:
trap onExit EXIT
logMessage 2 "Disabling Pathname Expansion:"
set -f


## Capture remaining (non-option) parameters into array filesToRename:
## This handles a non-quoted source string such as *.text
## which Pathname Expansion will expand to file1.text, ..., fileN.text:
for file in "${@}" ; do
	filesToRename[ $((arrayIndex++)) ]=${file}
	logMessage 2 "File array loaded with ${file}"
done

## Now, peel off the final element of array (number elements-1),
## since it MUST be the "replace string".
## So, if this script is invoked with parameters *.htm "*.html", this
## will capture the "*.html":
replacePattern=${filesToRename[-1]}
if [[ ${verbosityLevel} -gt 0 ]]; then
	logMessage 1 "Replace pattern = ${replacePattern}"
fi


## Remove the replacePattern from end of array:
## (NB: the syntax on unset for arrays seems odd)
unset 'filesToRename[-1]'
logMessage 2 "Files array has ${#filesToRename[*]} items: ${filesToRename[*]}"



## What we're USING as a matching string in our search portion of 
## search/replace,
## i.e. *.htm  -> htm (strip out the wildcard bits):
##
## Pathname expansion means we receive NOT 
## *.test but file1.test, file2.test,
## unless quotes were used on first parameter.

## Disable Pathname Expansion:
set -f

searchPattern="${filesToRename[*]}"

## countWildcards "$searchPattern"
## wildcardsSearchCount=$?
wildcardsSearchCount=$(countWildcards "$searchPattern")
## countWildcards "$replacePattern"
## wildcardsReplaceCount=$?
wildcardsReplaceCount=$(countWildcards "$replacePattern")

logMessage 3 $(echo "Wildcard count: search: $wildcardsSearchCount 
 replace: $wildcardsReplaceCount")



## (re-)Enable Pathname Expansion:
logMessage 2 "(re-)Enabling Pathname Expansion:"
set +f








## ##################################################################
## Now to iterate through all matching files:
## ##################################################################
logMessage 2 "Iterating through file list: \"${filesToRename[@]}\""

## Adding quotes to ${filesToRename[@]} suppresses Pathname Expansion:
## that makes "ls" fail:
for myFile in $(ls ${filesToRename[@]});
	do
		## If same number of wildcards in search & replace, and > 0, then
		## we can parse on "*" to get components to search/replace:
		if [[ $wildcardsSearchCount -eq $wildcardsReplaceCount && 
		$wildcardsSearchCount -gt 0 ]]; then
			myNewFile=$myFile
			typeset -i arrayIndexKounter=0
			var=$searchPattern
			declare -a searchTermArray
			declare -a replaceTermArray
			## Parse "read" input on "*", not default "space/tab/new-line":
			IFS="*"
			## Parse searchPattern into components, splitting at "*"
			## file*.htm -> array with 2 elements: "file", ".htm"
			read -ra searchTermArray <<< "$searchPattern"
			## Parse replacePattern into components, splitting at "*"
			## file*.html -> array with 2 elements: "file", ".html"
			read -ra replaceTermArray <<< "$replacePattern"
			IFS=$origIFS
			## Iterate through array, replacing substrings via bash's
			## Pattern substitution:
			for var in "${searchTermArray[@]}"; do
				logMessage 2 $(echo "search=\"$var\" 
					and replace=\"${replaceTermArray[$arrayIndexKounter]}\" 
					and kounter=$arrayIndexKounter and myNewFile=${myNewFile}")
				if [[ $var == "" ]]; then
					## Replacement won't happen on empty string, prepend it:
					myNewFile=${replaceTermArray[$arrayIndexKounter]}${myNewFile}
				else
					myNewFile=${myNewFile/$var/"${replaceTermArray[$arrayIndexKounter]}"}
				fi
				## Increment counter:
				((arrayIndexKounter++))
			done
		elif [[ $wildcardsSearchCount -eq $wildcardsReplaceCount
		&& $wildcardsSearchCount -eq 0 ]]; then
			## Appears to be a simple "rename.sh file1.htm file1.html"
			myNewFile=${replacePattern}
		elif [[ "${searchPattern}" == *"*.*"* ]]; then
			logMessage 2 "searchPattern CONTAINS *.*: \"${searchPattern}\""

			typeset -i arrayIndexKounter=0
			declare -a searchTermArray
			declare -a replaceTermArray
			## Parse "read" input on ".", not default "space/tab/new-line":
			IFS="."
			## Parse searchPattern into components, splitting at "."
			## file*.htm -> array with 2 elements: "file*", "*"
			read -ra searchTermArray <<< "$searchPattern"
			## Parse replacePattern into components, splitting at "."
			## file*.html -> array with 2 elements: "file*", "html"
			read -ra replaceTermArray <<< "$replacePattern"
			IFS=$origIFS

			if [[ ${#searchTermArray[@]} -ne 2 
			&& ${#replaceTermArray[@]} -ne 2 ]]; then
				logMessage 0 $(echo "ERROR: barfed on parsing on \".\" 
					-- not 1 \".\" in each param:")
## echo "searchTermArray: ${searchTermArray[@]}"
## echo "replaceTermArray: ${replaceTermArray[@]}"
				exit $E_BADARGS
			fi
			myNewFile=${myFile/${searchTermArray[0]%%\**}/${replaceTermArray[0]%%\**}}

			myNewFile=${myNewFile%%.*}.${replaceTermArray[1]}
		elif [[ "${searchPattern:0:3}" == "*.*" ]]; then
			logMessage 2 "searchPattern STARTS with *.*: ${searchPattern}"

			## bash Pattern substitution: search / replace
			myNewFile=${myFile/${search_cleaned}/${replacePattern}}
		elif [[ "${searchPattern:0:1}" == "*" ]]; then
			logMessage 2 "searchPattern STARTS with *: ${searchPattern}"

			## bash Substring Expansion from position 2 to end (zero-indexed)
			replacePattern=${replacePattern:1}
			## bash Pattern substitution: search / replace
			myNewFile=${myFile/${search_cleaned}/${replacePattern}}
		elif [[ "${searchPattern}" == *"*."* ]]; then
			logMessage 2 "searchPattern CONTAINS *.: ${searchPattern}"

			## bash Remove matching suffix pattern: 1st "*" to end:
			replace_cleaned=${replacePattern#\*.*}
			logMessage 2 "Replace pattern cleaned 2 = ${replace_cleaned}"

			## bash Pattern substitution: search / replace
			myNewFile=${myFile/${search_cleaned}/${replace_cleaned}}
		elif [[ ${searchPattern: -2:2} == ".*" ]]; then
			logMessage 2 "searchPattern ENDS with .*: $searchPattern"

			## bash Substring removal: grab all but last character:
			replacePattern=${replacePattern:0: -1 }
			## bash Pattern substitution: swap search (minus wildcards) with
			## replacePattern to build new, destination file name:
			myNewFile=${myFile/${search_cleaned}/${replacePattern}}
		elif [[ ${searchPattern: -1:1} == "*" ]]; then
			## User gave wildcard at end, withOUT the "dot"
			logMessage 2 "searchPattern ENDS with *: $searchPattern"

			## bash Pattern substitution: swap search (minus wildcards) with
			myNewFile=${myFile/${search_cleaned}/${replacePattern%\**}}

## ##################################################################
		## searchPattern SHOULD not contain a wildcard, but replacePattern
		## still may: i.e. file1.test -> *.text
		elif [[ ${replacePattern:0:2} == "*." ]]; then
			logMessage 2 "replacePattern STARTS with *: $replacePattern"

			## bash Remove matching suffix pattern:
			## From END of myFile: from the "." to the end, then
			## bash Substring  Expansion to remove 2 characters from
			## BEGINNING of replacePattern:
			myNewFile=${myFile%.*}.${replacePattern:2}
		elif [[ ${replacePattern:0:1} == "*" ]]; then
			logMessage 2 "replacePattern STARTS with *: $replacePattern"

			## bash Remove matching suffix pattern:
			## From END of myFile: from the "." to the end, then
			## bash Substring  Expansion to remove 1 character from
			## BEGINNING of replacePattern:
			myNewFile=${myFile%.*}${replacePattern#*\*}
		elif [[ ${replacePattern: -3:3} == "*.*" ]]; then
			logMessage 2 "replacePattern ENDS with *.*: $replacePattern"

			## bash Remove matching suffix pattern: 1st "*" to end:
			replace_cleaned=${replacePattern%%\**}
			logMessage 2 "replace_cleaned=\"${replace_cleaned}\""

			## Remove matching prefix pattern from name parts to 1st ".":
			myNewFile=${replace_cleaned}${myFile#*.}
		elif [[ ${replacePattern: -2:2} == ".*" ]]; then
			echo "replacePattern ENDS with .* $replacePattern"
			## bash Substring  Expansion to remove 1 character from
			## END of replacePattern:
			## bash Remove matching suffix pattern from 1st "." to end, then
			## Remove matching prefix in myFile: to the 1st ".":
			myNewFile=${replacePattern%.*}.${myFile#*.}
		elif [[ ( ${replacePattern} == *"*"* ) 
			|| ( ${replacePattern} == *"?"* ) ]]; then
			echo
			echo "ERROR: can't figure out what to do with the wildcard in "
			echo "\"${replacePattern}\" due to its location within string."
			echo "What is it replacing within file \"${myFile}\"?"
			echo
			echo "Quoting first parameter may help by preserving wildcards."
			echo
			exit 
		else
			## No wildcard in replacePattern.
			## Perhaps user gave one source file and one target filename,
			## so just take the "replacePattern" and call it the target:
			## Alternately, file*.htm got Pathname Expansion'd to a 
			## list of files...
			## NOTE: this ought to have been taken care of in 2nd "elif" above:
			myNewFile=${replacePattern}
		fi


		if [[ -f ${myNewFile} ]]; then
			echo
			echo "ERROR"
 			echo "Cannot rename ${myFile}: target file ${myNewFile} exists."
			echo
			echo "Try quoting parameters or checking match pattern."
			echo
			exit $E_BADARGS
		fi

		## perform the move / rename (and check for a --dry-run / noop):
		if [[ ${noop} -eq 0 || ${noop} == "TRUE" ]]; then
			echo "NOOP mv --no-clobber ${verboseMode}" \
				"${interactiveMode} ${myFile} ${myNewFile}"
		else
			mv --no-clobber ${verboseMode} ${interactiveMode} ${myFile} ${myNewFile}
		fi
	done
