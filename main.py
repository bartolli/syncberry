import sys
import json
from dateutil.rrule import rrulestr
from dateutil.parser import parse

def expand_recurring_events(json_input):
    events = json.loads(json_input)
    expanded_events = []
    
    for event in events:
        event_data = event['eventItem']
        if "recurrenceRule" in event_data:
            rrule = rrulestr(event_data["recurrenceRule"], dtstart=parse(event_data["start_date"]))
            
            for dt in rrule:
                new_event_data = event_data.copy()  # Create a new dictionary
                duration = parse(event_data["end_date"]) - parse(event_data["start_date"])
                new_event_data["start_date"] = dt.strftime("%A, %B %d, %Y at %I:%M:%S %p")
                new_event_data["end_date"] = (dt + duration).strftime("%A, %B %d, %Y at %I:%M:%S %p")
                expanded_events.append({"eventItem": new_event_data})
                
        else:
            expanded_events.append(event)
            
    return json.dumps(expanded_events)

def main():
    json_data = sys.argv[1]  # Get JSON from command line argument
    processed_data = expand_recurring_events(json_data)  # Process the data using your function
    print(processed_data)  # This will be captured by AppleScript

if __name__ == '__main__':
    main()
