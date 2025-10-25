classdef PointCloudVisualizer < ros.internal.Visualizer
%This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitlePointCloud'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'sensor_msgs/PointCloud2'}
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerPointCloudVisualizerDisplay'
        TagBaseDataSource = 'RosbagViewerPointCloudVisualizerDataSource'
    end

    methods
        function updateData(obj, dataSourcePath, data)
        %updateData Change the displayed point cloud
      
        % Avoid updating the point cloud if the data source chosen has changed
            if ((isempty(dataSourcePath) && isempty(obj.DataSources.Value)) || ...
                    strcmp(dataSourcePath, obj.DataSources.Value)) && ~isempty(data.Message.xyz)
                xyz = data.Message.xyz;
                rgb = data.Message.rgb;

                ptCloud = pointCloud(xyz, Color=rgb);
                obj.GraphicsHandles.displayPointCloud(ptCloud);                

            end
        end
    end

    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and point cloud graphics

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

            % Point cloud display
            panelHandle = uipanel(obj.GridHandle, "BorderType","none");
            panelHandle.Layout.Row = 2;
            panelHandle.Layout.Column = 1;
            subgrid = uigridlayout(panelHandle, [1, 1], ...
                                    "ColumnSpacing", 0, "RowSpacing", 0);

            obj.GraphicsHandles = pointclouds.internal.app.PointCloudStreamView(subgrid);
            %obj.GraphicsHandles.createAxesToolbarWithExport();
            
            set(subgrid, 'BackgroundColor', [0 0 40/255]);            
        end

        function reinitVisualizer(obj)
            obj.GraphicsHandles.resetView();
        end
    end
end
