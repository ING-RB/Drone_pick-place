classdef DataChangeEventData < event.EventData
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Event Data Class used when sending data events from either the
    % DataModel or the ViewModel

    % Copyright 2021 The MathWorks, Inc.

    properties
        Range % The indicies of the changed data
        Values % The new data values
        DimensionsChanged % size of data changed
    end
end
