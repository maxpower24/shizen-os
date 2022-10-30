from src.utils import Colours, inputbool
from src.config import InstallConfig, subprocess


# Define constants
GIT_REPO="maxpower24/shizen-os"
GIT_BRANCH="main"


if __name__ == "__main__":
    ## Download other git files and make them executable if needed
    # wget https://github.com/maxpower24/shizen-os/archive/main.zip
    # unzip main.zip
    subprocess.run(['chmod', '+x', './src/bashscripts.sh'])

    # Displays the banner
    subprocess.run('clear')
    print(f"""
    {Colours.GREEN}
        ┌─────────────────────────────────────┐
    	│░░░█▀▀░█░█░█░▀▀█░█▀▀░█▖█░░░█▀█░█▀▀░░░│
    	│░░░▀▀█░█▀█░█░▄▀ ░█▀▀░█▝█░░░█░█░▀▀█░░░│
    	│░░░▀▀▀░▀░▀░▀░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░░░│
    	└─────────────────────────────────────┘
    	{Colours.ORANGE}[*] {Colours.CYAN}By: Max Power
    	{Colours.ORANGE}[*] {Colours.CYAN}Github: @maxpower24
    	{Colours.ORANGE}[*] {Colours.CYAN}Repo: {GIT_REPO}
    	{Colours.ORANGE}[*] {Colours.CYAN}Branch: {GIT_BRANCH}

    	Welcome...
    """)

    # User input settings
    instsett = InstallConfig()
    while True:
        instsett.configure()
        print(instsett.tojson())
        confirmed = inputbool(
            "Save these settings and continue with installation? [y/N]: ")
        if confirmed:
            instsett.save()
            break

    # Run bash scripts based on config
    if instsett.reinstall:
        params = f'{instsett.wipehome} {instsett.partroot} {instsett.parthome}'
        proc = f'. ./src/bashscripts.sh; wipe_disks {params}'
        subprocess.Popen(['bash', '-c', f'{proc}'])
    else:
        subprocess.Popen(['bash', '-c', '. ./src/bashscripts.sh; prep_disks'])
