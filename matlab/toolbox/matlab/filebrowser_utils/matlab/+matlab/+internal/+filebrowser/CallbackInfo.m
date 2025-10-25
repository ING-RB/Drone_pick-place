classdef CallbackInfo
    % CALLBACKINFO This class describes the input parameter passed into
    % context menu items' callbacks
    %   Contains optional properties for:
    %    "Context", that contains information about the current selection 
    %       and other optional contextual attributes, and is always
    %       present.
    %    "EventData", that contains information about the change of state
    %       of the context-menu widget (like check-box item or radio-button
    %       item), and is only present for stateful menu widgets .
    %    "Options", that contains other optional attributes based on the
    %       feature.

%   Copyright 2024 The MathWorks, Inc.

    properties
        Context
        EventData
        Options
    end
    
    methods
        function obj = CallbackInfo(context, eventData, options)
            if nargin > 0
                obj.Context = context;
            end
            if nargin > 1
                obj.EventData = eventData;
            end
            if nargin > 2
                obj.Options = options;
            end
        end
    end
end
