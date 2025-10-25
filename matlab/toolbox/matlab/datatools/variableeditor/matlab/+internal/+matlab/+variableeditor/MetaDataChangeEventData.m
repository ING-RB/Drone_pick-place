classdef MetaDataChangeEventData < event.EventData 
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Event Data Class used when sending data events from either the
    % DataModel or the ViewModel

    % Copyright 2021 The MathWorks, Inc.
    properties
        Property % The Meta Data Property that Changed
        IsTypeChange % True if this is a datatype change
        OldValue % The old data values
        NewValue % The new data values
    end
end
