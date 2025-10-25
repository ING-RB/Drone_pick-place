classdef ListBoxInteraction < matlab.ui.eventdata.internal.Interaction
    %

    % Do not remove above white space
    
    % Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Item
    end

    methods
        function obj = ListBoxInteraction(options)
            obj@matlab.ui.eventdata.internal.Interaction(options);
            obj.Item = options.Item;
        end
    end
end