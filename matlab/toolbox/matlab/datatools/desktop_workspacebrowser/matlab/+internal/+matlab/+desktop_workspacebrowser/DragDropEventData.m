classdef DragDropEventData <  event.EventData
    % DragDropEventData event to be dispatched whenever there was a drop on
    % the document

    % Copyright 2021 The MathWorks, Inc.
    % NOTE: This is currently only used by the WorkspaceBrowserDocument.
    properties
        DropData;
        Workspace;
    end  
end

