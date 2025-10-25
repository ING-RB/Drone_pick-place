classdef LaserScanVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

%   Copyright 2022 The MathWorks, Inc.
%   Copyright 2022-2023 The MathWorks, Inc.
    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleLaserScan'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'sensor_msgs/LaserScan'}
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerLaserScanVisualizerDisplay'
        TagBaseDataSource = 'RosbagViewerLaserScanVisualizerDataSource'
    end

    properties (Access = private)
        PCViewStruct
    end

    methods
        function updateData(obj, dataSourcePath, data)
        %updateData Change the displayed laser scan

        % Avoid updating the laser scan if the data source chosen has changed
            if ((isempty(dataSourcePath) && isempty(obj.DataSources.Value)) || ...
                    strcmp(dataSourcePath, obj.DataSources.Value)) && ...
                    ~isempty(data.Message.xy)
                
                xy = data.Message.xy;
                rgb = data.Message.intensity;
                
                % Transform 2d data to 3d
                xySize = size(xy);
                xyz = xy;
                zeroArr = zeros(xySize(1),1);
                xyz(:,3) = zeroArr;
                %Check for valid color information
                rgbSize = size(rgb);
                if ~isequal(xySize(1),rgbSize(1))
                   rgb = []; 
                end
                
                if ~isempty(rgb)
                        view(obj.GraphicsHandles, xyz, rgb)
                else
                        view(obj.GraphicsHandles, xyz)
                end

                lim = axis(obj.GraphicsHandles.Axes);
                minVals = min([xy; lim(1:2:3)]);
                maxVals = max([xy; lim(2:2:4)]);
                newLim = lim;
                newLim(1:2:3) = minVals;
                newLim(2:2:4) = maxVals;
                if any(newLim ~= lim)
                    axis(obj.GraphicsHandles.Axes, newLim)
                    resetplotview(obj.GraphicsHandles.Axes, 'SaveCurrentView');
                end
            end
        end
    end

    methods (Access = protected)
        function buildInternals(obj)
        %buildInternals Set up data source and laser scan graphics
           
            % Data source selection
            obj.DataSourcesID = obj.getNewID;
            tag = numberTag(obj, obj.TagBaseDataSource);
            obj.DataSources = uidropdown(obj.GridHandle, ...
                                         "Editable", true, ...
                                         "Placeholder", obj.DataSourceLabel, ...
                                         "Items", {''}, ...
                                         "Value", '', ...
                                         "Tag", tag);
            obj.DataSources.ValueChangedFcn = ...
                @(source, event) makeCallback(obj, ...
                                              obj.DataSourceChangedCallback, ...
                                              source, ...
                                              event, ...
                                              obj.DataSourcesID);
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = 1;

            % Laser scan display
            panelHandle = uipanel(obj.GridHandle, "BorderType", "none");
            panelHandle.Layout.Row = 2;
            panelHandle.Layout.Column = 1;
            subgrid = uigridlayout(panelHandle, [1, 1], ...
                "ColumnSpacing", 0, "RowSpacing", 0);
            obj.AxesHandle = uiaxes(subgrid);
            
            % position it to centre of the panel
            obj.AxesHandle.Position = [obj.AxesHandle.Position(1:2) panelHandle.Position(3:4) - 2*obj.AxesHandle.Position(1:2)];
            % create a pcplayer instance
            obj.GraphicsHandles = pcplayer([0 1], [0 1], [0 0.01], ...
                                            "Parent", obj.AxesHandle, ...
                                            "BackgroundColor", [0 0 0], ...
                                            "MarkerSize", 15);
            obj.PCViewStruct = resetplotview(obj.GraphicsHandles.Axes, ...
                                             'GetStoredViewStruct');
            reinitVisualizer(obj);
        end
        
        function reinitVisualizer(obj)
            %reinit function is used to reinitialize the ui components to
            %its default values

            resetplotview(obj.GraphicsHandles.Axes, 'SetViewStruct', obj.PCViewStruct);
            resetplotview(obj.GraphicsHandles.Axes, 'ApplyStoredView');
            obj.GraphicsHandles.view([[0 1]; [0 1]; [0 0.01]]');
            resetplotview(obj.GraphicsHandles.Axes, 'SaveCurrentView');
            view(obj.GraphicsHandles.Axes, 2);
            % Set Axis color to red
            obj.GraphicsHandles.Axes.XColor = [1 0 0]; 
            obj.GraphicsHandles.Axes.YColor = [1 0 0];
        end
    end
end
