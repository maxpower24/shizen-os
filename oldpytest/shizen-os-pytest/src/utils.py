import re


# Define ANSI colours (FG & BG)
class Colours:
    BLACK='\033[30m'
    RED='\033[31m'
    GREEN='\033[32m'
    ORANGE='\033[33m'
    BLUE='\033[34m'
    MAGENTA='\033[35m'
    CYAN='\033[36m'
    WHITE='\033[37m'
    BLACKBG='\033[40m'
    REDBG='\033[41m'
    GREENBG='\033[42m'
    ORANGEBG='\033[43m'
    BLUEBG='\033[44m'
    MAGENTABG='\033[45m'
    CYANBG='\033[46m'
    WHITEBG='\033[47m'


# Return bool from yes/no question string input
def inputbool(question):
    while True:
        response = input(question)
        response = response.lower()
        yes = re.search("^(yes|y)$", response)
        no = re.search("^(no|n)$", response)
        if yes:
            return True
        elif no:
            return False
        print("Enter a valid answer (y|yes|n|no)")


# remove a key from a dictionary
def removekey(d, key):
    r = dict(d)
    del r[key]
    return r