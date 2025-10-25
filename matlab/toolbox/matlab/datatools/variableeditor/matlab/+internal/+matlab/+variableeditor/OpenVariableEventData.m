classdef OpenVariableEventData <  event.EventData
    %DoubleClickEventData event to be dispatched on double click in Views.

    % Copyright 2021 The MathWorks, Inc.
    % NOTE: This is currently only used by the WorkspaceBrowserDocument.
    properties
        row
        column
        variableName
        parentName % If openvar is a result of a drilldown operation
        workspace
    end  
end

