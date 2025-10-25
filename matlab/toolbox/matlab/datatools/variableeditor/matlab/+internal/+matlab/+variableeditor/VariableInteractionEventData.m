classdef VariableInteractionEventData < event.EventData
    % Event Data Class used when sending data events from either the
    % DataStore

    % Copyright 2023 The tMathWorks, Inc.

    properties
        UserAction;
        Index; % View index of the column being interacted with
        DataIndex; % Actual Data index of the Interaction (Offset for views with nested tables and grouped columns)
        Code;
    end
end
