classdef MarkerVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleMarker'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'visualization_msgs/MarkerArray','visualization_msgs/Marker'}

        GraphicHandleIdx = 1;
    end

    properties (SetAccess = protected)
        DataRangeUpdated = false
        PendingData = {}

        % Creating a temporary marker which can be utilized to plot list
        % based marker such as Point, Sphere, Cube list markers
        tempMarker = rosmessage('visualization_msgs/Marker');

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

        function updateData(obj, dataSourcePath, dataContainer, clearAxes)
            
            % Obtain the message data
            [~, fieldPath] = splitTopicFieldPath(dataSourcePath);
            if isempty(fieldPath)
                msg = dataContainer.Message;
            else
                msg = getfield(dataContainer.Message, fieldPath{:});
            end

            fieldMap = dataContainer.FieldMap;
            obj.FieldMap = fieldMap;

            if msg.(fieldMap.messageType) == "visualization_msgs/MarkerArray" ...
                    && isempty(msg.(fieldMap.markers))
                return
            end
            % Reset the app data for text and points for every
            % time stamp
            % 
            setappdata(obj.AxesHandle, "textData", []);
            setappdata(obj.AxesHandle, "pointData", []);
            
            % Clear the figure at start of every time step
            if clearAxes
                cla(obj.AxesHandle)
            end
            

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
            
            % Iterate through the Marker Array
            for i = 1:marker_array_size
                if marker_array_size > 1
                    % If handling a MarkerArray, dynamically access each Marker
                    Marker = msg.(fieldMap.markers)(i);
                else
                    % For a single Marker, the Marker itself is already defined
                    Marker = msg.markers(i);
                end                
                % Plot the Marker based on Marker Type
                switch Marker.(fieldMap.type)
                    case 0 % defined as per message Definition for visualization_msgs/Marker Message
                        % 0 is ARROW
                        plotArrowMarker(obj, Marker)
                    case 1
                        % 1 is CUBE
                        plotCubeMarker(obj, Marker)
                    case 2
                        % 2 is SPHERE
                        plotSphereMarker(obj, Marker)
                    case 3
                        % 3 CYLINDER
                        plotCylinderMarker(obj, Marker)
                    case {4, 5, 6, 7, 8, 11}
                        % uint8 LINE_STRIP=4
                        % uint8 LINE_LIST=5
                        % uint8 CUBE_LIST=6
                        % uint8 SPHERE_LIST=7
                        % uint8 POINTS=8
                        % uint8 TRIANGLE_LIST=11

                        plotList(obj, Marker, Marker.(fieldMap.type))
                    case 9
                        % uint8 TEXT_VIEW_FACING=9

                        plotTextMarker(obj, Marker)
                    case 10
                        % uint8 MESH_RESOURCE=10
                        plotMeshMarker(obj, Marker)

                    otherwise
                        % TO DO - Throw an error instead
                        disp("Not Supported")
                end
            end
            % Set the Axis Limits when plotting text data as the axes does
            % not automatically adjust based on axis limits
            setAxisLimits(obj)

            % Adjust the Camera lighting
            camlight(obj.AxesHandle);
        end
      
        function viewToggle(obj)
            % This function helps in toggling between 3d and 2d view

            % Obtain the camera angle
            [az, el] = view(obj.AxesHandle);
            if el ~= 90
                view(obj.AxesHandle, [0 90])
            else
                view(obj.AxesHandle, obj.CameraAngle)
            end
        end

        function plotted = measureDistance(obj, dataTips)
            % This function plots the Distance Marker between selected
            % data points

            % Check if the plot already exists
             if isempty(obj.measureDistanceHandle)
                 % Obtain the locations
                 locations = [dataTips(:).Position];
                 X = locations(1: 3: end);
                 Y = locations(2: 3: end);
                 Z = locations(3: 3: end);
                 coordinates = [X' Y' Z'];

                 % Find the distance between them
                 distances = sqrt(sum(diff(coordinates).^2, 2));

                 % Calculate the Mid Points to plot the Text
                 midpoints = (coordinates(1: end-1, :) + coordinates(2: end, :))/ 2;
                
                 % Plot the Line and Distance on to the plot
                 obj.measureDistanceHandle = plot3(obj.AxesHandle, ...
                                                    X, Y, Z, ...
                                                    'Color', [0.75, 0 , 0],...
                                                    'LineWidth', 1);
                 obj.measureDistanceTextHandle = text(obj.AxesHandle, ...
                                                     midpoints(:,1), midpoints(:, 2), midpoints(:, 3), ...
                                                     cellstr(string(round(distances, 2))), ...
                                                     "FontSize", 12, ...
                                                     "HorizontalAlignment", "center", ...
                                                     "VerticalAlignment", "middle", ...
                                                     "Color", [0.75,0 , 0], ...
                                                     "BackgroundColor", 'w', ...
                                                     "Clipping", "on");
                % Return plotted = True, this will help when user deletes 
                % all the data tips and wants to clear the distance 
                % measurement handles. 
                plotted = true;
             else
                 % Delete all the handles related to Distance Measurement
                 delete(obj.measureDistanceHandle)
                 delete(obj.measureDistanceTextHandle)
                 obj.measureDistanceHandle = [];
                 obj.measureDistanceTextHandle = [];
                 plotted = false;
             end
        end        
    end
    
    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and plot
            % Data source selection
            obj.DataSourcesID = obj.getNewID;

            % Axes graphics object
            obj.AxesHandle = uiaxes(obj.GridHandle);
            obj.AxesHandle.Layout.Row = 2;
            obj.AxesHandle.Layout.Column = 1;
            obj.defaultAxesSetting();

            % set 3D view
            view(obj.AxesHandle, obj.CameraAngle);

            % add X and Y LimitsChange callback to resize the marker
            addlistener(obj.AxesHandle, "XLim", "PostSet", @(~, ~)obj.updatePointAndTextMarker());
            addlistener(obj.AxesHandle, "YLim", "PostSet", @(~, ~)obj.updatePointAndTextMarker());
            addlistener(obj.AxesHandle, "ZLim", "PostSet", @(~, ~)obj.updatePointAndTextMarker());
            addlistener(obj.AxesHandle, "SizeChanged", @(~, ~)obj.updatePointAndTextMarker());
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
            % Clear all drawn plot
            cla(obj.AxesHandle);
            obj.defaultAxesSetting();

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            else
                obj.DataRangeUpdated = false;
            end
            view(obj.AxesHandle, obj.CameraAngle);
        end
        
        %% plot markers code start
        function plotArrowMarker(obj, Marker)
            % This function plots an arrow Marker which is a combination of
            % a cone and a cylinder

            % There are two possible ways to plot an arrow which is based
            % on the users inputs
            % 1. User provides the property "Points", this specifies the
            %   start and end point of the arrow. The "Scale.X" is cylinder
            %   radius, "Scale.Y" is arrow radius and "Scale.Z" is the 
            %   height of arrow head
            % 2. In the "Points" property is empty then the "Pose" acts as
            %   the starting point and "Scale.X" is total arrow height,
            %   "Scale.Y" is radius of arrow head and "Scale.Z" is height
            %   of arrow head.

            if ~isempty(Marker.(obj.FieldMap.Points))
                % Case 1: The "Points" property is provided
                % Define Arrow Properties
                % update marker points field to global frame (we use when there is
                % POINTS field is provided)
                Marker = transformPointsToGlobalFrame(obj, Marker);
                startPoint = [Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.x), Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.y), Marker.(obj.FieldMap.Points)(1).(obj.FieldMap.z)];
                endPoint = [Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.x), Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.y), Marker.(obj.FieldMap.Points)(2).(obj.FieldMap.z)];
                totalHeight = sqrt(sum((startPoint-endPoint).^2));
                if getNestedField(Marker, obj.FieldMap.scale.z) == 0 % when z == 0 we are assuming some ratio to come up with a suitable height
                    arrowHeight = 0.25*totalHeight;
                else %  If scale.z is not zero, it specifies the head length.
                    arrowHeight = getNestedField(Marker, obj.FieldMap.scale.z);
                end
                cylinderRadius = getNestedField(Marker, obj.FieldMap.scale.x);
                arrowRadius = getNestedField(Marker, obj.FieldMap.scale.y);
            else
                % Case 2: The "Points" property is not provided
                % Define Arrow Properties
                startPoint = [Marker.(obj.FieldMap.pose.position.x),  getNestedField(Marker, obj.FieldMap.pose.position.y),  getNestedField(Marker, obj.FieldMap.pose.position.z)];
                totalHeight = getNestedField(Marker, obj.FieldMap.scale.x);
                arrowHeight = getNestedField(Marker, obj.FieldMap.scale.z);
                arrowRadius = getNestedField(Marker, obj.FieldMap.scale.y);
                cylinderRadius = 0.5*arrowRadius;
                endPoint = startPoint + [totalHeight, 0, 0];
            end
            
            % Calculate the normalized direction vector
            directionVector = (endPoint - startPoint) / norm(endPoint - startPoint);
            
            % Define Arrow properties 
            cylinderHeight = totalHeight - arrowHeight;
            coneStartPoint = startPoint + cylinderHeight * directionVector;
            cylinderStartPoint = startPoint;

            % Define Cone and Cylinder Vertices
            % 
            [coneX, coneY, coneZ] = cylinder([arrowRadius, 0], obj.NoOfFaces);
            [cylinderX, cylinderY, cylinderZ] = cylinder(cylinderRadius,obj.NoOfFaces);
            
            % Transform Vertices to required height
            coneZ = coneZ * arrowHeight;
            cylinderZ = cylinderZ * cylinderHeight;
            
            % Transform Vertices utilizing the direction vector
            [coneX, coneY, coneZ] = transformPointsUsingDirectionVector(obj, coneX, coneY, coneZ, coneStartPoint, directionVector);
            [cylinderX, cylinderY, cylinderZ] = transformPointsUsingDirectionVector(obj, cylinderX, cylinderY, cylinderZ, cylinderStartPoint, directionVector);
            
            % Plot the coneSurface
            coneSurface = surf(obj.AxesHandle, ...
                coneX, coneY, coneZ, ...
                "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                "EdgeColor", "none", ...
                "FaceLighting", "gouraud", ...
                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a)); 
            
            % Plot the cylinderSurface
            cylinderSurface =surf(obj.AxesHandle, ...
                   cylinderX, cylinderY, cylinderZ, ...
                    "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                    "EdgeColor", "none", ...
                    "FaceLighting", "gouraud", ...
                    "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));
            
            % Plot the cylinder base
            cylinderBase = fill3(obj.AxesHandle, ...
                                cylinderX(1,:), cylinderY(1,:), cylinderZ(1,:), ...
                                [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));
            
            % Plot the cone base
            coneBase = fill3(obj.AxesHandle, ...
                            coneX(1,:), coneY(1,:), coneZ(1,:), ...
                            [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                            "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));

            % Set the material properties
            material(coneSurface, "dull");
            material(cylinderSurface, "dull");
            material(cylinderBase, "dull");
            material(coneBase, "dull");

        end

        function plotCubeMarker(obj, Marker)
            % This function plots a Cube Marker
            vertices = [
                       -1/2, -1/2, -1/2;       % Vertex 1
                        1/2, -1/2, -1/2;       % Vertex 2
                        1/2, 1/2, -1/2;        % Vertex 3
                       -1/2, 1/2, -1/2;        % Vertex 4
                       -1/2, -1/2, 1/2;        % Vertex 5
                        1/2, -1/2, 1/2;        % Vertex 6
                        1/2, 1/2, 1/2;         % Vertex 7
                       -1/2, 1/2, 1/2];        % Vertex 8
            
            faces = [
                    1 2 3 4;   % Face 1
                    2 6 7 3;   % Face 2
                    4 3 7 8;   % Face 3
                    1 5 8 4;   % Face 4
                    1 2 6 5;   % Face 5
                    5 6 7 8 ]; % Face 6

            % Scale the vertices using scale values
            scaledVertices = vertices .* [getNestedField(Marker, obj.FieldMap.scale.x), getNestedField(Marker, obj.FieldMap.scale.y), getNestedField(Marker, obj.FieldMap.scale.z)];
            
            % Transform Vertices to desired Pose
            transformedVertices = transformVerticesUsingPose(obj, Marker, scaledVertices);
            
            % Plot the cuboid using patch function
            cubeSurface = patch(obj.AxesHandle, ...
                                "Vertices", transformedVertices, ...
                                "Faces", faces, ...
                                "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a)); 

            % set the cube material 
            material(cubeSurface, "dull")
        end
        
        function plotSphereMarker(obj, Marker)
            % This function plots a Sphere Marker

            % Construct an ellipsoid at 0,0,0 using the "Scale" property
            [X, Y, Z] = ellipsoid(0, 0, 0, getNestedField(Marker, obj.FieldMap.scale.x)/2, getNestedField(Marker, obj.FieldMap.scale.y)/2, getNestedField(Marker, obj.FieldMap.scale.z)/2);

            points = [X(:), Y(:), Z(:)];
            
            % Transform Vertices to desired Pose
            transformedVertices = transformVerticesUsingPose(obj, Marker, points);
            
            % Reshape the rotated points back to the original grid shape
            X = reshape(transformedVertices(:, 1), size(X));
            Y = reshape(transformedVertices(:, 2), size(Y));
            Z = reshape(transformedVertices(:, 3), size(Z));
            
            % Plot the ellipsoid
            sphereSurface = surface(obj.AxesHandle, ...
                                    X, Y, Z, ...
                                    "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                    "EdgeColor", "none", ...
                                    "FaceLighting", "gouraud", ...
                                    "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));

            % Set the sphere material
            material(sphereSurface, "dull")
        end
        
        function plotCylinderMarker(obj, Marker)

            % Generate points on the cylinder surface
            theta = linspace(0, 2*pi, obj.NoOfFaces);
            z = linspace(-getNestedField(Marker, obj.FieldMap.scale.z)/2, getNestedField(Marker, obj.FieldMap.scale.z)/2, obj.NoOfFaces);
            [thetaGrid, zGrid] = meshgrid(theta, z);
            x = getNestedField(Marker, obj.FieldMap.scale.x) * cos(thetaGrid);
            y = getNestedField(Marker, obj.FieldMap.scale.y) * sin(thetaGrid);
            
            % Transform Vertices to desired Pose   
            transformedVertices = transformVerticesUsingPose(obj, Marker, [x(:), y(:), zGrid(:)]);

            % Extract the rotated and translated x, y, z coordinates
            x = reshape(transformedVertices(:, 1), size(thetaGrid));
            y = reshape(transformedVertices(:, 2), size(thetaGrid));
            z = reshape(transformedVertices(:, 3), size(thetaGrid));
            
            % Plot the elliptic cylinder
            cylinderSurface = surface(obj.AxesHandle, x, y, z, ...
                                    "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                    "EdgeColor","none", ...
                                    "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));
            cylinderBase = fill3(obj.AxesHandle, ...
                                x(1,:), y(1,:), z(1,:), ...
                                [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "EdgeColor","none", ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));
            cylinderTop = fill3(obj.AxesHandle, ...
                                x(end,:), y(end,:), z(end,:), ...
                                [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "EdgeColor","none", ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));

            % Set the material properties
            material(cylinderSurface,"dull");
            material(cylinderBase,"dull");
            material(cylinderTop,"dull");
        end
        
        function plotLineStripMarker(obj, Marker)
            % This function plots a Line Strip marker

            % Utilizing patch to plot the line in order to incorporate
            % gradient color using "FaceVertexCData"
            patch(obj.AxesHandle, ...
                  "XData", [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.x) nan], ...
                  "YData", [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.y) nan], ...
                  "ZData", [Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.z) nan], ...
                  "EdgeColor", "interp", ...
                  "FaceVertexCData", [[Marker.Colors.R nan]', [Marker.Colors.G nan]', [Marker.Colors.B nan]'], ...
                  "EdgeAlpha", Marker.Colors(1).A, ...
                  "LineWidth", 0.5 * getNestedField(Marker, obj.FieldMap.scale.x))
        end
        
        function plotLineListMarker(obj, Marker)
            % This function plots a Line List Marker
            
            % Reshaping X, Y, Z, and Color(RGBA) to create a 2xN matrix
            % where N = No of lines
            X = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.x)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            Y = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.y)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            Z = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.z)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
           
            R = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.r)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            G = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.g)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            B = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.b)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            A = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.a)],[2, size(Marker.(obj.FieldMap.Points),2)/2]);
            
            % Iterate through the lines and plot them.
            % Note: Loop is used to incorporate gradient colored lines
            for i = 1: size(X, 2)
                patch(obj.AxesHandle, ...
                      "XData", [X(:,i)' nan], ...
                      "YData", [Y(:,i)' nan], ...
                      "ZData", [Z(:,i)' nan], ...
                      "EdgeColor", "interp", ...
                      "FaceVertexCData", [[R(:,i); nan], [G(:,i); nan], [B(:,i); nan]], ...
                      "EdgeAlpha", A(1,i), ...
                      "LineWidth", 0.5* getNestedField(Marker, obj.FieldMap.scale.x))
            end
        end

        function plotMeshMarker(obj, Marker)
            % This function is used to plot STL files

            % Check if the path for Mesh file is provided
            if isfield(Marker, "MeshResource")
                % Check if the file exist at the specified path
                if isfile(Marker.MeshResource)
                    % Read the STL file using a custom STLread function
                    [faces, vertices] = ros.internal.utils.STLread(Marker.MeshResource);

                    % Scale the vertices using scale values
                    scaledVertices = vertices .* [getNestedField(Marker, obj.FieldMap.scale.x), getNestedField(Marker, obj.FieldMap.scale.y), getNestedField(Marker, obj.FieldMap.scale.z)];
                    
                    % Transform Vertices to desired Pose
                    transformedVertices = transformVerticesUsingPose(obj, Marker, scaledVertices);
                    
                    % Plot the STL file using Patch
                    stlSurface =patch(obj.AxesHandle, ...
                                "Vertices", transformedVertices, ...
                                "Faces", faces, ...
                                "FaceColor", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "EdgeColor",       "none",        ...
                                "FaceLighting",    "gouraud",     ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));

                    % Set the material properties
                    material(stlSurface,"dull");
                else
                    disp("ERROR: File does not exist at specified path. Please provide the absolute path to STL file")
                end
            else
                disp("ERROR: No path exists in mesh_resource field of Marker. Please provide the absolute path to STL file")
            end
        end

        function plotPointMarker(obj, Marker)
            % This function plots the Point Marker in form of a rectangle 

            % Calculate the corners of the rectangle
            [XData, YData, ZData] = generatePointCorners(obj, Marker);

            % Plot the point marker
            pointHandle = fill3(obj.AxesHandle, ...
                                XData, ...
                                YData, ...
                                ZData, ...
                                [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "EdgeColor","none", ...
                                "FaceLighting","gouraud", ...
                                "FaceAlpha", getNestedField(Marker, obj.FieldMap.color.a));
            
            % Set the material properties
            material(pointHandle, "dull");
            
            % Obtain the point data if it exist or else create it
            pointData = getappdata(obj.AxesHandle, "pointData");
            
            % Note: Below fields help later in the "updatePointAndTextMarker" callback

            % Check if the "handles" field exists and append the new handle
            if isfield(pointData, "handles")
                pointData.handles = [pointData.handles(:); pointHandle];
            else
                pointData.handles = pointHandle;
            end

            % Check if the "Marker" field exists and append the new Marker
            if isfield(pointData, "Marker")
                pointData.Marker = [pointData.Marker(:); Marker];
            else
                pointData.Marker = Marker;
            end
            
            % Update the "pointData" with new data
            setappdata(obj.AxesHandle, "pointData", pointData);
        end

        function plotList(obj, Marker, type)
            % Transform the points to global frame using the "Pose" property
            Marker = transformPointsToGlobalFrame(obj, Marker);

            % Check if the Marker has the "Colors" property, if not then
            % populate it with "Color" data. This helps in error handling 
            % as all list markers expect to have Color data for each point
            if isempty(Marker.(obj.FieldMap.Colors)) 
                Marker = setNestedField(Marker, obj.FieldMap.Colors, repmat(struct("MessageType", "std_msgs/ColorRGBA", ...
                                              string((obj.FieldMap.r)), getNestedField(Marker, obj.FieldMap.color.r), ...
                                              string((obj.FieldMap.g)), getNestedField(Marker, obj.FieldMap.color.g), ...
                                              string((obj.FieldMap.b)), getNestedField(Marker, obj.FieldMap.color.b), ...
                                              string((obj.FieldMap.a)), getNestedField(Marker, obj.FieldMap.color.a)), ...
                                              size(Marker.(obj.FieldMap.Points)))); 
            end

            % Iterate through the Points and plot the Marker
            for i = 1: size(Marker.(obj.FieldMap.Points), 2)
                % Check Marker Type
                switch type
                    case 4
                        plotLineStripMarker(obj, Marker)
                        break
                    case 5
                        plotLineListMarker(obj, Marker)
                        break
                    case 6
                        % (CUBE_LIST=6)
                        % Create a temporary marker to be plotted
                        updateTempMarker(obj, Marker, i);
                        plotCubeMarker(obj, obj.tempMarker)
                    case 7
                        %SPHERE_LIST=7
                        % Create a temporary marker to be plotted
                        updateTempMarker(obj, Marker, i);
                        plotSphereMarker(obj, obj.tempMarker)
                    case 8
                        %POINTS=8
                        % Create a temporary marker to be plotted
                        updateTempMarker(obj, Marker, i);
                        obj.updateCameraProperties();
                        plotPointMarker(obj, obj.tempMarker)
                    case 11
                        plotTriangleListMarker(obj, Marker)
                        break
                end
            end
        end

        function plotTextMarker(obj, Marker)
            % This function is used to plot text
            textHandle = text(obj.AxesHandle, ...
                                getNestedField(Marker, obj.FieldMap.pose.position.x),  getNestedField(Marker, obj.FieldMap.pose.position.y),  getNestedField(Marker, obj.FieldMap.pose.position.z), ...
                                Marker.(obj.FieldMap.text), ...
                                "FontSize", 12* getNestedField(Marker, obj.FieldMap.scale.z), ...
                                "HorizontalAlignment","center", ...
                                "Color", [getNestedField(Marker, obj.FieldMap.color.r), getNestedField(Marker, obj.FieldMap.color.g), getNestedField(Marker, obj.FieldMap.color.b)], ...
                                "Clipping", "on");

            % Obtain the text data if it exist or else create it
            textData = getappdata(obj.AxesHandle, "textData"); % first time it creates the textData for uiaxes

            % Note: Below fields help later in the "updatePointAndTextMarker" callback
            % Check if the "handles" field exists and append the new handle
            if isfield(textData, "handles")
              textData.handles = [textData.handles(:); textHandle];
            else
              textData.handles = textHandle;
            end

            % Update the "textData" with new data
            setappdata(obj.AxesHandle, "textData", textData);
        end
        
        function plotTriangleListMarker(obj, Marker)
            % This function plots a list of triangles

            % Reshaping X, Y, Z, and Color(RGBA) to create a 3xN matrix
            % where N = No of lines
            X = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.x)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);
            Y = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.y)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);
            Z = reshape([Marker.(obj.FieldMap.Points)(:).(obj.FieldMap.z)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);

            R = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.r)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);
            G = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.g)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);
            B = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.b)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);
            A = reshape([Marker.(obj.FieldMap.Colors)(:).(obj.FieldMap.a)], [3, size(Marker.(obj.FieldMap.Points), 2)/ 3]);

            % Iterate through the lines and plot them.
            % Note: Loop is used to incorporate gradient colored lines           
            for i = 1: size(X, 2)
                patch(obj.AxesHandle, ...
                                      "XData", X(:, i), ...
                                      "YData", Y(:, i), ...
                                      "ZData", Z(:, i), ...
                                      "FaceVertexCData", [R(:, i) G(:, i) B(:, i)], ...
                                      "FaceColor", "interp", ...
                                      "FaceAlpha", A(1, i))
            end
        end    
       % plot markers code end

       %% Helper methods for plot markers start
       function [XData, YData, ZData] = generatePointCorners(obj, Marker)
            % This function is used to generate the corners for a rectangle
            % ensuring the rectangle points the user
            
            % Extract the center of the rectangle using the "Pose" property
            position = [ getNestedField(Marker, obj.FieldMap.pose.position.x),  getNestedField(Marker, obj.FieldMap.pose.position.y),  getNestedField(Marker, obj.FieldMap.pose.position.z)];
            
            % Calculate the corner points using the Camera properties
            corner1 = position + (obj.cameraRight * getNestedField(Marker, obj.FieldMap.scale.x)/2) + (obj.cameraUp * getNestedField(Marker, obj.FieldMap.scale.y)/2);
            corner2 = position - (obj.cameraRight * getNestedField(Marker, obj.FieldMap.scale.x)/2) + (obj.cameraUp * getNestedField(Marker, obj.FieldMap.scale.y)/2);
            corner3 = position - (obj.cameraRight * getNestedField(Marker, obj.FieldMap.scale.x)/2) - (obj.cameraUp * getNestedField(Marker, obj.FieldMap.scale.y)/2);
            corner4 = position + (obj.cameraRight * getNestedField(Marker, obj.FieldMap.scale.x)/2) - (obj.cameraUp * getNestedField(Marker, obj.FieldMap.scale.y)/2);
            
            % Reshaping the data
            XData = [corner1(1), corner2(1), corner3(1), corner4(1)];
            YData = [corner1(2), corner2(2), corner3(2), corner4(2)];
            ZData = [corner1(3), corner2(3), corner3(3), corner4(3)];
        end
        
        function updateCameraProperties(obj)
            % Get the current camera position and rotation
            camPos = get(obj.AxesHandle, "CameraPosition");
            camUp = get(obj.AxesHandle, "CameraUpVector");
            camTarget = get(obj.AxesHandle, "CameraTarget");

            % Calculate the new plane corners based on the camera position and rotation
            camDir = camTarget - camPos;
            camDir = camDir / norm(camDir);
            camRight = cross(camUp, camDir);
            obj.cameraRight = camRight / norm(camRight);
            camUp = cross(camDir, obj.cameraRight);
            obj.cameraUp = camUp / norm(camUp);
        end    

        function updateTempMarker(obj, parentMarker, index)
            % This function is used to update a temporary marker with the
            % points data at a particular index. 
            % Note: Creating this temporary marker helps in re-usability of
            % code when plotting list data such as Cube List, Sphere List
            % and Point list data.
            obj.tempMarker = parentMarker; 
            setNestedField(obj.tempMarker, obj.FieldMap.pose.position.x, parentMarker.(obj.FieldMap.Points)(index).(obj.FieldMap.x))
            setNestedField(obj.tempMarker, obj.FieldMap.pose.position.y, parentMarker.(obj.FieldMap.Points)(index).(obj.FieldMap.y))
            setNestedField(obj.tempMarker, obj.FieldMap.pose.position.z, parentMarker.(obj.FieldMap.Points)(index).(obj.FieldMap.z))
            setNestedField(obj.tempMarker, obj.FieldMap.color.r, parentMarker.(obj.FieldMap.Colors)(index).(obj.FieldMap.r))
            setNestedField(obj.tempMarker, obj.FieldMap.color.g, parentMarker.(obj.FieldMap.Colors)(index).(obj.FieldMap.g))
            setNestedField(obj.tempMarker, obj.FieldMap.color.b, parentMarker.(obj.FieldMap.Colors)(index).(obj.FieldMap.b))
            setNestedField(obj.tempMarker, obj.FieldMap.color.a, parentMarker.(obj.FieldMap.Colors)(index).(obj.FieldMap.a))

            % obj.tempMarker.Pose.Position.X = parentMarker.Points(index).X;
            % obj.tempMarker.Pose.Position.Y = parentMarker.Points(index).Y;
            % obj.tempMarker.Pose.Position.Z = parentMarker.Points(index).Z;
            % obj.tempMarker.Color.R = parentMarker.Colors(index).R;
            % obj.tempMarker.Color.G = parentMarker.Colors(index).G;
            % obj.tempMarker.Color.B = parentMarker.Colors(index).B;
            % obj.tempMarker.Color.A = parentMarker.Colors(index).A;
        end

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

        function setAxisLimits(obj)
            % Obtain the Text Data from the Axes Handle
            textData = getappdata(obj.AxesHandle, "textData");

            % Check if text data exists in the plot
            if ~isempty(textData)
                % Extract all the text positions in the plot
                textPositions = [textData.handles(:).Position];

                % Calculate the min and max in x, y, z
                xMin = min(min(obj.AxesHandle.XLim), min(textPositions(1: 3: end)));
                yMin = min(min(obj.AxesHandle.YLim), min(textPositions(2: 3: end)));
                zMin = min(min(obj.AxesHandle.ZLim), min(textPositions(3: 3: end)));

                xMax = max(max(obj.AxesHandle.XLim), max(textPositions(1: 3: end)));
                yMax = max(max(obj.AxesHandle.YLim), max(textPositions(2: 3: end)));
                zMax = max(max(obj.AxesHandle.ZLim), max(textPositions(3: 3: end)));

                % Add padding to the limits
                xPad = 0.1 * (xMax - xMin);
                yPad = 0.1 * (yMax - yMin);
                zPad = 0.1 * (zMax - zMin);

                obj.AxesHandle.XLim = ([xMin - xPad, xMax + xPad]);
                obj.AxesHandle.YLim = ([yMin - yPad, yMax + yPad]);
                obj.AxesHandle.ZLim = ([zMin - zPad, zMax + zPad]);

                % Iterate through the handles and assign the Font Ratios
                % Note: The below code helps in "updatePointAndTextMarker" callback for
                % resizing the text when the user zooms in or zooms out.
                for i = 1:length(textData.handles)
                    fs = get(textData.handles(i), "FontSize");
                    hFig = get(obj.AxesHandle,"Parent");
                    ratios = fs * diff(get(obj.AxesHandle,"YLim")) / max(get(hFig,"Position") .* [0 0 0 1]);
                    if isfield(textData, "ratios")
                        textData.ratios = [textData.ratios(:); ratios];
                    else
                        textData.ratios = ratios;
                    end
                end

                % Update the "textData" with the field ratios
                setappdata(obj.AxesHandle, "textData", textData);
            end
        end

        function fontSize = getBestFontSize(obj)
            % This function helps in calculating the new Font Size
            hFig = get(obj.AxesHandle, "Parent");
            hFigFactor = max(get(hFig, "Position") .* [0 0 0 1]);
            axHeight = diff(get(obj.AxesHandle, "YLim"));
            
            textData = getappdata(obj.AxesHandle, "textData");
            
            fontSize = round(textData.ratios * hFigFactor / axHeight);
            fontSize = max(fontSize, 3);
        end

        function updatePointAndTextMarker(obj)
            % This function updates the Point and Text Marker when the user
            % zooms/rotates the plot

            % Find and set the Font Size for Text Markers
            textData = getappdata(obj.AxesHandle, "textData");
            if ~isempty(textData) && isfield(textData, "ratios")
                fontSize = getBestFontSize(obj);
                for i = 1:length(textData.handles)
                  set(textData.handles(i), "fontsize", fontSize(i), "visible", "on");
                end
            end

            % Alter the Point Marker based on new Camera Angle
            pointData = getappdata(obj.AxesHandle, "pointData");
            if ~isempty(pointData)
                obj.updateCameraProperties();
                for i = 1:length(pointData.handles)
                    [XData, YData, ZData] = generatePointCorners(obj, pointData.Marker(i));
                    set(pointData.handles(i), "XData", XData, "YData", YData, "ZData", ZData);
                end
            end
        end
        % helper methods for plot marker end

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
            error('Field %s does not exist.', parts{i});
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
                error(['Field ', fieldName, ' does not exist in struct array element ', num2str(i), '.']);
            end
        end
    else
        error([arrayName, ' is not a field or not an array of structs.']);
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
            error(['Field ', parts{idx_field}, ' does not exist.'])
        end
    end
    % Assign the value to the lowest part of the nest
    if isfield(dataLayers{end}, parts{end})
       dataLayers{end}.(parts{end}) = value;
    else
        error(['Field ', parts{end}, ' does not exist.'])
    end

    % Assign up the nested structure
    for idx_field = (nFields):-1:2
        % We want to reverse the layers 
        dataLayers{idx_field - 1}.(parts{idx_field - 1}) = dataLayers{idx_field};
    end
    % Finally output the final modified data structure
    nestedData = dataLayers{1};
end

% LocalWords:  XAxis YAxis ZAxis reinit gouraud RGBA Lread uiaxes xyzquat fontsize
