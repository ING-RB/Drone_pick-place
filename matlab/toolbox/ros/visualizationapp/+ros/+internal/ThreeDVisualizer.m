classdef ThreeDVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitle3D'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'sensor_msgs/PointCloud2', 'sensor_msgs/LaserScan', ...
            'visualization_msgs/MarkerArray','visualization_msgs/Marker'}

        GraphicHandleIdx = 1;

        Viewer
    end

    properties (SetAccess = protected)
        DataRangeUpdated = false
        PendingData = {}

        % Creating a temporary marker which can be utilized to plot list
        % based marker such as Point, Sphere, Cube list markers
        % tempMarker = rosmessage('sensor_msgs/PointCloud2');

        % Camera properties for plotting point marker
        cameraRight = [];
        cameraUp = [];

        % The below property stores the measure distance plot handle
        measureDistanceHandle = [];
        measureDistanceTextHandle = [];

        % field map for ros and ros2
        FieldMap

        % Camera Angle of the 3D Plot
        CameraAngle = [-37.5 30]; ... [-5 2 5] ; ...[58 15]
        NoOfFaces = 100 % used for arrow and sphere

        %Container to map sources to viewer containers
        SourceContMap;

        %Source to which the data will be set.
        Source

        %Current Mode (2D or 3D)
        CurrentMode

        %Default camera position to be used when switching to 3D
        DefaultCameraPos
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerMarkerVisualizerDisplay'
        TagBaseIndicator = 'RosbagViewerMarkerVisualizerIndicator'
        TagBaseDataSource = 'RosbagViewerMarkerVisualizerDataSource'
    end

    methods
        function updateGraphicHandleIdx(~)
            %updateGraphicHandleIdx is used to create the new GraphicsHandles
            %whenever pause button is pressed so that we can display
            %discontinuous graph

            % obj.GraphicHandleIdx = obj.GraphicHandleIdx + 1;
            % tag = numberTag(obj, obj.TagBaseDisplay);
            % obj.GraphicsHandles(obj.GraphicHandleIdx) = ...
            %     ros.internal.view.LineHelper3D(obj.AxesHandle, ...
            %                                     "Color", [1, 0.5, 0], ...
            %                                     "Tag", tag);
        end

        function updateData(obj, dataSourcePath, dataContainer, source_props)
            
            
            if ~isempty(obj.Viewer.Annotations)
                obj.Viewer.Annotations = [];
                %Clear any annotations that user has drawn on the screen.
                %They won't be relevant after this update.
            end
            
            % Obtain the message data
            [~, fieldPath] = splitTopicFieldPath(dataSourcePath);
            if isempty(fieldPath)
                msg = dataContainer.Message;
            else
                msg = getfield(dataContainer.Message, fieldPath{:});
            end

            fieldMap = dataContainer.FieldMap;
            obj.FieldMap = fieldMap;

            
            source = dataContainer.Topic;
            obj.Source = source;
            
            if ~isKey(obj.SourceContMap, source)
                obj.addSource(source, dataContainer.DataType);
            end
            textPlot = false;

            if strcmp(dataContainer.DataType, "pointcloud")
                
                [vert_data, color_data] = obj.getPointCloudData(dataContainer);
                
            elseif strcmp(dataContainer.DataType, "laserscan")            
                [vert_data, color_data] = obj.getLaserScanData(dataContainer);
                
            elseif strcmp(dataContainer.DataType, "marker")

                [vert_data, color_data, textPlot] = getMarkerData(obj, msg, fieldMap, dataContainer.Topic);
                
            else
                %TODO author error
                error(message("ros:visualizationapp:view:ThreeDUnsupportedMessageType"),msgType, source)
            end

            if ~strcmp(source_props.ColorMode, 'Default')
                color_data = source_props.Color;
            end
            container = obj.SourceContMap(source);
            if ~textPlot
                container.Data = vert_data;
                if ~isempty(color_data)
                    container.Color = color_data;
                end
            end
            % Better camera management g3437261. Call drawnow to refresh
            % visualizer and change camera to manual. First call should be
            % such that user can easily find the visualized object.
            % drawnow;
            obj.changeCameraModeManual();
        end
      
        function [draw_data, color] = getPointCloudData(~, dataContainer)
            data = dataContainer.Message;
            xyz = data.xyz;
            color = data.rgb;
            draw_data = xyz;
        end

        function [draw_data, color] = getLaserScanData(~, dataContainer)
            data = dataContainer.Message;
            xy = data.xy;
            rgb = data.intensity;
            
            % Transform 2d data to 3d
            xySize = size(xy);
            xyz = xy;
            zeroArr = zeros(xySize(1),1);
            xyz(:,3) = zeroArr;
            
            color = rgb;
            draw_data = xyz;
        end
       

        function [out_data, color, textPlot] = getMarkerData(obj, msg, fieldMap, topic)
            % Check if message type is Marker Array or Marker
            if msg.(fieldMap.messageType) == "visualization_msgs/MarkerArray"
                marker_array_size = numel(msg.(fieldMap.markers));
            else
                % If the message type is marker then create a single
                % element Marker array
                % Note: This is done for better re-usability of code
                marker_array_size = 1;
                msg = struct("MessageType", "visualization_msgs/Marker", "markers", msg);
            end

            tri_data = [];
            color_data = [];
            for i = 1:marker_array_size
                
                if marker_array_size > 1
                    % If handling a MarkerArray, dynamically access each Marker
                    Marker = msg.(fieldMap.markers)(i);
                else
                    % For a single Marker, the Marker itself is already defined
                    Marker = msg.markers(i);
                end

                textPlot = false;
                switch Marker.(fieldMap.type)
                    case 0 % defined as per message Definition for visualization_msgs/Marker Message
                        % 0 is ARROW
                        [tri, color] = getTriArrowMarker(obj, Marker);
                    case 1
                        % 1 is CUBE
                        [tri, color] = getTriCubeMarker(obj, Marker);
                    case 2
                        % 2 is SPHERE
                        [tri, color] = getTriSphereMarker(obj, Marker);
                    case 3
                        % 3 CYLINDER
                        [tri, color] = getTriCylinderMarker(obj, Marker);
                    case 4
                        % uint8 LINE_STRIP=4
                        obj.SourceContMap(source) = images.ui.graphics.ThinLine;
                        [tri, color] = getTriLineStripMarker(obj, Marker);
                    case 5
                       % uint8 LINE_LIST=5

                        obj.SourceContMap(topic) = images.ui.graphics.ThinLine;
                        [tri, color] = getTriLineListMarker(obj, Marker);
                    
                    case {6, 7, 8, 11}
                        % uint8 CUBE_LIST=6
                        % uint8 SPHERE_LIST=7
                        % uint8 POINTS=8
                        % uint8 TRIANGLE_LIST=11

                        [tri, color] = getTriList(obj, Marker, Marker.(fieldMap.type));
                    case 9
                        % uint8 TEXT_VIEW_FACING=9

                        
                        [pos, text] = getTextMarkerData(obj, Marker);
                        container = images.ui.graphics.internal.Text("Label", text, "Position", pos);
                        obj.SourceContMap(topic) = container;
                        obj.Viewer.Text = [obj.Viewer.Text container];

                        textPlot = true;
                    case 10
                        % uint8 MESH_RESOURCE=10
                        [tri, color] = getTriMeshMarker(obj, Marker);

                    otherwise
                        % TO DO - Throw an error instead
                        error(message("ros:visualizationapp:view:ThreeDUnkownMarkerType", Marker.(fieldMap.type), topic))
                end

                if ~textPlot
                    tri_data = obj.concatenateTriangulations(tri_data, tri);
                    numOfTriangles = size(tri.ConnectivityList, 1);
                    color = repmat(color, numOfTriangles, 1);
                    color_data = [color_data; color];
                end
            end
            out_data = tri_data;
            color = color_data;
        end

        function [textPosition, textData] = getTextMarkerData(obj, Marker)
            textPosition = [getNestedField(Marker, obj.FieldMap.pose.position.x), ...
                getNestedField(Marker, obj.FieldMap.pose.position.y),...
                getNestedField(Marker, obj.FieldMap.pose.position.z)];
            textData = Marker.(obj.FieldMap.text);
            

        end

        function addSourceContainer(obj, source, container)
            container.UserData = source;
            obj.SourceContMap(source) = container;
        end

        function addSource(obj, source, msgType)
            if strcmp(msgType, 'pointcloud') || ...
                    strcmp(msgType, 'laserscan')
                container = images.ui.graphics.Points(obj.Viewer);
            elseif strcmp(msgType, 'marker')
                
                container = images.ui.graphics.Surface(obj.Viewer);
            else
                error(message("ros:visualizationapp:view:ThreeDUnsupportedMessageType"),msgType, source)
            end
            % If we are add new source, first change to auto. This will
            % reset the camera properly. During update we will change it
            % back to manual after we set the data.
            obj.changeCameraModeAuto()
            container.UserData = source;

            obj.SourceContMap(source) = container;
        end


        function removeSource(obj, source)
            if isKey(obj.SourceContMap, source)
                remove(obj.SourceContMap, source);

                child = [];
                for i = 1:length(obj.Viewer.Children)
                    if isvalid(obj.Viewer.Children(i)) && isequal(obj.Viewer.Children(i).UserData, source)
                        child = obj.Viewer.Children(i);
                    end
                end
                if ~isempty(child)
                    delete(child);
                end
            end
            if ~isempty(obj.SourceContMap)
                obj.changeCameraModeAuto() %Once last source is removed. Revert back to auto settings.
            end
        end

        function viewToggle(obj)
            import images.ui.graphics.internal.helpers.*

            currentMode = obj.CurrentMode;
            if (strcmp(currentMode, "2d"))
                newMode = "3d";
                obj.Viewer.Mode.CurrentMode = "Default";
                obj.Viewer.Interactions = ["zoom", "pan", "annotate", "rotate"];

                obj.Viewer.CameraUpVector = obj.DefaultCameraPos.CameraUpVector;
                obj.Viewer.CameraPosition = obj.DefaultCameraPos.CameraPosition;
                obj.Viewer.CameraTarget = obj.DefaultCameraPos.CameraTarget;
                obj.Viewer.CameraZoom = obj.DefaultCameraPos.CameraZoom;
                drawnow;

            else
                % Save current camera settings
                obj.DefaultCameraPos = struct();
                obj.DefaultCameraPos.CameraPosition = obj.Viewer.CameraPosition;
                obj.DefaultCameraPos.CameraTarget = obj.Viewer.CameraTarget;
                obj.DefaultCameraPos.CameraUpVector = obj.Viewer.CameraUpVector;
                obj.DefaultCameraPos.CameraZoom = obj.Viewer.CameraZoom;

                newMode = "2d";
                obj.Viewer.Mode.CurrentMode = "Pan";
                obj.Viewer.Interactions = ["zoom", "pan", "annotate"];
                view(obj.Viewer,0,90);
                drawnow;
            end
            obj.CurrentMode = newMode;
        end

        function plotted = measureDistance(obj, dataTips)
            %TODO Need to consider as visualizer provides a native way to
            %measure distances.
        end        
    end
    
    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and plot
            % Data source selection
            obj.DataSourcesID = obj.getNewID;
            obj.SourceContMap = containers.Map();

            obj.Viewer = images.ui.graphics.Viewer(obj.GridHandle, ...
                "BackgroundGradient", false, ...
                "RenderingQuality", 'medium', ...
                "Interactions",  ["rotate", "zoom", "pan", "annotate"], ...
                "CameraStyle", "perspective", ...
                "CameraViewAngle", 75, ...
                "BackgroundColor", [0 0 0]);

           obj.Viewer.Layout.Row = [1 2];
           obj.Viewer.Mode.Default.Fit = "tight";
           obj.Viewer.Mode.Annotate.Style = "line";
           obj.CurrentMode = "3d";
           obj.Viewer.DiffuseLight = 0.5;
           obj.Viewer.AmbientLight = 1.0;
           % obj.Viewer.Camera.Near = 0.5;
           % obj.Viewer.Camera.Far = 5000;
           

        end

        
        function reinitVisualizer(obj)
            %reinitVisualizer function is used to reinitialize the ui
            % components to its default values
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
			    obj.GraphicsHandles = [];
                % tag = numberTag(obj, obj.TagBaseDisplay);
                % obj.GraphicsHandles = ...
                %     ros.internal.view.LineHelper3D(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
                % obj.GraphicHandleIdx = 1;
            end
            
            obj.Viewer.Children = [];
            obj.SourceContMap = containers.Map();

        end
        %TODO: Will shift all Marker message parsing to C++ for performance
        %(g3411390)
       %%get Triangulation method starts

       % Change Camera to manual. Call this function once something is
       % drawn to visualizer. This is needed because if camera is auto it
       % keeps resetting every frame.
       function changeCameraModeManual(obj)
            if ~strcmp(obj.Viewer.CameraPositionMode, 'manual') || ...
                    ~strcmp( obj.Viewer.CameraTargetMode, 'manual')
                %First let drawing complete or else camera will be facing
                %nothing.
                drawnow;
                obj.Viewer.CameraPositionMode = 'manual';
                obj.Viewer.CameraTargetMode = 'manual';
                obj.Viewer.CameraZoomMode = 'manual';
                obj.Viewer.CameraUpVectorMode = 'manual';
            end
       end

       function changeCameraModeAuto(obj)
           if ~strcmp(obj.Viewer.CameraPositionMode, 'auto') || ...
                    ~strcmp( obj.Viewer.CameraTargetMode, 'auto')
                obj.Viewer.CameraPositionMode = 'auto';
                obj.Viewer.CameraTargetMode = 'auto';
                obj.Viewer.CameraZoomMode = 'auto';
                obj.Viewer.CameraUpVectorMode = 'auto';
            end
       end

       function [triObj, faceColor] = getTriArrowMarker(obj, Marker)
            % This function converts an arrow Marker into a single triangulation object
        
            if ~isempty(Marker.(obj.FieldMap.Points))
                % Case 1: The "Points" property is provided
                Marker = transformPointsToGlobalFrame(obj, Marker);
                startPoint = [Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.x), Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.y), Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.z)];
                endPoint = [Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.x), Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.y), Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.z)];
                totalHeight = sqrt(sum((startPoint-endPoint).^2));
                arrowHeight = getNestedField(Marker, obj.FieldMap.scale.z);
                if arrowHeight == 0
                    arrowHeight = 0.25 * totalHeight;
                end
                cylinderRadius = getNestedField(Marker, obj.FieldMap.scale.x);
                arrowRadius = getNestedField(Marker, obj.FieldMap.scale.y);
            else
                % Case 2: The "Points" property is not provided
                startPoint = [Marker.(obj.FieldMap.pose.position.x), getNestedField(Marker, obj.FieldMap.pose.position.y), getNestedField(Marker, obj.FieldMap.pose.position.z)];
                totalHeight = getNestedField(Marker, obj.FieldMap.scale.x);
                arrowHeight = getNestedField(Marker, obj.FieldMap.scale.z);
                arrowRadius = getNestedField(Marker, obj.FieldMap.scale.y);
                cylinderRadius = 0.5 * arrowRadius;
                endPoint = startPoint + [totalHeight, 0, 0];
            end
        
            directionVector = (endPoint - startPoint) / norm(endPoint - startPoint);
            cylinderHeight = totalHeight - arrowHeight;
            coneStartPoint = startPoint + cylinderHeight * directionVector;
            cylinderStartPoint = startPoint;
        
            [coneX, coneY, coneZ] = cylinder([arrowRadius, 0], obj.NoOfFaces);
            [cylinderX, cylinderY, cylinderZ] = cylinder(cylinderRadius, obj.NoOfFaces);
        
            coneZ = coneZ * arrowHeight;
            cylinderZ = cylinderZ * cylinderHeight;
        
            [coneX, coneY, coneZ] = transformPointsUsingDirectionVector(obj, coneX, coneY, coneZ, coneStartPoint, directionVector);
            [cylinderX, cylinderY, cylinderZ] = transformPointsUsingDirectionVector(obj, cylinderX, cylinderY, cylinderZ, cylinderStartPoint, directionVector);
        
            % Convert cone and cylinder surfaces to patch data
            [coneFaces, coneVertices] = surf2patch(coneX, coneY, coneZ, 'triangles');
            [cylinderFaces, cylinderVertices] = surf2patch(cylinderX, cylinderY, cylinderZ, 'triangles');
        
            % Offset cylinder faces indices by the number of cone vertices
            cylinderFaces = cylinderFaces + size(coneVertices, 1);
        
            % Combine vertices and faces
            combinedVertices = [coneVertices; cylinderVertices];
            combinedFaces = [coneFaces; cylinderFaces];
        
            % Create a single triangulation object
            triObj = triangulation(combinedFaces, combinedVertices);
        
            % Extract color data
            faceColor = [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)];
       end

       function [tri, color] = getTrilist(obj, Marker, type)
            % Transform the points to global frame using the "Pose" property
            Marker = transformPointsToGlobalFrame(obj, Marker);
        
            % Check if the Marker has the "Colors" property, if not then
            % populate it with "Color" data. This helps in error handling 
            % as all list markers expect to have Color data for each point
            if isempty(Marker.(obj.FieldMap.Colors))
                Marker = setNestedField(Marker, obj.FieldMap.Colors, ...
                    repmat(struct("MessageType", "std_msgs/ColorRGBA", ...
                    string((obj.FieldMap.r)), getNestedField(Marker, obj.FieldMap.color.r), ...
                    string((obj.FieldMap.g)), getNestedField(Marker, obj.FieldMap.color.g), ...
                    string((obj.FieldMap.b)), getNestedField(Marker, obj.FieldMap.color.b), ...
                    string((obj.FieldMap.a)), getNestedField(Marker, obj.FieldMap.color.a)), ...
                    size(Marker.(obj.FieldMap.Points)))); 
            end
        
            % Initialize the outputs
            triObj = [];
            faceColor = [];
        
            % Iterate through the Points and plot the Marker
            for i = 1:size(Marker.(obj.FieldMap.Points), 2)
                % Check Marker Type
                switch type
                    case 6
                        % CUBE_LIST=6
                        [tri, color] = getTriCubeMarker(obj, Marker);
                    case 7
                        [tri, color] = getTriSphereMarker(obj, Marker);
                    case 11
                        % TRIANGLE_LIST=11
                        % Extract vertices and faces for the triangulation
                        vertices = Marker.(obj.FieldMap.Points);
                        faces = Marker.(obj.FieldMap.Faces);
        
                        % Use surf2patch to convert the surface data to patch data
                        [f, v, c] = surf2patch('Vertices', vertices, 'Faces', faces, 'triangles');
        
                        % Create a triangulation object
                        tri = triangulation(f, v);
        
                        % Extract color data
                        color = c;
        
                        % Exit the loop after processing the triangle list
                        break
                end
                triObj = obj.concatenateTriangulations(triObj, tri);
                faceColor = [faceColor color];
            end
            color = faceColor;
            tri = triObj;
        end


       function [triangulationObj, color] = getTriCubeMarker(obj, Marker)
            % This function returns the triangulation and color for a Cube Marker
            % Main Idea: Create a unit cube centered at origin and
            % transform it.
        
            % Define the vertices of the unit cube centered at the origin
            vertices = [
                -0.5, -0.5, -0.5;
                 0.5, -0.5, -0.5;
                -0.5,  0.5, -0.5;
                 0.5,  0.5, -0.5;
                -0.5, -0.5,  0.5;
                 0.5, -0.5,  0.5;
                -0.5,  0.5,  0.5;
                 0.5,  0.5,  0.5;
            ];
            
            % Define the faces for the unit cube
            faces = [
                    1, 2, 3; 2, 4, 3; % Bottom face
                    5, 6, 7; 6, 8, 7; % Top face
                    1, 2, 5; 2, 6, 5; % Front face
                    3, 4, 7; 4, 8, 7; % Back face
                    1, 3, 5; 3, 7, 5; % Left face
                    2, 4, 6; 4, 8, 6; % Right face
                ];
        
            % Scale the vertices using scale values
            scaledVertices = vertices .* [getNestedField(Marker, obj.FieldMap.scale.x), getNestedField(Marker, obj.FieldMap.scale.y), getNestedField(Marker, obj.FieldMap.scale.z)];
        
            % Transform Vertices to desired Pose
            transformedVertices = transformVerticesUsingPose(obj, Marker, scaledVertices);
        
            % Create a triangulation object
            triangulationObj = triangulation(faces, transformedVertices);
        
            % Return the color
            color = [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)];
       end

       function [triangulationObj, color] = getTriSphereMarker(obj, Marker)
            % This function returns the triangulation and color for a Sphere Marker
            % Main Idea: Create a unit sphere and transform it
        
            % Construct an ellipsoid at 0,0,0 using the "Scale" property
            [X, Y, Z] = ellipsoid(0, 0, 0, getNestedField(Marker, obj.FieldMap.scale.x)/2, getNestedField(Marker, obj.FieldMap.scale.y)/2, getNestedField(Marker, obj.FieldMap.scale.z)/2);
        
            points = [X(:), Y(:), Z(:)];
            
            % Transform Vertices to desired Pose
            transformedVertices = transformVerticesUsingPose(obj, Marker, points);
            
            % Reshape the rotated points back to the original grid shape
            X = reshape(transformedVertices(:, 1), size(X));
            Y = reshape(transformedVertices(:, 2), size(Y));
            Z = reshape(transformedVertices(:, 3), size(Z));
        
            % Create a triangulation object
            % Convert the grid to faces and vertices
            [faces, vertices] = surf2patch(X, Y, Z, 'triangles');
            triangulationObj = triangulation(faces, vertices);
        
            % Return the color
            color = [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b), getNestedField(Marker, obj.FieldMap.color.a)];
       end

       

       function [triangulationObj, color] = getTriCylinderMarker(obj, Marker)
            % This function returns the triangulation and color for a Cylinder Marker
            % Main Idea: Generate points on a cylinder. Generate the top
            % and bottom faces.
        
            % Generate points on the cylinder surface
            theta = linspace(0, 2*pi, obj.NoOfFaces);
            z = linspace(-getNestedField(Marker, obj.FieldMap.scale.z)/2, getNestedField(Marker, obj.FieldMap.scale.z)/2, 2); % Only two z levels for top and bottom
            [thetaGrid, zGrid] = meshgrid(theta, z);
            x = getNestedField(Marker, obj.FieldMap.scale.x) * cos(thetaGrid);
            y = getNestedField(Marker, obj.FieldMap.scale.y) * sin(thetaGrid);
            
            % Transform vertices to desired pose   
            transformedVertices = transformVerticesUsingPose(obj, Marker, [x(:), y(:), zGrid(:)]);
        
            % Extract the rotated and translated x, y, z coordinates
            x = reshape(transformedVertices(:, 1), size(thetaGrid));
            y = reshape(transformedVertices(:, 2), size(thetaGrid));
            z = reshape(transformedVertices(:, 3), size(thetaGrid));
            
            % Convert the surface grid to faces and vertices
            [faces, vertices] = surf2patch(x, y, z, 'triangles');
        
            % Add the bottom face
            bottomCenter = mean(transformedVertices(1:obj.NoOfFaces, :), 1);
            vertices = [vertices; bottomCenter];
            bottomFaceIndices = [1:obj.NoOfFaces, 1];
            bottomFaces = [bottomFaceIndices(1:end-1), bottomFaceIndices(2:end), repmat(size(vertices, 1), obj.NoOfFaces, 1)];
            faces = [faces; bottomFaces];
        
            % Add the top face
            topCenter = mean(transformedVertices(end-obj.NoOfFaces+1:end, :), 1);
            vertices = [vertices; topCenter];
            topFaceIndices = [size(vertices, 1) - 1 - obj.NoOfFaces + 1 : size(vertices, 1) - 1, size(vertices, 1) - 1 - obj.NoOfFaces + 1];
            topFaces = [topFaceIndices(1:end-1), topFaceIndices(2:end), repmat(size(vertices, 1), obj.NoOfFaces, 1)];
            faces = [faces; topFaces];
        
            % Create a triangulation object
            triangulationObj = triangulation(faces, vertices);
        
            % Return the color
            color = [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b), getNestedField(Marker, obj.FieldMap.color.a)];
       end

       function [vertices, colors] = getTriLineStripMarker(obj, Marker)
            % This function returns the vertices and colors for a Line Strip marker
        
            % Extract the line points
            xData = [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.x)];
            yData = [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.y)];
            zData = [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.z)];
        
            % Append NaN to separate line segments
            xData = [xData, NaN];
            yData = [yData, NaN];
            zData = [zData, NaN];
        
            % Create vertices matrix with NaN separator
            vertices = [xData', yData', zData'];
        
            % Extract the colors
            rData = [Marker.Colors.R];
            gData = [Marker.Colors.G];
            bData = [Marker.Colors.B];
            aData = [Marker.Colors(1).A];
        
            % Append NaN to separate color segments
            rData = [rData, NaN];
            gData = [gData, NaN];
            bData = [bData, NaN];
            aData = [aData, NaN];
        
            % Create color matrix with NaN separator
            colors = [rData', gData', bData', aData'];
       end

       function [vertices, colors] = getTriLineListMarker(obj, Marker)
            % This function returns the vertices and colors for a Line List Marker
        
            % Reshape X, Y, Z, and Color(RGBA) to create a 2xN matrix
            % where N = Number of lines
            X = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.x)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            Y = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.y)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            Z = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.z)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            
            R = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.r)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            G = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.g)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            B = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.b)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
            A = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.a)], [2, size(Marker.(obj.FieldMap.Points), 2)/2]);
        
            % Initialize empty arrays for vertices and colors with NaN separators
            vertices = [];
            colors = [];
            
            % Iterate through the lines and collect vertices and colors
            for i = 1:size(X, 2)
                % Append the current line's vertices and a NaN separator
                vertices = [vertices; X(:, i)', NaN; Y(:, i)', NaN; Z(:, i)', NaN];
                
                % Append the current line's colors and a NaN separator
                colors = [colors; R(:, i)', NaN; G(:, i)', NaN; B(:, i)', NaN; A(:, i)', NaN];
            end
        
            % Reshape the vertices and colors into 3-column and 4-column matrices, respectively
            vertices = reshape(vertices, [], 3);
            colors = reshape(colors, [], 4);
        
       end

       function [triangulationObj, color] = getTriMeshMarker(obj, Marker)
            % This function returns the triangulation and color for an STL Mesh Marker
        
            % Check if the path for Mesh file is provided
            if isfield(Marker, "MeshResource")
                % Check if the file exists at the specified path
                if isfile(Marker.MeshResource)
                    % Read the STL file using a custom STLread function
                    [faces, vertices] = ros.internal.utils.STLread(Marker.MeshResource);
        
                    % Scale the vertices using scale values
                    scaledVertices = vertices .* [getNestedField(Marker, obj.FieldMap.scale.x), getNestedField(Marker, obj.FieldMap.scale.y), getNestedField(Marker, obj.FieldMap.scale.z)];
                    
                    % Transform Vertices to desired Pose
                    transformedVertices = transformVerticesUsingPose(obj, Marker, scaledVertices);
                    
                    % Create a triangulation object
                    triangulationObj = triangulation(faces, transformedVertices);
        
                    % Return the color
                    color = [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b), getNestedField(Marker, obj.FieldMap.color.a)];
                else
                    % TODO Author error
                    error(message("ros:visualizationapp:view:ThreeDSTLFileNotFound", Marker.MeshResource));
                end
            else
                % TODO Author error
                error(message("ros:visualizationapp:view:ThreeDSTLFileNotFound:ThreeDMeshResourceNotSet"));
            end
        end



        %% Helper methods for plot markers start
        function Marker = transformPointsToGlobalFrame(obj, Marker)
            % This function transforms the "Points" property to global
            % frame using the "Pose" property

            % Calculate the tf
            tf = se3([ getNestedField(Marker, obj.FieldMap.pose.position.x),  getNestedField(Marker, obj.FieldMap.pose.position.y),  getNestedField(Marker, obj.FieldMap.pose.position.z), getNestedField(Marker, obj.FieldMap.pose.orientation.w), getNestedField(Marker, obj.FieldMap.pose.orientation.x), getNestedField(Marker, obj.FieldMap.pose.orientation.y), getNestedField(Marker, obj.FieldMap.pose.orientation.z)],"xyzquat");
            
            % Transform the points
            transformedPoints = transform(tf, [[getNestedFieldArray(Marker, obj.FieldMap.points.x)]', [getNestedFieldArray(Marker, obj.FieldMap.points.y)]', [getNestedFieldArray(Marker, obj.FieldMap.points.z)]']);
            
            % Assign the transformed points to the Marker
            Marker.Points = struct("MessageType", num2cell(repmat("geometry_msgs/Point",1,size(Marker.Points,2))), ...
                                   "X", num2cell(transformedPoints(:,1)'), ...
                                   "Y", num2cell(transformedPoints(:,2)'), ...
                                   "Z", num2cell(transformedPoints(:,3)'));
        end

        function transformedVertices = transformVerticesUsingPose(obj, Marker, Vertices)
            % This function transforms vertices using the "Pose" property

            % Rotate the vertices using quaternion rotation
            if getNestedField(Marker, obj.FieldMap.pose.orientation.w) == 0 && getNestedField(Marker, obj.FieldMap.pose.orientation.x) == 0 && getNestedField(Marker, obj.FieldMap.pose.orientation.y) == 0 && getNestedField(Marker, obj.FieldMap.pose.orientation.z) == 0 
                Marker = setNestedField(Marker, obj.FieldMap.pose.orientation.w, 1)    ;                
            end
            rotatedVertices = rotatepoint(quaternion(getNestedField(Marker, obj.FieldMap.pose.orientation.w), getNestedField(Marker, obj.FieldMap.pose.orientation.x), getNestedField(Marker, obj.FieldMap.pose.orientation.y), getNestedField(Marker, obj.FieldMap.pose.orientation.z)), Vertices);
            
            % Translate the vertices to the origin
            transformedVertices = rotatedVertices + [ getNestedField(Marker, obj.FieldMap.pose.position.x),  getNestedField(Marker, obj.FieldMap.pose.position.y),  getNestedField(Marker, obj.FieldMap.pose.position.z)];
        end

        function [X, Y, Z] = transformPointsUsingDirectionVector(obj, X, Y, Z, startPoint, directionVector)
            % Transform list of X,Y,Z given the starting point and the
            % normalized direction vector

            % Create a transformation matrix
            tranformMatrix = eye(4);
            tranformMatrix(1:3, 4) = startPoint';
            
            % Find the rotation matrix using the directionVector
            rotationAxis = cross([0, 0, 1], directionVector);
            rotationAngle = acos(dot([0, 0, 1], directionVector));
            rotationMatrix = axang2rotm([rotationAxis, rotationAngle]);
            
            % Assign the rotation matrix to the transformation matrix 
            tranformMatrix(1:3,1:3) = rotationMatrix;

            % Create Vertices matrix to calculate the transformed vertices
            vertices = [X(:)'; Y(:)'; Z(:)'; ones(1, numel(X))];
            transformedVertices = tranformMatrix * vertices;
            
            % Reshape to obtain the transformed X, Y, Z
            X = reshape(transformedVertices(1, :), size(X));
            Y = reshape(transformedVertices(2, :), size(Y));
            Z = reshape(transformedVertices(3, :), size(Z));
        end

        function combinedTriangulation = concatenateTriangulations(~, tri1, tri2)
            if isempty(tri1)
                combinedTriangulation = tri2;
                return;
            elseif isempty(tri2)
                combinedTriangulation =  tri1;
                return;
            end

            % Extract vertices and connectivity list from the first triangulation
            vertices1 = tri1.Points;
            connectivityList1 = tri1.ConnectivityList;
        
            % Extract vertices and connectivity list from the second triangulation
            vertices2 = tri2.Points;
            connectivityList2 = tri2.ConnectivityList;
        
            % Adjust the indices in the connectivity list of the second triangulation
            adjustedConnectivityList2 = connectivityList2 + size(vertices1, 1);
        
            % Concatenate vertices and connectivity lists
            combinedVertices = [vertices1; vertices2];
            combinedConnectivityList = [connectivityList1; adjustedConnectivityList2];
        
            % Create the combined triangulation object
            combinedTriangulation = triangulation(combinedConnectivityList, combinedVertices);
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

function value = getNestedField(data, fieldPath)
    parts = strsplit(fieldPath, '.'); % Split the path into parts
    for i = 1:length(parts)
        if isfield(data, parts{i})
            data = data.(parts{i}); % Access the next nested field
            % Check if data is an array of structs and handle appropriately
            if i < length(parts) && isstruct(data) && isempty(data)
                % If data is an empty struct array and not the last part of the path, return an empty array
                value = [];
                return;
            end
        else
            error(message('ros:visualizationapp:view:ThreeDFieldNotPresent', parts{i}));
        end
    end
    value = data;
end

function values = getNestedFieldArray(data, fieldPath)
    % Split the fieldPath to separate the struct array name and the field name
    parts = strsplit(fieldPath, '.');
    arrayName = parts{1};
    fieldName = parts{2};
    
    % Check if the specified arrayName exists and is an array of structs
    if isfield(data, arrayName) && isstruct(data.(arrayName))
        % Extract the array of structs
        structArray = data.(arrayName);
        % Preallocate for efficiency based on the length of structArray
        values = zeros(1, length(structArray));
        % Loop through each struct in the array to extract the fieldName value
        for i = 1:length(structArray)
            if isfield(structArray(i), fieldName)
                values(i) = structArray(i).(fieldName);
            else
                error(message('ros:visualizationapp:view:ThreeDFieldNotInArrayPresent', fieldName, num2str(i)));
            end
        end
    else
        error(message('ros:visualizationapp:view:ThreeDFieldNorArrayPresent', arrayName));
    end
end

function nestedData = setNestedField(data, fieldPath, value)
    % Split the path into parts
    parts = strsplit(fieldPath, '.');
    nFields = length(parts);
    % Allocate an array to hold layers of the data structure
    dataLayers = cell(1, nFields);
    % Extract the layers
    dataLayers{1} = data;
    for idx_field = 1:nFields - 1
        if isfield(dataLayers{idx_field}, parts{idx_field})
            dataLayers{idx_field + 1} = dataLayers{idx_field}.(parts{idx_field});
        else
            error(message('ros:visualizationapp:view:ThreeDFieldNotPresent', parts{idx_field}));
        end
    end
    % Assign the value to the lowest part of the nest
    if isfield(dataLayers{end}, parts{end})
       dataLayers{end}.(parts{end}) = value;
    else
        error(message('ros:visualizationapp:view:ThreeDFieldNotPresent', parts{end}));
    end

    % Assign up the nested structure
    for idx_field = (nFields):-1:2
        % We want to reverse the layers 
        dataLayers{idx_field - 1}.(parts{idx_field - 1}) = dataLayers{idx_field};
    end
    % Finally output the final modified data structure
    nestedData = dataLayers{1};
end

% LocalWords:  rosmessage DUnsupported DUnkown reinit RGBA Lread DSTL DMesh xyzquat DField
% LocalWords:  visualizer
