classdef (Hidden) CheckBoxTreeController < ...
        matlab.ui.container.internal.controller.TreeController
    % CheckBoxTreeController is the controller for CheckBoxTree

    % Copyright 2011-2021 The MathWorks, Inc.

    methods
        function obj = CheckBoxTreeController(varargin)
            obj@matlab.ui.container.internal.controller.TreeController(varargin{:});

        end
    end

    methods(Access = 'protected')

        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};

            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.container.internal.controller.TreeController(obj, propertyNames), ...
                ];

            if(ismemberForStringArrays("CheckedNodes", propertyNames))

                % Convert Nodes to node ids
                % Use for loop because get does not return consistent
                % results for one node vs multiple nodes
                %
                % For performance reasons, store obj.Model.CheckedNodes
                % before accessing it in the for loop.
                newValue = obj.formatNodes(obj.Model.CheckedNodes);

                viewPvPairs = [viewPvPairs, ...
                    {'CheckedNodes', newValue}, ...
                    ];
            end
        end

        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.container.internal.controller.TreeController(obj, src, event);

            %% Event handling goes here
            if(strcmp(event.Data.Name, 'CheckedNodesChanged'))
                % Handles when the user changes the text in the ui

                % Get the previous value
                previousValue = obj.Model.CheckedNodes;

                % Get the new value
                checkedNodes = string(event.Data.CheckedNodes);

                if isempty(checkedNodes)
                    newValue = [];
                else
                    newValue = obj.Model.getNodesById(checkedNodes);
                end

                % Create event data
                eventData = matlab.ui.eventdata.CheckedNodesChangedData(newValue, previousValue);

                % Update the model and emit 'CheckedNodesChanged' which in turn will
                % trigger the user callback
                obj.handleUserInteraction('CheckedNodesChanged', event.Data, {'CheckedNodesChanged', eventData, 'PrivateCheckedNodes', newValue});
            end
        end
    end
end

