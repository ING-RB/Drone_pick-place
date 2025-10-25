classdef PropertyViewer < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.
    
    properties

        PropertyPanel
        PropertyTable
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        %% Tags
        TagPropertyPanel = "PropertyPanel"
        TagPropertyTable = "PropertyTable"
        
        %% Catalogs
        TitlePropertyPanel = getString(message("ros:rosgraphapp:view:TitlePropertyPnl"))
        DescriptionPropertyPanel = getString(message("ros:rosgraphapp:view:DescriptionPropertyPnl"))
    end

    methods
        function obj = PropertyViewer(appContainer)
            
           createPropertyPanel(obj,appContainer)
        end
        
        function createPropertyPanel(obj, appContainer)
            
           propertyPanelOptions.Title = obj.TitlePropertyPanel;
           propertyPanelOptions.Description = obj.DescriptionPropertyPanel;
           propertyPanelOptions.Region = "left";
           obj.PropertyPanel = matlab.ui.internal.FigurePanel(propertyPanelOptions);
           obj.PropertyPanel.Tag = obj.TagPropertyPanel;
           appContainer.add(obj.PropertyPanel);
           % Creating grid layout to make Property panel responsive
           gridLayout = uigridlayout(obj.PropertyPanel.Figure);
           gridLayout.ColumnWidth = {'1x'};
           gridLayout.RowHeight = {'1x'};
           obj.PropertyTable = uitable(gridLayout);
           obj.PropertyTable.Tag = obj.TagPropertyTable;
           obj.PropertyTable.Visible = matlab.lang.OnOffSwitchState.off;
        end

        function update(obj, Keys, Values)
            obj.PropertyTable.Visible = matlab.lang.OnOffSwitchState.on;
            obj.PropertyTable.Data = table(Keys, Values, ...
                'VariableNames', [message("ros:rosgraphapp:view:PropertyTableKeys").string, message("ros:rosgraphapp:view:PropertyTableValues").string]);
        end
    end
        
end

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

    if ~isempty(fcn)
        feval(fcn, varargin{:})
    end
end