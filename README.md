### SyncBerry

SyncBerry is a two-way calendar synchronization script designed specifically for macOS users. Crafted in AppleScript, it serves as a bridge between two distinct Apple Calendars, ensuring both are always up-to-date. Leveraging Python and the python-dateutil library, SyncBerry provides accurate handling of recurring events through RRULE parsing.

The script designates one calendar as the 'source' and the other as the 'destination,' reversing these roles for bi-directional synchronization. Before duplicating events, it removes prior script-generated entries by scanning the 'location' field for a unique ParentID. This ensures source integrity while enabling precise synchronization. Roles are then reversed to complete the two-way sync.

### Features
- Two-way synchronization between Apple Calendars
- Support for both single and recurring events
- Python-assisted RRULE parsing for nuanced recurrence patterns
- Customizable time window for synchronization


### Installation
Make sure you are equipped with the following:

- macOS Catalina or later
- Python 3.x
- AppleScript :-)
- JSON Helper (AppleScript Library)

### Instructional Overview

1. **Clone the Repository**: 

   `git clone https://github.com/bartolli/syncberry.git`

2. **Set Up Virtual Environment**: 

   Create a Python virtual environment named `.venv` in your project directory. You can do that in VS Code or PyCharm
   Activate the virtual environment and install `python-dateutil` with the following commands:

   ```
   source .venv/bin/activate
   pip install python-dateutil
   ```

3. **Shell Script Permissions**: Make `shell.sh` executable. Run `chmod +x shell.sh` in the terminal. This script is your liaison to the Python virtual environment and is called each time RRULEs need parsing. 
4. **Script Permissions**: Once everything is set up, launch the script using Apple's Script Editor and execute it for the initial run. The script will request permission to access your Calendar and employ JSON Helper.
5. **Run SyncBerry**: With the preliminary configuration complete, execute 'osascript syncberry.applescript' to initiate the synchronization process. To automate this operation or convert it into a standalone application, consider using Automator.

### Customization and Setup Variables

The script provides a set of predefined variables that you can adjust to meet your specific needs. Customizing these variables allows the script to better fit your workflow and calendar setup.

#### AppleScript Constants

Find this section in the AppleScript:

```applescript
-- Constants: Our guiding stars
property calendarAName : "Work Sync"
property calendarBName : "Familie"
property timeScopeDays : 14
property pythonScriptPath : "/your_path/syncberry/vscode/shell.sh"
```
- `calendarAName`: The name of the first calendar you wish to sync.
- `calendarBName`: The name of the second calendar you wish to sync.
- `timeScopeDays`: The time scope, in days, for which the script should sync events. Configured by default to encompass a 14-day span: 7 days prior and 7 days forthcoming.
- `pythonScriptPath`: The full path to the shell script which activates your Python virtual environment.

**Note**: Before diving in, create two new calendars specifically for testing. Confirm the script operates as intended. This ensures a safeguard for your existing schedules.

#### Shell Script Configuration

Edit the `shell.sh` script to include your specific paths:

```sh
#!/bin/sh

source '/your_path/syncberry/vscode/.venv/bin/activate'
python /your_path/syncberry/vscode/main.py "$1"
```
Ensure that the paths to the virtual environment and Python script are correct.

### Python Virtual Environment

Before running the script, make sure you have activated your Python virtual environment and installed the `python-dateutil` package. This is essential as the shell script used by SyncBerry utilizes this package to parse RRULEs for recurring events.

To install the package, run:

```bash
pip install python-dateutil
```
Once installed, you're ready to utilize SyncBerry to its full potential.
