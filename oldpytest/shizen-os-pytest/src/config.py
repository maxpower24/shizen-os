import json
import subprocess
from src.utils import inputbool


# Define class to get and set disks to install arch on before saving.
class Disks(object):
    # Define default values
    def __init__(self):
        self.root = ''
        self.home = ''

    # Runs a subprocess to get current disk information.
    # Stores in an attribute that should be deleted before saving.
    def load(self):
        self.freedisks = []
        lsblkout = subprocess.run(['lsblk'], capture_output=True)
        lsblkout = lsblkout.stdout.splitlines()
        for line in lsblkout:
            line = line.decode("utf-8").split()
            if line[5] == 'disk':
                self.freedisks.append([line[0], line[3]])

    # Set the root and home disks via user input or select method.
    def set(self, homedisk):
        self.load()
        self.root = ''
        self.home = ''
        if (len(self.freedisks) == 1):
            response = inputbool(
                    f"Install on {self.freedisks[0][0]}? [y/N]: ")
            if response:
                self.root = self.freedisks[0][0]
        else:
            self.root = self.select('root')
            if homedisk:
                self.home = self.select('home')
        del self.freedisks

    # Returns a disk name to be assigned to a given directory via user input.
    # Removes the disk from the remaining disks before assigning.
    def select(self, dir):
        i = 1
        for freedisk in self.freedisks:
            print(f"{i}) {freedisk[0]} {freedisk[1]}")
            i = i + 1
        response = int(input(f"Which disk to install {dir} on? "))
        disk = self.freedisks[response-1]
        self.freedisks.remove(disk)
        return disk[0]


# Define class for creating, storing and loading settings
class InstallConfig(object):
    # Set config file location constant
    SAVEFILE = "./config.json"

    # Define default values
    def __init__(self):
        self.username = "maxpower"
        self.hostname = "mp-test"
        self.optpackages = False
        self.reinstall = False
        self.homedisk = False
        self.wipehome = False
        self.disks = Disks()
        self.partroot = 'part1'
        self.parthome = 'part2'

    # Set installation config via user input
    def configure(self):
        default = inputbool("Use default settings? [y/N]: ")
        if (default == False):
            self.username = input("Enter username: ")
            self.hostname = input("Enter hostname: ")
            self.optpackages = inputbool(
                "Install optional packages? [y/N]: ")
            self.reinstall = inputbool(
                "Reinstall to existing partitions? [y/N]: ")
            if (len(self.disks.freedisks) > 1):
                self.homedisk = inputbool(
                    "Install /home on a second disk? [y/N]: ")
        self.disks.set(self.homedisk)
        if ((self.reinstall == True) & (self.homedisk == True)):
            self.wipehome = inputbool("Wipe /home as well? [y/N]: ")

    # Save cofnig to json file
    def save(self):
        with open(self.SAVEFILE, "w") as configfile:
            json.dump(self, configfile, default=lambda o: o.__dict__,
                sort_keys=True, indent=4)

    # Return config for print()
    def tojson(self):
        js = json.dumps(self, default=lambda o: o.__dict__,
                sort_keys=True, indent=4)
        return js