classdef OdometryVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleOdometry'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'nav_msgs/Odometry'}

        GraphicHandleIdx = 1;
    end

    properties (SetAccess = protected)
        % Indicator of current position
        IndicatorHandles

        % Basic triangle, to be scaled, moved, and rotated
        BaseIndicatorPoints = [0.025 0 0 ; 0 0.0110 -0.0110];

        % surface data for 3D marker based on object pose
        Marker3DSurf

        % Base surface data for 3D marker
        Marker3DBaseSurf

		DataRangeUpdated = false
        PendingData = {}

        % For Marker
        Scale
        XPos
        YPos
        ZPos
        Yaw
        Quat
        MarkerScatter
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerOdometryVisualizerDisplay'
        TagBaseIndicator = 'RosbagViewerOdometryVisualizerIndicator'
        TagBaseDataSource = 'RosbagViewerOdometryVisualizerDataSource'

        % margin around the sides
        % Set 3D marker precision: Number of points used to construct
        % the surface of each of the four faces of the 3D marker (cone,
        % cone base, cylinder, cylinder base) will be determined by
        % this number. Higher precision value results in more dense
        % surface. Avoid increasing points to keep the surface color
        % 'light' (dense surfaces tend to be black if the edge color is
        % black).

        % 3D marker precision (number of grid points in surface)
        Marker3DPrecision = 4

        % 3D marker scale
        Marker3DScale = 0.025

        % Camera Angle of the 3D Plot
        CameraAngle = [-37.5 30]; ... [-5 2 5] ; ...[58 15]
    end

    methods

        function updateGraphicHandleIdx(obj)
            %updateGraphicHandleIdx is used to create the new GraphicsHandles
            %whenever pause button is pressed so that we can display
            %discontinuous graph

            obj.GraphicHandleIdx = obj.GraphicHandleIdx + 1;
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles(obj.GraphicHandleIdx) = ...
                ros.internal.view.LineHelper3D(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
        end

        

        function updateData(obj, dataSourcePath, dataContainer)
            %updateData Change the displayed position indicator
            if ~obj.DataRangeUpdated
                pendingData.dataSourcePath = dataSourcePath;
                pendingData.dataContainer = dataContainer;
                obj.PendingData{length(obj.PendingData) + 1} = pendingData;
                return
            end
            [~, fieldPath] = splitTopicFieldPath(dataSourcePath);
            if isempty(fieldPath)
                msg = dataContainer.Message;
            else
                msg = getfield(dataContainer.Message, fieldPath{:});
            end

            fieldMap = dataContainer.FieldMap;
            obj.XPos = eval(['msg.' char(fieldMap.position.x)]); %#ok<EVLDOT>
            obj.YPos = eval(['msg.' char(fieldMap.position.y)]); %#ok<EVLDOT>
            obj.ZPos = eval(['msg.' char(fieldMap.position.z)]); %#ok<EVLDOT>
            qw = eval(['msg.' char(fieldMap.orientation.w)]); %#ok<EVLDOT>
            qz = eval(['msg.' char(fieldMap.orientation.z)]); %#ok<EVLDOT>
            qx = eval(['msg.' char(fieldMap.orientation.w)]); %#ok<EVLDOT>
            qy = eval(['msg.' char(fieldMap.orientation.z)]); %#ok<EVLDOT>
            obj.Quat = quaternion(qw,qx,qy,qz);

            obj.Yaw = atan2(2.*qw.*qz, qw.^2-qz.^2);

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.GraphicsHandles(obj.GraphicHandleIdx).XData(end+1) = obj.XPos;
                obj.GraphicsHandles(obj.GraphicHandleIdx).YData(end+1) = obj.YPos;
			    obj.GraphicsHandles(obj.GraphicHandleIdx).ZData(end+1) = obj.ZPos;
            end
			
            if ~(qw==0 && qx==0 && qy==0 && qz==0)
                %updateMarker(obj)
                updateMarker3D(obj);
            else
                obj.MarkerScatter.XData = obj.XPos;
                obj.MarkerScatter.YData = obj.YPos;
                obj.MarkerScatter.ZData = obj.ZPos;
                if ~(obj.MarkerScatter.Visible)
                    obj.MarkerScatter.Visible = true;
                end

                if strcmp(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)            
                    throw(MException('ros:visualizationapp:view:InvalidQuaternion', message("ros:visualizationapp:view:InvalidQuaternionLiveData", qw, qx, qy, qz)));
                else
                    throw(MException('ros:visualizationapp:view:InvalidQuaternion', message("ros:visualizationapp:view:InvalidQuaternion", qw, qx, qy, qz, num2str(dataContainer.Time))));
                end
                
            end	
        end

        function setFullData(obj, dataSourcePath, data, ~, fieldMap)
            %setFullData Set the data from the data source to the graphics
            
            crPgIdHdle = obj.launchCircularProgressIndicator();
            c = onCleanup(@()delete(crPgIdHdle));
            
            x = arrayfun(@(msg)eval(['msg.' char(fieldMap.position.x)]), data); %#ok<EVLDOT>
            y = arrayfun(@(msg)eval(['msg.' char(fieldMap.position.y)]), data); %#ok<EVLDOT>
            z = arrayfun(@(msg)eval(['msg.' char(fieldMap.position.z)]), data); %#ok<EVLDOT>
            
            for idxDataSource = 1:numel(obj.DataSources)
                if strcmp(dataSourcePath, obj.DataSources(idxDataSource).Value)
                    obj.GraphicsHandles(idxDataSource).XData = x;
                    obj.GraphicsHandles(idxDataSource).YData = y;
                    obj.GraphicsHandles(idxDataSource).ZData = z; % addition for 3D marker
                end
            end
            obj.DataRangeUpdated = true;

            if ~isempty(obj.PendingData)
                for ii = 1:length(obj.PendingData)
                    updateData(obj, obj.PendingData{ii}.dataSourcePath, ...
                        obj.PendingData{ii}.dataContainer);
                end
            end
        end
    end

    methods (Access = protected)
        function updateMarker(obj)
            %updateMarker Compute and plot indicator based on current pose

            % Get current axes size and scaling indicator
            xscale = diff(xlim(obj.AxesHandle));
            yscale = diff(ylim(obj.AxesHandle));
            obj.Scale = max(xscale, yscale);
            points(1,:) = obj.BaseIndicatorPoints(1,:).* obj.Scale ;
            points(2,:) = obj.BaseIndicatorPoints(2,:).* obj.Scale ;

            % Rotate and translate the indicator to the right position
            rot = [cos(obj.Yaw) - sin(obj.Yaw) ; sin(obj.Yaw) cos(obj.Yaw)];
            points = rot* points;
            points = points + [obj.XPos ; obj.YPos];

            % Update the visuals
            obj.IndicatorHandles.XData = points(1, :);
            obj.IndicatorHandles.YData = points(2, :);
        end

        function updateMarker3D(obj)
            %updateMarker3D udpate 3D marker pose

            % Get base surface vertices
            point = [obj.XPos, obj.YPos, obj.ZPos];
            xscale = diff(xlim(obj.AxesHandle));
            yscale = diff(ylim(obj.AxesHandle));
            zscale = diff(zlim(obj.AxesHandle));
            obj.Scale = obj.Marker3DScale* max([xscale yscale zscale]);

            surfVertices = obj.Marker3DBaseSurf;

            % Rotate surface vertices
            rotMatrix = rotmat(obj.Quat, 'point');
            % M = (Number of faces in marker (4)) * (marker precision)
            M = size(surfVertices, 1);
            % N = marker precision
            N = size(surfVertices, 2);
            for i = 1:M
                for j = 1:N
                    surfVertices(i, j, 1:3) = ...
                        rotMatrix*squeeze(surfVertices(i, j, 1:3));
                end
            end
            % Translate rotated surface vertices from origin to point
            surfVertices(:, :, 1) = surfVertices(:, :, 1) * obj.Scale + point(1);
            surfVertices(:, :, 2) = surfVertices(:, :, 2) * obj.Scale + point(2);
            surfVertices(:, :, 3) = surfVertices(:, :, 3) * obj.Scale + point(3);

            % Update surface vertices in plot
            obj.Marker3DSurf.XData = surfVertices(:, :, 1);
            obj.Marker3DSurf.YData = surfVertices(:, :, 2);
            obj.Marker3DSurf.ZData = surfVertices(:, :, 3);
        end
        function buildInternals(obj)
            %buildInternals Set up data source and plot

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            end

            % Data source selection
            obj.DataSourcesID = obj.getNewID;

            % X data source
            tag = numberTag(obj, obj.TagBaseDataSource, 1);
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
                obj.DataSourcesID(1));
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = 1;

            % Axes graphics object
            obj.AxesHandle = uiaxes(obj.GridHandle);
            obj.AxesHandle.Layout.Row = 2;
            obj.AxesHandle.Layout.Column = 1;
            obj.defaultAxesSetting();

            % set 3D view
            view(obj.AxesHandle, obj.CameraAngle);

            obj.Marker3DBaseSurf = generate3DMarkerSurface(obj);

            % Create surface for 3D marker object. Refer to 'surf'
            % documentation to customize marker appearance.
            obj.Marker3DSurf = surf(obj.AxesHandle, ...
                zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision), ...
                zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision), ...
                zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision), ...
                "FaceColor", [1 0 0], ...
                "FaceLighting", "none", ...
                "EdgeColor", [0 0 0], ...
                "EdgeAlpha", "0.3");

            % Position indicator graphics object
            % tag = numberTag(obj, obj.TagBaseIndicator);
            % obj.IndicatorHandles = patch(obj.AxesHandle, ...
            %                             "XData", nan(1, 3), ...
            %                             "YData", nan(1, 3), ...
            %                             "Tag", tag);

            % add X and Y LimitsChange callback to resize the marker
            addlistener(obj.AxesHandle, 'XLim', 'PostSet', @(~, ~)obj.resize3DMarker());
            addlistener(obj.AxesHandle, 'YLim', 'PostSet', @(~, ~)obj.resize3DMarker());
            addlistener(obj.AxesHandle, 'ZLim', 'PostSet', @(~, ~)obj.resize3DMarker());
            addlistener(obj.AxesHandle, 'SizeChanged', @(~, ~)obj.resize3DMarker());
            % for data without orientation
            obj.MarkerScatter = scatter3(obj.AxesHandle,0,0,0);
            obj.MarkerScatter.Visible=false;
            obj.MarkerScatter.LineWidth=3;
            obj.MarkerScatter.SizeData=50;

            % Line graphics object
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles = ...
                ros.internal.view.LineHelper3D(obj.AxesHandle,  "Color", [1, 0.5, 0],"Tag", tag);
        end

        function defaultAxesSetting(obj)
            %defaultAxesSetting set axes settings

            obj.AxesHandle.NextPlot = "add";
            % obj.AxesHandle.XLim = [0 1];
            % obj.AxesHandle.YLim = [0 1];
            % obj.AxesHandle.ZLim = [0 1];
            obj.AxesHandle.XGrid = 'on';
            obj.AxesHandle.YGrid = 'on';
            obj.AxesHandle.ZGrid = 'on';
            obj.AxesHandle.XLabel.String = getString(message('ros:visualizationapp:view:XAxisLabel'));
            obj.AxesHandle.YLabel.String = getString(message('ros:visualizationapp:view:YAxisLabel'));
            obj.AxesHandle.ZLabel.String = getString(message('ros:visualizationapp:view:ZAxisLabel'));

            % Turn clipping off will prevent data from disappearing when
            % user pans 3D plot area. Turning this on will ensure plotted
            % data doesn't 'spill' out of axes limits.
            obj.AxesHandle.Clipping = 'on';

            % Set data aspect ratio to keep uniform look for 3D marker
            % from all viewing angles
            obj.AxesHandle.DataAspectRatio = [1 1 1];
        end

        function reinitVisualizer(obj)
            %reinitVisualizer function is used to reinitialize the ui
            % components to its default values
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
			    obj.GraphicsHandles = [];
                tag = numberTag(obj, obj.TagBaseDisplay);
                obj.GraphicsHandles = ...
                    ros.internal.view.LineHelper3D(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
                obj.GraphicHandleIdx = 1;
            end
            obj.GraphicsHandles.XData = [];
            obj.GraphicsHandles.YData = [];
            obj.GraphicsHandles.ZData = [];

            reset(obj.AxesHandle);
            obj.defaultAxesSetting();

            % reset local properties
            obj.Scale = [];
            obj.XPos = [];
            obj.YPos = [];
            obj.ZPos = [];
            obj.Yaw = [];
            obj.Quat = [];

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            else
                obj.DataRangeUpdated = false;
            end

            obj.Marker3DSurf.XData = zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision);
            obj.Marker3DSurf.YData = zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision);
            obj.Marker3DSurf.ZData = zeros(obj.Marker3DPrecision*4, obj.Marker3DPrecision);

             view(obj.AxesHandle, obj.CameraAngle);
        end

        function resizeMarker(obj)
            % resize 2d marker

            if any(isnan(obj.IndicatorHandles.XData)) && any(isnan(obj.IndicatorHandles.YData))
                return;
            end
            obj.updateMarker();
        end

        function resize3DMarker(obj)
            %resize3DMarker

            if (isempty(obj.Quat))
                return;
            end
            obj.updateMarker3D();
        end          
		
		function surfaceVertices = generate3DMarkerSurface(obj)
            % generate3DMarkerSurface create base surface for an arrow
            % shaped 3D marker

            % Create conical face
            coneRadius = 1/3; ...obj.Marker3DScale/3; % Radius of cone
                coneH = 1; ....obj.Marker3DScale; % height of cone
                m = coneH/coneRadius;
            coneNT = linspace(0,2*pi,obj.Marker3DPrecision); % angles
            coneNR = linspace(0,coneRadius,obj.Marker3DPrecision); %  Radius
            [coneT, coneR] = meshgrid(coneNT,coneNR) ;
            % Convert grid to cartesian coordintes
            coneY = coneR.*cos(coneT);
            coneZ = coneR.*sin(coneT);
            coneX = coneH - m*coneR;

            % Create circular base for cone
            % Generate the Polar angle vector containing information about
            % sector location and angle
            circleNT = linspace(0, 2*pi, obj.Marker3DPrecision);
            % Generate the Radius vector
            circleNR = linspace(0, coneRadius, obj.Marker3DPrecision);
            % Create a grid from angle and Radius
            [circleT, circleR] = meshgrid(circleNT,circleNR);
            % Create X,Y matrices calculated on grid.
            circleY = circleR.*cos(circleT);
            circleZ = circleR.*sin(circleT);
            % Calculate the function
            circleX = zeros(obj.Marker3DPrecision, obj.Marker3DPrecision);

            % Create cylindrical face (cylinder of radius is 25% smaller
            % than that of cone)
            cylinderNT = circleNT;
            cylinderNR = coneRadius*0.75*ones(1, obj.Marker3DPrecision);
            [cylinderT, cylinderR] = meshgrid(cylinderNT,cylinderNR);
            cylinderY = cylinderR.*cos(cylinderT);
            cylinderZ = cylinderR.*sin(cylinderT);
            cylinderX = ones(obj.Marker3DPrecision).*(linspace(0, ...
                -coneH, obj.Marker3DPrecision))';

            % Create circular base for cylinder
            cylinder_baseX = -coneH*ones(obj.Marker3DPrecision);
            cylinder_baseY = circleY*0.75;
            cylinder_baseZ = circleZ*0.75;

            % Combine all faces: cone, cone circular base, cylinder,
            % cylinder circular base
            surfaceVertices(:, :, 1) = [coneX; circleX; cylinderX;
                cylinder_baseX];
            surfaceVertices(:, :, 2) = [coneY; circleY; cylinderY;
                cylinder_baseY];
            surfaceVertices(:, :, 3) = [coneZ; circleZ; cylinderZ;
                cylinder_baseZ];
        end
    end
end

function [topic, fieldPath] = splitTopicFieldPath(fullPath)
splitPath = strsplit(fullPath, '.');
topic = splitPath{1};
fieldPath = {};
if numel(splitPath) > 1
    fieldPath = splitPath(2:end);
end
end
