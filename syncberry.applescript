-- Constants: Our guiding stars
property calendarAName : "Work Sync"
property calendarBName : "Familie"
property timeScopeDays : 14
property pythonScriptPath : "/your_path/syncberry/vscode/shell.sh"

-- Variables: The tides we navigate
set currentDate to current date
set startTime to currentDate - (timeScopeDays * days)
set endTime to currentDate + (timeScopeDays * days)

-- Functions: The oars that propel us
on fetchEssentialEventProperties(calendarName, startTime, endTime)
	set singleEvents to {}
	set recurringEvents to {}
	tell application "Calendar"
		set fetchedEvents to every event of calendar calendarName whose start date ³ startTime and start date ² endTime
		repeat with anEvent in fetchedEvents
			set eventID to uid of anEvent as string
			set startDate to (start date of anEvent)
			set endDate to (end date of anEvent)
			set startDateString to startDate as string 
			set endDateString to endDate as string 
			set recurrenceRule to (recurrence of anEvent)
			set eventTitle to (summary of anEvent as string)
			
			if (location of anEvent) is missing value then
				set eventLocation to "null"
			else
				set eventLocation to (location of anEvent)
			end if
			if (description of anEvent) is missing value then
				set eventDescription to "null"
			else
				set eventDescription to (description of anEvent as string)
			end if
			
			set anEventDict to {eventItem:{eventUID:eventID, start_date:startDateString, end_date:endDateString, recurrenceRule:recurrenceRule, eventTitle:eventTitle, eventLocation:eventLocation, eventDescription:eventDescription}}
			if recurrenceRule is missing value then
				set end of singleEvents to anEventDict
			else
				set end of recurringEvents to anEventDict
			end if
		end repeat
	end tell
	return {singleEvents:singleEvents, recurringEvents:recurringEvents}
end fetchEssentialEventProperties

on fetchAllEssentialEventProperties(calendarAName, calendarBName, startTime, endTime)
	set calendarAResult to my fetchEssentialEventProperties(calendarAName, startTime, endTime)
	set calendarBResult to my fetchEssentialEventProperties(calendarBName, startTime, endTime)
	return {calendarA:calendarAResult, calendarB:calendarBResult}
end fetchAllEssentialEventProperties

on makeJSON(dataToConvert)
	try
		tell application "JSON Helper"
			set properJSON to make JSON from dataToConvert
			return properJSON
		end tell
	on error errorMessage number errorNumber
		return "Error: " & errorMessage & ", Error Number: " & errorNumber
	end try
end makeJSON

on readJSON(dataToConvert)
	try
		tell application "JSON Helper"
			set parsedJSON to read JSON from dataToConvert
			return parsedJSON
		end tell
	on error errorMessage number errorNumber
		return "Error: " & errorMessage & ", Error Number: " & errorNumber
	end try
end readJSON

on parseDateAndSetTime(dateString)
	-- Parse the initial date string to create a base date object
    -- @format: Example "Thursday, October 19, 2023 at 6:30:00 PM"
    -- @python: dateutil >>> (dt + duration).strftime("%A, %B %d, %Y at %I:%M:%S %p")
	set theStartDate to date dateString
	
	-- Extract the time information from the string
	set timeString to text from ((offset of "at" in dateString) + 3) to end of dateString
	set {hourValue, minuteValue, secondValue, ampmValue} to my splitTimeString(timeString)
	
	-- Handle AM/PM
	if ampmValue is "PM" and hourValue is not 12 then
		set hourValue to hourValue + 12
	else if ampmValue is "AM" and hourValue is 12 then
		set hourValue to 0
	end if
	
	-- Set the time components
	set hours of theStartDate to hourValue
	set minutes of theStartDate to minuteValue
	set seconds of theStartDate to secondValue
	
	return theStartDate
end parseDateAndSetTime

-- Helper function to split a string based on a delimiter
on splitString(theString, theDelimiter)
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to ""
	return theArray
end splitString

