classdef TreeInteraction < matlab.ui.eventdata.internal.Interaction
    %

    % Do not remove above white space
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Node
        Level
    end

    methods
        function obj = TreeInteraction(options)
            obj@matlab.ui.eventdata.internal.Interaction(options);
            obj.Node = options.Node;
            obj.Level = options.Level;
        end
    end
    methods (Access = protected)

        function location = getLocation(obj)
            % Calculate pixel position relative to the parent container
            if isa(obj.Source, 'matlab.ui.container.TreeNode')
                positionedComponent = ancestor(obj.Source, {'uitree', 'uicheckboxtree'});
                location =  positionedComponent.Position(1:2) + obj.LocationOffset;
            else 
                location = getLocation@matlab.ui.eventdata.internal.Interaction(obj);
            end
        end
    end
end