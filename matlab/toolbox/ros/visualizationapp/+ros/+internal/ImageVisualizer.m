classdef ImageVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2022 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleImage'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'sensor_msgs/Image', 'sensor_msgs/CompressedImage'}
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base

        TagBaseImageAxes = 'RosbagViewerImageVisualizerAxes';
        TagBaseDisplay = 'RosbagViewerImageVisualizerDisplay';
        TagBaseDataSource = 'RosbagViewerImageVisualizerDataSource';
    end

    properties(Access=private)
        % Default Image Location
        DefaultImage = fullfile(matlabroot, "toolbox", "ros", ...
            "visualizationapp", "resources", "icons", "ImageIcon.png");
    end

    methods
        function updateData(obj, dataSourcePath, data)
            %updateData Change the displayed image

            % Avoid updating the image if the data source chosen has changed
            if ((isempty(dataSourcePath) && isempty(obj.DataSources.Value)) || ...
                    strcmp(dataSourcePath, obj.DataSources.Value)) && ~isempty(data.Message.img)
                if ~ismatrix(data.Message.img)
                    obj.GraphicsHandles.CData = data.Message.img;
                else
                    obj.GraphicsHandles.CData = cat(3,data.Message.img,data.Message.img,data.Message.img);
                end
            end
        end
    end

    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and image graphics

            % Data source selection
            obj.DataSourcesID = obj.getNewID;
            dstag = numberTag(obj, obj.TagBaseDataSource);
            obj.DataSources = uidropdown(obj.GridHandle, ...
                                        "Editable", true, ...
                                        "Placeholder", obj.DataSourceLabel, ...
                                        "Items", {''}, ...
                                        "Value", '', ...
                                        "Tag", dstag);
            obj.DataSources.ValueChangedFcn = ...
                @(source, event) makeCallback(obj, ...
                                              obj.DataSourceChangedCallback, ...
                                              source, ...
                                              event, ...
                                              obj.DataSourcesID);
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = 1;

            % Image graphics object
            imgtag = numberTag(obj, obj.TagBaseDisplay);
            axtag = numberTag(obj, obj.TagBaseImageAxes);

            obj.AxesHandle = uiaxes(obj.GridHandle, "Tag", axtag, ...
                                                    "Visible", 'off', ...
                                                    "YDir", 'reverse', ...
                                                    "YLim", [-inf inf], ...
                                                    "XLim", [-inf inf], ...                                           
                                                    "DataAspectRatio", [1 1 1], ...
                                                    "DataAspectRatioMode", "manual",...
                                                    "PlotBoxAspectRatioMode", "auto", ...
                                                    "XLimMode", "auto", ...
                                                    "YLimMode", "auto", ...
                                                    "XLimitMethod", "tight", ...
                                                    "YLimitMethod", "tight");
            % refer axis help for setting for image 
            % https://www.mathworks.com/help/matlab/ref/axis.html#d124e70516    
            obj.GraphicsHandles = image(obj.AxesHandle, ...
                "Tag", imgtag, ...
                "CData", []);
            obj.AxesHandle.Layout.Row = 2;
            obj.AxesHandle.Layout.Column = 1;
        end

        function reinitVisualizer(obj)
            %reinit function is used to reinitialize the ui components to
            %its default values

            obj.GraphicsHandles.CData = [];
        end
    end
end
