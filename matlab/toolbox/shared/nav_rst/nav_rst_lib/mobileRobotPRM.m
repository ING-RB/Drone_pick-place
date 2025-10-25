classdef (Sealed) mobileRobotPRM < handle & nav.algs.internal.GridAccess
%mobileRobotPRM Create a probabilistic roadmap path planner
%   The probabilistic roadmap path planner constructs a roadmap without
%   start or goal points. At the query stage, it finds
%   paths between specific, given start and goal points. If there is no
%   connectivity between the start and the goal point, it returns an
%   empty array. The roadmap is not constructed until either the method UPDATE,
%   FINDPATH or SHOW is invoked.
%
%   PLANNER = mobileRobotPRM creates an empty mobileRobotPRM object. A value must be assigned
%   to the Map property before using the object. The input to the Map
%   property is an object of type binaryOccupancyMap.
%
%   PLANNER = mobileRobotPRM(MAP) creates a mobileRobotPRM object with input, MAP,
%   assigned to the property Map. The default number of nodes will be
%   calculated based on the size of the MAP.
%
%   PLANNER = mobileRobotPRM(MAP, NUMNODES) creates a mobileRobotPRM object with MAP
%   assigned to the property Map and NUMNODES assigned to the property
%   NumNodes.
%
%   mobileRobotPRM properties:
%       Map                 - Map representing the workspace
%       NumNodes            - Maximum number of nodes in the roadmap
%       ConnectionDistance  - Maximum distance between two connected nodes
%
%   mobileRobotPRM methods:
%       update    - Create or update the roadmap
%       findpath  - Find a path between start and goal points
%       show      - Show the map, roadmap and path in a figure
%
%   Example:
%
%       % Create an empty probabilistic roadmap
%       planner = mobileRobotPRM
%
%       % Create a binary occupancy grid map
%       map = binaryOccupancyMap(10,10);
%
%       % Assign the map object to the PRM
%       planner.Map = map;
%
%       % Find path between two points
%       waypoints = findpath(planner, [1 3], [8 6])
%
%       % Visualize the roadmap and path in a figure
%       show(planner)
%
%   See also binaryOccupancyMap, controllerPurePursuit

%   Copyright 2014-2019 The MathWorks, Inc.
%
%   References:
%
%   [1] L.E. Kavraki, P. Svestka, J.-C. Latombe, M.H. Overmars,
%       "Probabilistic roadmaps for path planning in high-dimensional
%       configuration spaces," IEEE Transactions on Robotics and
%       Automation, vol. 12, no. 4, pp. 566-580, Aug 1996.
%   [2] P. Corke, Robotics, Vision & Control, Springer 2011.

%   Copyright (C) 1993-2014, by Peter I. Corke
%
%   This file is part of The Robotics Toolbox for Matlab (RTB).
%
%   http://www.petercorke.com
%
%   Peter Corke 8/2009.

