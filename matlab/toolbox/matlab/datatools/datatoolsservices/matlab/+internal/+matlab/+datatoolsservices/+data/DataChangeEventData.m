classdef DataChangeEventData < event.EventData
    % Event Data Class used when sending data events from either the
    % DataStore
    properties
        StartRow
        EndRow
        StartColumn
        EndColumn
        NewData
        SizeChanged
        EventSource
        VarsChanged
    end
end
