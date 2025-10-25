classdef View < handle
    %VIEW is the Appspace Communication Log Section View Class. It creates
    %the communication log table and contains events for user interactions
    %with the table.

    % Copyright 2021 The MathWorks, Inc.

    properties
        Table
    end

    events
        TableRowSelected
    end

    properties
        Constants
    end

    %% Hook methods
    methods
        function constants = getConstants(~)
            constants = matlabshared.transportapp.internal.appspace.communicationlog.Constants;
        end
    end

    methods
        function obj = View(parentPanel, ~)
            obj.Constants = obj.getConstants();
            obj.createTable(parentPanel);
            obj.setupEvents();
        end
    end

    methods (Access = private)
        function createTable(obj, parent)
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory

            grid = AppSpaceElementsFactory.createGridLayout ...
                (parent, obj.Constants.TableParentGrid);

            obj.Table = AppSpaceElementsFactory.createTable(grid, ...
                AppSpaceGridLayout(1, 1), obj.Constants.Table);
        end

        function setupEvents(obj)
            obj.Table.CellSelectionCallback = @obj.tableIndexSelected;
        end
    end

    %% Event Callback Functions
    methods
        function tableIndexSelected(obj, ~, evt)

            if ~isempty(evt.Indices)
                eventData = matlabshared.transportapp.internal.utilities.EventData(evt.Indices(1));
                obj.notify("TableRowSelected", eventData);
            end
        end
    end
end