%#codegen

    properties (Dependent)
        %Map The map representing the world
        %   The MAP is an object of the type binaryOccupancyMap
        %   or occupancyMap. This property holds a copy of the
        %   Map assigned for constructing the roadmap and returns a copy of
        %   the Map used by the probabilistic roadmap.
        %
        %   Default: Empty binaryOccupancyMap object
        Map

        %NumNodes Maximum number of nodes in the roadmap
        %   The number of nodes in the constructed roadmap will be to equal or
        %   less than the NumNodes value. The chance of finding a path increases
        %   with higher number of nodes. The higher number of nodes also increases
        %   the computation time for the roadmap construction.
        %
        %   Default: 50
        NumNodes
    end

    properties
        %ConnectionDistance Maximum distance between connected nodes
        %   Nodes with distance above the ConnectionDistance will not be
        %   connected in the roadmap.
        %
        %   Default: inf
        ConnectionDistance = inf;
    end

    properties (Access = private)

        %InternalNumNodes Internal property that holds the NumNodes
        InternalNumNodes

    end

    properties (Access = {?mobileRobotPRM, ?matlab.unittest.TestCase})
        %InternalMap Internal property that holds the map object
        InternalMap

        %PathFinder Handle to PathFinder System object
        PathFinder

        %UpdateFlag Internal flag to indicate a property has been modified
        UpdateFlag

        %LastFoundPath Cache to keep the last found path
        LastFoundPath = []

        %RoadmapBuilder Handle to RoadmapBuilder System object
        RoadmapBuilder
    end

    methods
        function obj = mobileRobotPRM(arg1, arg2)
        %mobileRobotPRM Constructor

        % Check number of argument
            narginchk(0,2);
            isMapDefault = false;

            if coder.target('MATLAB')
                % Use empty as default values
                defaultsMap = binaryOccupancyMap.empty(0,1);
            else
                % empty() not supported in code generation
                % Use single grid occupied map
                % This will also throw an error when update() is called
                % The error WILL NOT be 'EmptyMap'
                % The error WILL be 'NoFreeSpace'
                %
                % Code-generation limitation: Due to a required default on
                % mobileRobotPRM, setting Map property on mobileRobotPRM with
                % occupancyMap object after constructor does not
                % work due to type difference. User will be required to put
                % the map in mobileRobotPRM constructor.
                %   Does not work in codegen:
                %       prm = mobileRobotPRM;
                %       prm.Map = occupancyMap(5);
                %   Works in codegen:
                %       prm = mobileRobotPRM(occupancyMap(5));
                defaultsMap = binaryOccupancyMap(1);
                isMapDefault = true;
            end
            defaultsNumNodes = 50;

            % Parse optional inputs
            % Using nargin to throw better errors
            if nargin == 0
                map = defaultsMap;
                numNodes = defaultsNumNodes;
            elseif nargin == 1
                validateattributes(arg1,...
                                   {'binaryOccupancyMap', ...
                                    'occupancyMap'}, {'nonempty', 'scalar'}, 'mobileRobotPRM', 'Map', 1);
                map = arg1;
                numNodes = defaultsNumNodes;
                isMapDefault = false;
            else
                % Already verified with narginchk that nargin is >= 0 and <= 2,
                % so this else case covers 2 input arguments
                if ischar(arg1) || isstring(arg1)
                    name = validatestring(arg1, {'Map','NumNodes'}, 'mobileRobotPRM', 'Name', 1);
                    switch name
                      case 'Map'
                        validateattributes(arg2,{'binaryOccupancyMap', ...
                                            'occupancyMap'}, {'nonempty', 'scalar'}, ...
                                           'mobileRobotPRM', 'Map', 2);
                        map = arg2;
                        numNodes = defaultsNumNodes;
                        isMapDefault = false;
                      case 'NumNodes'
                        validateattributes(arg2, {'double'}, ...
                                           {'scalar', 'integer', 'positive','finite'}, 'mobileRobotPRM', 'NumNodes', 2);
                        map = defaultsMap;
                        numNodes = arg2;
                    end
                else
                    validateattributes(arg1,{'binaryOccupancyMap', ...
                                        'occupancyMap'}, {'nonempty', 'scalar'}, 'mobileRobotPRM', 'Map', 1);
                    map = arg1;
                    validateattributes(arg2, {'double'}, ...
                                       {'scalar', 'integer', 'positive','finite'}, 'mobileRobotPRM', 'NumNodes', 2);
                    numNodes = arg2;
                    isMapDefault = false;
                end
            end

            if ~coder.target('MATLAB')
                coder.internal.errorIf(isMapDefault, 'nav:navalgs:prm:DefaultMapCodegen');
            end

            % Assign inputs to the properties
            obj.InternalMap = map.copy;
            obj.InternalNumNodes = numNodes;
            obj.UpdateFlag = true;

            % Create internal objects for update and findpath
            obj.RoadmapBuilder = nav.algs.internal.RoadmapBuilder;
            obj.PathFinder = nav.algs.internal.PathFinder;
        end

        function set.Map(obj, map)
        %set.Map Setter for dependent property Map
            validateattributes(map, {'binaryOccupancyMap', ...
                                'occupancyMap'}, {'nonempty', 'scalar'},'mobileRobotPRM', 'Map');
            obj.InternalMap = map.copy;
            obj.UpdateFlag = true;
        end

        function map = get.Map(obj)
        %get.Map Getter for dependent property Map
            map = obj.InternalMap.copy;
        end

        function set.NumNodes(obj, nodes)
        %set.NumNodes Setter for dependent property NumNodes
            validateattributes(nodes, {'double'}, {'nonempty', 'positive', ...
                                'scalar', 'integer'},'mobileRobotPRM','NumNodes');
            obj.InternalNumNodes = nodes;
            obj.UpdateFlag = true;
        end

        function nodes = get.NumNodes(obj)
        %get.NumNodes Getter for dependent property NumNodes
            nodes = obj.InternalNumNodes;
        end

        function set.ConnectionDistance(obj, dist)
        %set.ConnectionDistance Setter for ConnectionDistance

            validateattributes(dist, {'double'}, {'nonnan', 'nonempty', 'positive', ...
                                'scalar', 'real'},'mobileRobotPRM','ConnectionDistance');
            obj.ConnectionDistance = dist;
            obj.setUpdateFlag(true);
        end

        function update(obj)
        %update Create or update the probabilistic roadmap
        %   update(mobileRobotPRM) constructs a roadmap if called for the first
        %   time after mobileRobotPRM object creation. Subsequent calls of update
        %   re-creates the roadmap by re-sampling the Map. The update
        %   function uses Map, NumNodes and ConnectionDistance
        %   values to construct the new roadmap.
        %
        %   Example:
        %       % Create a binary occupancy map
        %       map = binaryOccupancyMap(10,10);
        %
        %       % Create a probabilistic roadmap
        %       prm = mobileRobotPRM;
        %
        %       % Assign the map to mobileRobotPRM
        %       prm.Map = map;
        %
        %       % Construct the roadmap by calling update
        %       update(prm);
        %
        %       % Visualize the constructed roadmap using show
        %       show(prm);
        %
        %   See also mobileRobotPRM, findpath, show

        % If Map property is empty, then throw an error
            coder.internal.errorIf(isempty(obj.InternalMap), 'nav:navalgs:prm:EmptyMap');

            % Construct the roadmap
            if coder.target('MATLAB')
                % Release system object to allow change of Map type during
                % simulation
                obj.RoadmapBuilder.release();
            end
            obj.RoadmapBuilder.step(obj.InternalMap, ...
                                    obj.InternalNumNodes, obj.ConnectionDistance);

            % Set actual number of nodes
            obj.InternalNumNodes = obj.RoadmapBuilder.Roadmap.NumNodes;

            obj.UpdateFlag = false;

            % Clear the last found path if any
            obj.LastFoundPath = [];
        end

        function path = findpath(obj, start, goal)
        %findpath Find an obstacle free path between two points
        %   XY = findpath(PRM, START, GOAL) computes an obstacle free
        %   path between a 2-by-1 array, START, and a 2-by-1 array, GOAL.
        %   If START and GOAL are not connected in the roadmap, an empty
        %   array will be returned indicating the failure to find a
        %   path. Updating the roadmap using the update function or
        %   increasing the NumNodes may help find a path in a map
        %   with narrow passages
        %
        %   Example:
        %       % Create a binary occupancy grid map
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Create a probabilistic roadmap
        %       prm = mobileRobotPRM;
        %
        %       % Assign the map to mobileRobotPRM
        %       prm.Map = map;
        %
        %       % Find a path between two points
        %       xy = findpath(prm, [0 0], [10 10]);
        %
        %       % Visualize the path using show
        %       show(prm);
        %
        %   See also mobileRobotPRM, update, show

        % Validate start and goal points
            obj.validateStartGoal(start, goal);

            % If not updated, update the roadmap
            if obj.UpdateFlag
                obj.update;
            end

            % Find the path
            if coder.target('MATLAB')
                % Release system object to allow change of Map type during
                % simulation
                obj.PathFinder.release();
            end
            path = obj.PathFinder.step(obj.RoadmapBuilder.Roadmap, ...
                                       obj.InternalMap, start, goal);

            obj.LastFoundPath = path;
        end

        function ax = show(obj, varargin)
        %show Show the map, roadmap and path in a figure
        %   show(PRM) shows the map and the roadmap in a figure. update
        %   will be called if no roadmap exists. If a
        %   path was computed before calling the show method, the path
        %   will also be plotted on the figure.
        %
        %   AH = show(PRM) returns the handle of the axes used for
        %   by the show function.
        %
        %   show(___,Name,Value) provides additional options specified
        %   by one or more Name,Value pair arguments. Name must appear
        %   inside single quotes (''). You can specify several name-value
        %   pair arguments in any order as Name1,Value1,...,NameN,ValueN:
        %
        %       'Parent'      - Handle of an axes that specifies
        %                       the parent of the objects created by
        %                       show.
        %
        %       'Map'         - A string to turn on or off the display
        %                       of the map, whose value is 'on' or 'off'.
        %
        %                       Default: 'on'
        %
        %       'Roadmap'     - A string to turn on or off the display
        %                       of the roadmap, whose value is 'on' or 'off'.
        %
        %                       Default: 'on'
        %
        %       'Path'        - A string to turn on or off the display
        %                       of the path, whose value is 'on' or 'off'.
        %
        %                       Default: 'on'
        %
        %   Example:
        %       % Create a binary occupancy grid map
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Create a probabilistic roadmap
        %       prm = mobileRobotPRM;
        %
        %       % Assign the map to mobileRobotPRM
        %       prm.Map = map;
        %
        %       % Construct the roadmap by calling update
        %       xy = findpath(prm, [0 0], [10 10]);
        %
        %       % Visualize the path using show
        %       show(prm);
        %
        %       % Visualize the path without the roadmap
        %       show(prm, 'Roadmap', 'off');
        %
        %   See also mobileRobotPRM, findpath, update

        % If called in code generation, throw incompatibility error
            coder.internal.errorIf(~coder.target('MATLAB'), 'nav:navalgs:prm:GraphicsSupportCodegen', 'show')

            % Input defaults
            inputParams.axHandle = [];
            inputParams.showMap = true;
            inputParams.showRoadmap = true;
            inputParams.showPath = true;

            % Parse input arguments if any
            if ~isempty(varargin)
                inputParams = obj.parseShowInputs(varargin{:});
            end

            % Update the roadmap if not updated
            if obj.UpdateFlag
                obj.update;
            end

            axHandle = inputParams.axHandle;

            % Create a new axes if not assigned
            if isempty(axHandle)
                axHandle = newplot;
            end

            % Get the hold status for given axes
            holdStatus = ishold(axHandle);


            % Plot the map
            if inputParams.showMap
                imgHandle = obj.Map.show('world','Parent', axHandle);
                title(axHandle, message('nav:navalgs:prm:FigureTitle').getString);
                hold(axHandle, 'on');
            end

            if isa(obj.Map, 'occupancyMap')
                grid = obj.Map.occupancyMatrix;
                grid(grid < obj.Map.FreeThreshold) = 0;
                imgHandle.CData = grid;
            end

            plotColors.lightBlue = [0.301 0.745 0.933];
            plotColors.blue = [0.15 0.25 0.8];
            plotColors.green = [0.85 0.325 0.098];

            % Plot the roadmap
            if inputParams.showRoadmap
                if  ~isempty(obj.RoadmapBuilder.Roadmap.EdgeList)
                    % The plot arguments
                    args = {'LineStyle', '-', ...
                            'Color', plotColors.lightBlue};

                    % Plot edges
                    v1 = obj.getEdges();
                    plot(axHandle,v1(1, :), v1(2, :), args{:});
                end

                % Plot nodes if the edgelist is empty
                args = {'Marker', 'o', ...
                        'MarkerFaceColor', plotColors.blue, ...
                        'MarkerEdgeColor', plotColors.blue};
                markerSize = 6;

                nodeList = obj.RoadmapBuilder.Roadmap.NodeList;
                scatter(axHandle,nodeList(1, :),nodeList(2, :), markerSize, args{:});
                hold(axHandle, 'on');
            end

            % Plot the path if there is a last found path
            if inputParams.showPath && ~isempty(obj.LastFoundPath)
                args = {'LineStyle', '-', ...
                        'LineWidth', 2, ...
                        'Marker', 'o', ...
                        'MarkerFaceColor', plotColors.green, ...
                        'MarkerSize', 4,...
                        'MarkerEdgeColor', plotColors.green, ...
                        'Color', plotColors.green};

                plot(axHandle, obj.LastFoundPath(:,1),obj.LastFoundPath(:,2),args{:});
            end

            % Restore the hold status of the original figure
            if ~holdStatus
                hold(axHandle, 'off');
            end

            % Only return handle if user requested it.
            if nargout > 0
                ax = axHandle;
            end
        end

        function cpObj = copy(obj)
        %copy Create a deep copy of mobileRobotPRM object.

            if isempty(obj) && coder.target('MATLAB')
                cpObj = mobileRobotPRM.empty;
                return;
            end

            % construct new object
            cpObj = mobileRobotPRM(obj.InternalMap);

            % Copy public non-dependent properties with setters
            cpObj.ConnectionDistance = obj.ConnectionDistance;

            % Copy internal properties
            cpObj.InternalNumNodes = obj.InternalNumNodes;
            cpObj.UpdateFlag = obj.UpdateFlag;
            cpObj.LastFoundPath = obj.LastFoundPath;

            % Deep copy handles
            if coder.target('MATLAB')
                cpObj.PathFinder = obj.PathFinder.clone;
                cpObj.RoadmapBuilder = obj.RoadmapBuilder.clone;
            else
                cpObj.PathFinder = obj.PathFinder.copy;
                cpObj.RoadmapBuilder = obj.RoadmapBuilder.copy;
            end
        end
    end

    methods(Access = private)
        function setUpdateFlag(obj, val)
        %setUpdateFlag Allows setting the update flag property
            obj.UpdateFlag = val;
        end

        function v1 = getEdges(obj)
        %getEdges Get edges from the roadmap
            i = 1;
            v1 = zeros(2, 3*size(obj.RoadmapBuilder.Roadmap.EdgeList,2));
            for e=obj.RoadmapBuilder.Roadmap.EdgeList
                v1(:, i) = obj.RoadmapBuilder.Roadmap.NodeList(:,e(1));
                v1(:, i+1) = obj.RoadmapBuilder.Roadmap.NodeList(:,e(2));
                v1(:, i+2) = [NaN;NaN];
                i = i+3;
            end
        end

        function validateStartGoal(obj, start, goal)
        %validateStartGoal Validate start and goal points

            validateattributes(start, {'double'}, {'real', 'finite','numel', 2},...
                               'findpath', 'start');
            validateattributes(goal, {'double'}, {'real', 'finite','numel', 2},...
                               'findpath', 'goal');
            
            [~, validIdx] = obj.InternalMap.checkOccupancy([start; goal]);
            
            % Indirectly check if start and goal are within the map
            if any(~validIdx)
                xlimits = obj.InternalMap.XWorldLimits;
                ylimits = obj.InternalMap.YWorldLimits;
                if coder.target('MATLAB')
                    coder.internal.error('nav:navalgs:occgridcommon:CoordinateOutside', ...
                        sprintf('%0.1f',xlimits(1,1)), sprintf('%0.1f',xlimits(1,2)), ...
                        sprintf('%0.1f',ylimits(1,1)), sprintf('%0.1f',ylimits(1,2)));
                else
                    coder.internal.error('nav:navalgs:occgridcommon:CoordinateOutside', ...
                        coder.internal.num2str(xlimits(1,1)), coder.internal.num2str(xlimits(1,2)), ...
                        coder.internal.num2str(ylimits(1,1)), coder.internal.num2str(ylimits(1,2)));
                end
            end

            % Verify if points are in free space

            % Using raycast to ensure consistent behavior between input
            % validation and path computation methods. The consistent
            % behavior is that if a point is on an obstacle edge or
            % obstacle corner, it will be considered occupied.

            isStartFree = nav.algs.internal.checkLineCollision(start, ...
                                                              start, obj.InternalMap);

            if ~isStartFree
                coder.internal.error('nav:navalgs:prm:OccupiedLocation', 'start');
            end

            isGoalFree = nav.algs.internal.checkLineCollision(goal, ...
                                                              goal, obj.InternalMap);

            if ~isGoalFree
                coder.internal.error('nav:navalgs:prm:OccupiedLocation', 'goal');
            end
        end
    end

    methods (Static, Access = protected)
        function obj = loadobj(s)
        %LOADOBJ Custom implementation for loading the mobileRobotPRM object from a MAT file
        %   Reconstruct the mobileRobotPRM object based on the saved data structure.

        % Currently load object is not supported in code generation
            if coder.target('MATLAB')
                if isempty(s)
                    obj = mobileRobotPRM.empty;
                    return
                end

                % construct new object
                obj = mobileRobotPRM;

                % Copy public non-dependent properties with setters
                obj.ConnectionDistance = s.ConnectionDistance;

                % Copy internal properties
                obj.InternalMap = s.InternalMap;
                obj.InternalNumNodes = s.InternalNumNodes;
                obj.UpdateFlag = s.UpdateFlag;
                obj.LastFoundPath = s.LastFoundPath;

                % Deep copy handles
                obj.PathFinder = s.PathFinder.clone;
                obj.RoadmapBuilder = s.RoadmapBuilder.clone;
                obj.InternalMap = s.InternalMap.copy;
            end
        end
    end

    methods (Static, Access = private)
        function inputParams = parseShowInputs(varargin)
        %parseShowInputs Parse inputs for show method

            if coder.target('MATLAB')
                % Define the input parser
                validStrings = {'on', 'off'};
                p = inputParser;
                addParameter(p, 'Parent', [], ...
                             @(x)robotics.internal.validation.validateAxesUIAxesHandle(x)); %#ok<*EMFH>
                addParameter(p, 'Map', 'on', ...
                             @(x)any(validatestring(x,validStrings)));
                addParameter(p, 'Roadmap', 'on', ...
                             @(x)any(validatestring(x,validStrings)));
                addParameter(p, 'Path', 'on', ...
                             @(x)any(validatestring(x,validStrings)));

                % Parse inputs
                p.parse(varargin{:});
                inputParams.axHandle = p.Results.Parent;
                inputParams.showMap = strcmpi(p.Results.Map,'on');
                inputParams.showRoadmap = strcmpi(p.Results.Roadmap,'on');
                inputParams.showPath = strcmpi(p.Results.Path,'on');
            end
        end

    end
end