-- Function to split the time string into its components
on splitTimeString(timeString)
	set timeParts to splitString(timeString, ":")
	set hourValue to item 1 of timeParts as integer
	set minuteValue to item 2 of timeParts as integer
	set remainingPart to item 3 of timeParts
	set secondValue to text 1 thru 2 of remainingPart as integer
	set ampmValue to text 4 thru 5 of remainingPart
	return {hourValue, minuteValue, secondValue, ampmValue}
end splitTimeString

-- Function to clone events
on cloneEventsToCalendar(eventsList, calendarName)
	tell application "Calendar"
		-- Loop through each event
		repeat with anEvent in eventsList
			
			set theTitle to anEvent's eventItem's eventTitle
			set theStartDateString to anEvent's eventItem's start_date
			set theStartDate to my parseDateAndSetTime(theStartDateString)

			set theEndDateString to anEvent's eventItem's end_date
			set theEndDate to my parseDateAndSetTime(theEndDateString)	

			set theLocation to "ParentID:" & (anEvent's eventItem's eventUID)
			set eventDescription to (anEvent's eventItem's eventDescription)
			
			-- Create the event in Destination Calendar
			tell calendar calendarName
				make new event with properties {summary:theTitle, start date:theStartDate, end date:theEndDate, location:theLocation, description:eventDescription}
			end tell
		end repeat
	end tell
end cloneEventsToCalendar

-- Cleanup Utility: We target only cloned events
on cleanupCalendar(calName, startTime, endTime)
	try
		tell application "Calendar"
			set calEvents to every event of calendar calName whose start date ³ startTime and start date ² endTime
			repeat with anEvent in calEvents
				if location of anEvent contains "ParentID" then
					delete anEvent
				end if
			end repeat
		end tell
	on error errMsg
		log "Cleanup Failed: " & errMsg
	end try
end cleanupCalendar

-- The Main Act: Strategy personified
try
	
	my cleanupCalendar(calendarAName, startTime, endTime)
	my cleanupCalendar(calendarBName, startTime, endTime)
	
	set allEssentialProperties to my fetchAllEssentialEventProperties(calendarAName, calendarBName, startTime, endTime)
	set calendarAProperties to calendarA of allEssentialProperties
	set calendarBProperties to calendarB of allEssentialProperties
	set recurringEventsFromCalendarA to recurringEvents of calendarA of allEssentialProperties
	set recurringEventsFromCalendarB to recurringEvents of calendarB of allEssentialProperties
	set singleEventsFromCalendarA to singleEvents of calendarA of allEssentialProperties
	set singleEventsFromCalendarB to singleEvents of calendarB of allEssentialProperties
	
	-- Convert the recurringEvents from CalendarA to JSON
	set jsonRecurringEventsCalendarA to my makeJSON(recurringEventsFromCalendarA)
	-- Expand RRULES from recurring events from CalendarA to individual instances
	set jsonExpandedEventsCalendarA to do shell script pythonScriptPath & " " & quoted form of jsonRecurringEventsCalendarA
	-- Convert the JSON format back to CalendarA object
	set expandedEventsCalendarA to readJSON(jsonExpandedEventsCalendarA)
	
	-- Convert the recurringEvents from CalendarB to JSON
	set jsonRecurringEventsCalendarB to my makeJSON(recurringEventsFromCalendarB)
	-- Expand RRULES from recurring events from CalendarB to individual instances
	set jsonExpandedEventsCalendarB to do shell script pythonScriptPath & " " & quoted form of jsonRecurringEventsCalendarB
	-- Convert the JSON format back to CalendarB object
	set expandedEventsCalendarB to readJSON(jsonExpandedEventsCalendarB)

    -- Clone expanded events from CalendarA to CalendarB
    my cloneEventsToCalendar(expandedEventsCalendarA, calendarBName)
    -- Clone expanded events from CalendarB to CalendarA
    my cloneEventsToCalendar(expandedEventsCalendarB, calendarAName)
    -- Clone single events from CalendarA to CalendarB
    my cloneEventsToCalendar(singleEventsFromCalendarA, calendarBName)
    -- Clone single events from CalendarB to CalendarA
    my cloneEventsToCalendar(singleEventsFromCalendarB, calendarAName)

on error errMsg
	log "An obstacle: " & errMsg
end try