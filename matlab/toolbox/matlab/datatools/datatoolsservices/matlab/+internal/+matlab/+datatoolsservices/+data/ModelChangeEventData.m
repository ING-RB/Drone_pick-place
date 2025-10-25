classdef ModelChangeEventData < event.EventData
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Event Data Class used when sending model changed events from the
    % ViewModel

    % Copyright 2021 The MathWorks, Inc.
    properties
        Row % Row Number
        Column % Column Number
        Key % The parameter changed
        OldValue % Previous Value
        NewValue % The new data value
    end
end
