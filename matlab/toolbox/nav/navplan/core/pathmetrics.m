classdef pathmetrics < nav.algs.internal.InternalAccess
%pathmetrics Information for path metrics
%   The pathmetrics object holds information for computing path
%   metrics. Calculate smoothness, clearance, and path validity based
%   on a set of poses and the associated map environment.
%
%   PATHMETRICOBJ = pathmetrics(NAVPATH) creates an object based on the
%   given navPath object. The state validator is assumed to be a
%   validatorOccupancyMap if state space of NAVPATH object is
%   StateSpaceSE2, StateSpaceDubins or StateSpaceReedsShepps and
%   validatorOccupancyMap3D if state space of NAVPATH object is
%   stateSpaceSE3 object.
%
%   PATHMETRICOBJ = pathmetrics(NAVPATH, VALIDATOR) creates an object
%   based on the given navPath object and associated state validator
%   for checking the path validity.
%
%   pathmetrics properties:
%   Path            - Path data structure
%   StateValidator  - Validator for states on path
%
%   pathmetrics methods:
%   smoothness    - Smoothness of path
%   clearance     - Minimum clearance from obstacles in map
%   isPathValid   - Determine if planned path is obstacle free
%   show          - Visualize path metrics in map environment
%
%   Example:
%       % Create binary occupancy map
%       load exampleMaps.mat;
%       map = binaryOccupancyMap(simpleMap, 2);
%
%       % Find a path using PRM planner
%       prm = mobileRobotPRM(map);
%       prm.ConnectionDistance = 4;
%       prm.NumNodes = 200;
%       path = findpath(prm, [2 2], [12 2]);
%       states = [path, zeros(size(path, 1), 1)];
%
%       % Create navPath object
%       navpath = navPath(stateSpaceSE2, states);
%
%       % Create validatorOccupancyMap object
%       statevalidator = validatorOccupancyMap;
%       statevalidator.Map = map;
%
%       % Create a path metrics object
%       pmObj = pathmetrics(navpath, statevalidator);
%
%       % Evaluate the minimum clearance of the path
%       clearancePathVal = clearance(pmObj);
%
%       % Evaluate the set of minimum distances for each
%       % segment of the path
%       clearanceStatesVals = clearance(pmObj, "Type", "states");
%
%   see also mobileRobotPRM, occupancyMap, occupancyMap3D.

% Copyright 2019-2024 The MathWorks, Inc.

    properties

        %Path - Path data structure
        %   Path data structure, specified as a navPath object is the path
        %   whose metric is to be calculated.
        Path

        %StateValidator - Validator for states on the path
        %   Validator for states on the path, specified as a
        %   validatorOccupancyMap, validatorVehicleCostmap, or
        %   validatorOccupancyMap3D object that validates the states and
        %   discretized motions based on the values in a 2-D or 3-D
        %   occupancy map.
        %
        %   Default: validatorOccupancyMap(stateSpaceSE2, binaryOccupancyMap(10)) for 2-D state space
        %            validatorOccupancyMap3D(stateSpaceSE3) for 3-D state space
        StateValidator
    end

    properties (Access = private)

        %   PtsObstacle - State's intersection points on obstacles at
        %   minimum distances. This is useful to plot clearance.
        PtsObstacle = [];
    end

    properties(Access = {?nav.algs.internal.InternalAccess})

        %IsStateValidatorDefault - State Validator default flag
        IsStateValidatorDefault;

        %IsStateValidatorUpdated - to check when stateValidator is updated.
        IsStateValidatorUpdated;

    end

    methods

        function obj = pathmetrics(pathobj, validatorOccupMap)
        %pathmetrics constructor

        %Check number of input arguments
            narginchk(1,2);

            % Input will be validated in property setter
            obj.Path = pathobj;


            if nargin == 2
                % Validate state validator given as user input
                % Input will be validated in property setter
                obj.StateValidator = validatorOccupMap;

            else
                % Use default state validator based on the stateSpace
                if isa(obj.Path.StateSpace,'stateSpaceSE3')
                    obj.StateValidator = validatorOccupancyMap3D;
                else
                    obj.StateValidator = validatorOccupancyMap;
                end
                obj.IsStateValidatorDefault = true;
                obj.StateValidator.ValidationDistance = ...
                    1/obj.StateValidator.Map.Resolution;
            end
        end

        function smoothVal = smoothness(obj, varargin)
        %smoothness Smoothness of path
        %
        %   SMOOTHVAL = smoothness(PATHMETRICSOBJ) evaluate the
        %   smoothness of the planned path. Values closer to 0 indicate
        %   a smoother path. Straight line paths return a value of 0.
        %
        %   SMOOTHVAL = smoothness(PATHMETRICSOBJ, "TYPE", "SEGMENTS")
        %   returns individual smoothness calculations between each set
        %   of three poses on the path. SMOOTHVAL is a (N-2)-element
        %   vector where N is the number of poses.
        %
        %   Example:
        %       % Create binary occupancy map
        %       load exampleMaps.mat;
        %       map = binaryOccupancyMap(simpleMap, 2);
        %
        %       % Find a path using PRM planner
        %       prm = mobileRobotPRM(map);
        %       prm.ConnectionDistance = 4;
        %       prm.NumNodes = 200;
        %       path = findpath(prm, [2 2], [12 2]);
        %       states = [path, zeros(size(path, 1), 1)];
        %
        %       % Create navPath object
        %       navpath = navPath(stateSpaceSE2, states);
        %
        %       % Create a path metrics object
        %       pmObj = pathmetrics(navpath);
        %
        %       % Evaluate the smoothness of the planned path
        %       smoothPathVal = smoothness(pmObj);
        %
        %       % Evaluate the smoothness between each set of three
        %       % poses on the path
        %       smoothSegmentsVals = smoothness(pmObj, "Type", "segments");
        %
        % see also pathmetrics, clearance, isPathValid, show.

        % Create parameter name cell array
            name = "Type";

            % Create default value cell array
            default = "sum";

            % Create a parser
            parser = robotics.core.internal.NameValueParser(name,default);

            % Parse name-value inputs (where the name-value inputs are
            % contained in varargin).
            parse(parser, varargin{:});

            % Access 'type' value
            type = parameterValue(parser, "Type");

            values = {'sum', 'segments'};

            % Validatestring error message was not clear to users g1885126
            % so using double validation
            validateattributes(type, {'string', 'char'}, {'nonempty'});

            validatestring(type, values, "smoothness", "pathmetrics");

            % Smoothness code
            smoothVal = nav.algs.internal.pathMetricsFunctions.smoothness(obj.Path.States, ...
                                                                          @(state1,state2)obj.Path.StateSpace.distance(state1,state2));

            if strcmp(type, "sum")
                smoothVal = sum(smoothVal);
            end
        end

        function clearanceVal = clearance(obj, varargin)
        %clearance Minimum clearance of path
        %
        %   CLEARANCEVAL = clearance(PATHMETRICSOBJ) returns the
        %   minimum clearance of the path. Clearance is measured as the
        %   minimum distance between grid cell centers of states on the
        %   path and obstacles in the specified map environment.
        %
        %   CLEARANCEVAL = clearance(PATHMETRICSOBJ, "TYPE", "STATES")
        %   returns the set of minimum distances for each states of the
        %   path. CLEARANCEVAL is returned as an n-by-1 vector, where n
        %   is the number of states
        %
        %   Note: The computed clearance is accurate up to sqrt(2)
        %   times grid map cell size
        %
        %   Example:
        %       % Create binary occupancy map
        %       load exampleMaps.mat;
        %       map = binaryOccupancyMap(simpleMap, 2);
        %
        %       % Find a path using PRM planner
        %       prm = mobileRobotPRM(map);
        %       prm.ConnectionDistance = 4;
        %       prm.NumNodes = 200;
        %       path = findpath(prm, [2 2], [12 2]);
        %       states = [path, zeros(size(path, 1), 1)];
        %
        %       % Create navPath object
        %       navpath = navPath(stateSpaceSE2, states);
        %
        %       % Create validatorOccupancyMap object
        %       statevalidator = validatorOccupancyMap;
        %       statevalidator.Map = map;
        %
        %       % Create a path metrics object
        %       pmObj = pathmetrics(navpath, statevalidator);
        %
        %       % Evaluate the minimum clearance of the path
        %       clearancePathVal = clearance(pmObj);
        %
        %       % Evaluate the set of minimum distances for each
        %       % states of path
        %       clearanceStatesVals = clearance(pmObj, "Type", "states");
        %
        %   See also pathmetrics, smoothness, isPathValid, show.

        % Create parameter name cell array
            name = "Type";
            % Create default value cell array
            default = "min";
            % Create a parser
            parser = robotics.core.internal.NameValueParser(name,default);
            % Parse name-value inputs (where the name-value inputs are
            % contained in varargin).
            parse(parser, varargin{:});
            % Access 'type' value
            type = parameterValue(parser, "Type");
            values = {'min', 'states'};
            % Validatestring error message was not clear to users g1885126
            % so using double validation
            validateattributes(type, {'string', 'char'}, {});
            validatestring(type, values, "clearance", "pathmetrics");

            if obj.IsStateValidatorUpdated
                validateattributes(obj.StateValidator, {'validatorOccupancyMap','validatorVehicleCostmap','validatorOccupancyMap3D'},{});
                checkStateValidatorCompatibility(obj,obj.StateValidator);
                obj.IsStateValidatorUpdated = false;

            end
            poses = obj.Path.States;
            nStates = size(poses,1);
            clearanceVal = inf(1,nStates);
            obj.PtsObstacle = [];


            if ~obj.IsStateValidatorDefault
                if isa(obj.StateValidator.Map, "binaryOccupancyMap") || isa(obj.StateValidator.Map, "occupancyMap") || isa(obj.StateValidator.Map, "occupancyMap3D")
                    occuMap = obj.StateValidator.Map;
                else
                    occuMap = obj.StateValidator.OccupancyMapInternal;
                end

                [clearanceVal, obj.PtsObstacle] = nav.algs.internal.pathMetricsFunctions.clearance(...
                    poses, occuMap);
            end

            if strcmp(type, "min")
                clearanceVal = min(clearanceVal);
            end
        end

        function boolVal = isPathValid(obj)
        %isPathValid Determine if planned path is obstacle free
        %
        %   BOOLVAL = isPathValid(PATHMETRICSOBJ) returns true if
        %   planned path is obstacles free otherwise false.
        %
        %   Example:
        %       % Create binary occupancy map
        %       load exampleMaps.mat;
        %       map = binaryOccupancyMap(simpleMap, 2);
        %
        %       % Find a path using PRM planner
        %       prm = mobileRobotPRM(map);
        %       prm.ConnectionDistance = 4;
        %       prm.NumNodes = 200;
        %       path = findpath(prm, [2 2], [12 2]);
        %       states = [path, zeros(size(path, 1), 1)];
        %
        %       % Create navPath object
        %       navpath = navPath(stateSpaceSE2, states);
        %
        %       % Create validatorOccupancyMap object
        %       statevalidator = validatorOccupancyMap;
        %       statevalidator.Map = map;
        %
        %       % Create a path metrics object
        %       pmObj = pathmetrics(navpath, statevalidator);
        %
        %       % Determine if planned path is obstacle free
        %       boolVal = isPathValid(pmObj);
        %
        %   See also pathmetrics, smoothness, clearance, show.
            boolVal = true;
            if obj.IsStateValidatorDefault
                %Environment is obstacles free so is valid.
                return;
            end

            %Check each segment is valid or not using isMotionValid method
            %the state validator
            for i = 1:size(obj.Path.States,1)-1
                if ~isMotionValid(obj.StateValidator, obj.Path.States(i,:), obj.Path.States(i+1,:))
                    boolVal = false;
                    return;
                end
            end
        end

        function ax = show(obj, varargin)
        %Show path metrics in map environment
        %
        %   AXHANDLE = show(PATHMETRICSOBJ) plots the path in the map
        %   environment with minimum clearance shown. Use the "Metrics"
        %   name-value pair to see more metrics.
        %
        %   AXHANDLE = show(PATHMETRICSOBJ, NAME, VALUE) specifies
        %   additional name-value pair arguments as described below:
        %
        %   "Parent"            Handle to an axes on which to display
        %                       the metrics.
        %   "Metrics"           Display specific metrics of the path,
        %                       specified as a cell array of strings,
        %                       using any combination of "MinClearance",
        %                       "StatesClearance", and "Smoothness".
        %   "Colormap"          Colormap values for the pixel values for
        %                       smoothness plot, specified as a
        %                       three-column matrix of RGB triplets.
        %                       If not provided, the current colormap
        %                       ('green', 'orange', 'red') is used,
        %                       'green' is good and 'red' is worst.
        %
        %   Example:
        %       % Create binary occupancy map
        %       load exampleMaps.mat;
        %       map = binaryOccupancyMap(simpleMap, 2);
        %
        %       % Find a path using PRM planner
        %       prm = mobileRobotPRM(map);
        %       prm.ConnectionDistance = 4;
        %       prm.NumNodes = 200;
        %       path = findpath(prm, [2 2], [12 2]);
        %       states = [path, zeros(size(path, 1), 1)];
        %
        %       % Create navPath object
        %       navpath = navPath(stateSpaceSE2, states);
        %
        %       % Create validatorOccupancyMap object
        %       statevalidator = validatorOccupancyMap;
        %       statevalidator.Map = map;
        %
        %       % Create a path metrics object
        %       pmObj = pathmetrics(navpath, statevalidator);
        %
        %       % Visualize the path minimum clearance
        %       show(pmObj);
        %
        %       % Visualize the path smoothness
        %       axHandle = show(pmObj, "Metrics", {"smoothness"});
        %
        %       % Visualize the path smoothness and clearance by
        %       % passing axes handle
        %       axHandle = show(pmObj, "Parent", axHandle, "Metrics", {"smoothness", "StatesClearance"});
        %
        %   See also pathmetrics, smoothness, clearance, isPathValid.

        %Parse the input parameters.
            [axHandle,metrics,cmapVals] = obj.validateShowInput(varargin);

            % Create a new axes if not assigned
            if isempty(axHandle)
                axHandle = newplot;
            end
            % Get the hold status for given axes
            holdStatus = ishold(axHandle);
            hold(axHandle, 'on');

            if ~obj.IsStateValidatorDefault
                %Visualize the map
                if isa(obj.StateValidator.Map, "binaryOccupancyMap") || isa(obj.StateValidator.Map, "occupancyMap")
                    nav.algs.internal.MapUtils.showGrid(obj.StateValidator.Map, axHandle, 0, 0, false);
                elseif isa(obj.StateValidator.Map, "occupancyMap3D")
                    show(obj.StateValidator.Map, 'Parent', axHandle);
                else
                    plot(obj.StateValidator.Map, 'Parent', axHandle);
                end
                hold(axHandle, "on");
            end

            %Take legend status;
            legendStatus = isempty(axHandle.Legend);
            legend('off');

            if isa(obj.StateValidator,'validatorOccupancyMap3D')
                %plot smoothness values
                if find(strcmp(metrics, "Smoothness"))
                    %visualize smoothness
                    smoothVals = obj.smoothness("Type", "segments");
                    obj.plotSmoothness3D(smoothVals,axHandle,cmapVals)
                else
                    %visualize paths
                    obj.plotLine3D(axHandle, obj.Path.States,...
                                   nav.internal.Marker.Line, nav.internal.Size.Path, ...
                                   nav.internal.LineSpecColor.PathInternal);
                end
                %plot clearance values
                if ~isempty(find(strcmp(metrics, "MinClearance"), 1)) ||...
                        ~isempty(find(strcmp(metrics, "StatesClearance"), 1))
                    obj.plotClearance3D(axHandle, metrics);
                end
            else
                %plot smoothness values
                if find(strcmp(metrics, "Smoothness"))
                    smoothVals = obj.smoothness("Type", "segments");
                    obj.plotSmoothness(smoothVals, axHandle,cmapVals);
                else
                    %visualize paths
                    obj.plotLine(axHandle, obj.Path.States,...
                                   nav.internal.Marker.Line, nav.internal.Size.Path, ...
                                   nav.internal.LineSpecColor.PathInternal);
                end
                %plot clearance values
                if ~isempty(find(strcmp(metrics, "MinClearance"), 1)) ||...
                        ~isempty(find(strcmp(metrics, "StatesClearance"), 1))
                    obj.plotClearance(axHandle, metrics);
                end
            end
            % Restore the hold status of the original figure
            if ~holdStatus
                hold(axHandle, "off");
            end
            % Restore the legend hold status
            if ~legendStatus
                legend('on');
            end
            % Only return handle if user requested it.
            if nargout > 0
                ax = axHandle;
            end
        end

        function cpObj = copy(obj)
        %copy Create a deep copy of pathmetrics object.
            if isempty(obj)
                cpObj = pathmetrics.empty;
                return;
            end
            % construct new object
            cpObj = pathmetrics(obj.Path);
            % Copy public non-dependent properties with setters
            cpObj.StateValidator = obj.StateValidator;
            % Copy internal properties
            cpObj.IsStateValidatorDefault = obj.IsStateValidatorDefault;
        end

        function set.Path(obj, pathobj)
        % Validate navpath attribute
            nav.internal.validation.validateNavPath(pathobj, "", "Path");
            obj.Path = pathobj;
        end

        function set.StateValidator(obj, statevalidator)
        %set.StateValidator Setter for StateValidator property
            nav.internal.validation.validateStateValidators(statevalidator, "", "StateValidator");
            obj.StateValidator = statevalidator;
            obj.IsStateValidatorDefault = false; %#ok<MCSUP>
            obj.IsStateValidatorUpdated = true; %#ok<MCSUP>

        end

    end

    methods(Access = private)
        function axHandle = plotSmoothness(obj,smoothVal,axHandle,cmapVals)
        %plotSmoothness Function to plot the smoothness values on the 2D map with colors
        % varying according to the smoothness values

            pathDiscrete = obj.Path.States;
            % Plot the line as a patch so individual segments can be colorized
            patch([pathDiscrete(:,1); nan],[pathDiscrete(:,2); nan],[0; smoothVal(:); 0; 0],'EdgeColor','interp','Parent',axHandle,'LineWidth',3);
            % Set the colormap for the figure
            axHandle.Colormap = cmapVals;
            % Set limits and show colorbar
            if numel(smoothVal) > 1 && max(smoothVal) > 0 
                                                          % used 'ceil' to map colorbar max. limit to nearest
                                                          % integer, which avoids visualization problem for very low
                                                          % smooth values
                axHandle.CLim = [0 ceil(max(smoothVal))];
            end
            colorbar;
        end

        function plotSmoothness3D(obj,smoothVal,axHandle,cmapVals)
        %plotSmoothness3D Function to plot the smoothness values on the 3D map with colors
        % varying according to the smoothness values

        %Find occupancyMap3D patch object and lock colormap values to
        %avoid changing color of occupancyMap3D during 3D path plot
        % with colorbar.
            hPatch = findobj(axHandle, 'Tag', message('nav:navalgs:occmap3d:FigureTitle').getString);
            obj.lockPatchColor(axHandle, hPatch);

            %plot 3D line along states
            pathDiscrete = obj.Path.States;
            p = patch([pathDiscrete(:,1); nan],[pathDiscrete(:,2); nan],[pathDiscrete(:,3); nan], [0; smoothVal(:); 0; 0],'EdgeColor','interp','Parent',axHandle,'LineWidth',3);

            %Assign colors of smoothness plot and lock it's color map value.
            axHandle.Colormap = cmapVals;
            obj.lockPatchColor(axHandle, p);

            % Set limits and show colorbar
            if numel(smoothVal) > 1 && max(smoothVal) > 0 
                                                          % used 'ceil' to map colorbar max. limit to nearest
                                                          % integer, which avoids visualization problem for very low
                                                          % smooth values
                axHandle.CLim = [0 ceil(max(smoothVal))];
            end
            colorbar;
        end

        function plotClearance(obj, axHandle, metrics)
        %plotClearance Visualize clearance of path and segments.
            if obj.IsStateValidatorDefault
                return;
            end
            %Compute clearance
            minDist = clearance(obj, "Type", "states");
            if isa(obj.StateValidator,'validatorVehicleCostmap')
                stateGridPts = obj.StateValidator.OccupancyMapInternal.world2grid(obj.Path.States(:,1:2));
                stateGridCellCenter = obj.StateValidator.OccupancyMapInternal.grid2world(stateGridPts);
                halfGridCellSize = (obj.StateValidator.Map.CellSize/2);
            else
                stateGridPts = obj.StateValidator.Map.world2grid(obj.Path.States(:,1:2));
                stateGridCellCenter = obj.StateValidator.Map.grid2world(stateGridPts);
                halfGridCellSize = 1/(2*obj.StateValidator.Map.Resolution);
            end

            obstacleGridCellCenter = obj.PtsObstacle;

            if find(strcmp(metrics, "MinClearance"))
                [d,idx] = min(minDist);
                % compute min clearance query state and obstacle grid centers for patch plot
                if d > 0 && (~isinf(d))
                    xObst = obstacleGridCellCenter(idx,1);
                    yObst = obstacleGridCellCenter(idx,2);
                    xPt = stateGridCellCenter(idx,1);
                    yPt = stateGridCellCenter(idx,2);

                    % plot square patches on query states
                    obj.plotPatches(axHandle,xPt,yPt,halfGridCellSize,0.3, ...
                        nav.internal.LineSpecColor.ClearanceInternal);

                    % plot square patches on obstacle
                    obj.plotPatches(axHandle,xObst,yObst,halfGridCellSize,0.5,...
                        nav.internal.LineSpecColor.ClearanceInternal);

                    % plot min clearance line
                    obj.plotLine(axHandle, [stateGridCellCenter(idx,:);...
                        obstacleGridCellCenter(idx,:)], nav.internal.Marker.Line, ...
                        nav.internal.Size.MinClearance, nav.internal.LineSpecColor.ClearanceInternal);


                    obstacleGridCellCenter(idx,:) = [];
                    stateGridCellCenter(idx,:) = [];
                    minDist(idx) = [];
                end
            end

            if find(strcmp(metrics, "StatesClearance"))
                % compute unique query point and obstacle grid centers for patch plot
                if isa(obj.StateValidator,'validatorVehicleCostmap')
                    gridPtsObstacle = obj.StateValidator.OccupancyMapInternal.world2grid(obstacleGridCellCenter);
                    gridSize = obj.StateValidator.Map.MapSize;
                else
                    gridPtsObstacle = obj.StateValidator.Map.world2grid(obstacleGridCellCenter);
                    gridSize = obj.StateValidator.Map.GridSize;
                end
                % visualize square patches only if minDist is not zero
                squarePatchesToConsiderInd = find((minDist' > 0) & (~isinf(minDist')));
                [~,uniqueObstacleCellIndex] = unique(sub2ind(gridSize,gridPtsObstacle(squarePatchesToConsiderInd,1),gridPtsObstacle(squarePatchesToConsiderInd,2)));
                [~,uniqueStateCellIndex] = unique(sub2ind(gridSize,stateGridPts(squarePatchesToConsiderInd,1),stateGridPts(squarePatchesToConsiderInd,2)));
                xObst = obstacleGridCellCenter(squarePatchesToConsiderInd(uniqueObstacleCellIndex),1)';
                yObst = obstacleGridCellCenter(squarePatchesToConsiderInd(uniqueObstacleCellIndex),2)';
                xPt = stateGridCellCenter(squarePatchesToConsiderInd(uniqueStateCellIndex),1)';
                yPt = stateGridCellCenter(squarePatchesToConsiderInd(uniqueStateCellIndex),2)';

                stateClearancePlot = nan(size(obstacleGridCellCenter,1)*3,size(obstacleGridCellCenter,2));
                iter = 1;
                for i = 1:size(obstacleGridCellCenter,1)
                    stateClearancePlot(iter:iter+2,:) = [obstacleGridCellCenter(i,:); stateGridCellCenter(i,:); nan(1,size(obstacleGridCellCenter,2))];
                    iter = iter+3;
                end

                % plot square patches on query states
                obj.plotPatches(axHandle,xPt,yPt,halfGridCellSize,0.3, ...
                                nav.internal.LineSpecColor.ClearanceInternal);

                % plot square patches on obstacle
                obj.plotPatches(axHandle,xObst,yObst,halfGridCellSize,0.5, ...
                                nav.internal.LineSpecColor.ClearanceInternal);

                % plot state clearance line
                obj.plotLine(axHandle, stateClearancePlot,...
                             nav.internal.Marker.DashedDotLine, ...
                             nav.internal.Size.StatesClearance, ...
                             nav.internal.LineSpecColor.ClearanceInternal);
            end
        end

        function plotClearance3D(obj,axHandle, metrics)
        %plot clearance for 3D
            if obj.IsStateValidatorDefault
                return;
            end
            minDist = clearance(obj, "Type", "states");
            %compute the points to connect via lines on the states and obstacles to show clearance
            stateGridPts = world2grid(obj.StateValidator.Map,obj.Path.States);
            stateGridCellCenter = grid2world(obj.StateValidator.Map,stateGridPts);
            halfGridCellSize = 1/(2*obj.StateValidator.Map.Resolution);
            obstacleGridCellCenter = obj.PtsObstacle;

            if find(strcmp(metrics, "MinClearance"))
                [d,idx] = min(minDist);
                if d > 0 && (~isinf(d))
                    % plot cube patches on query states
                    plotPatches3D(obj, axHandle, stateGridCellCenter(idx,:),...
                                  halfGridCellSize, nav.internal.LineSpecColor.ClearanceInternal);

                    % plot cube patches on obstacle
                    plotPatches3D(obj, axHandle, obstacleGridCellCenter(idx,:),...
                                  halfGridCellSize, nav.internal.LineSpecColor.ClearanceInternal);

                    % plot min clearance line
                    obj.plotLine3D(axHandle, [stateGridCellCenter(idx,:);...
                                              obstacleGridCellCenter(idx,:)], nav.internal.Marker.Line, ...
                                   nav.internal.Size.MinClearance, nav.internal.LineSpecColor.ClearanceInternal);

                    stateGridCellCenter(idx,:) = [];
                    obstacleGridCellCenter(idx,:) = [];
                end
            end

            if find(strcmp(metrics, "StatesClearance"))
                stateClearancePlot = nan(size(obstacleGridCellCenter,1)*3,size(obstacleGridCellCenter,2));
                iter = 1;
                for i = 1:size(obstacleGridCellCenter,1)
                    % plot cube patches on query states
                    plotPatches3D(obj, axHandle, stateGridCellCenter(i,:),...
                                  halfGridCellSize, nav.internal.LineSpecColor.ClearanceInternal);

                    % plot cube patches on obstacle
                    plotPatches3D(obj, axHandle, obstacleGridCellCenter(i,:),...
                                  halfGridCellSize, nav.internal.LineSpecColor.ClearanceInternal);

                    stateClearancePlot(iter:iter+2,:) = [obstacleGridCellCenter(i,:); stateGridCellCenter(i,:); nan(1,size(obstacleGridCellCenter,2))];
                    iter = iter+3;
                end
                % plot state clearance line
                obj.plotLine3D(axHandle, stateClearancePlot,...
                               nav.internal.Marker.DashedDotLine, ...
                               nav.internal.Size.StatesClearance, ...
                               nav.internal.LineSpecColor.ClearanceInternal);
            end
        end

        function checkStateValidatorCompatibility(obj,stateValidator)
            if (isa(obj.Path.StateSpace,'stateSpaceSE3') && ~isa(stateValidator,'validatorOccupancyMap3D'))
                coder.internal.error('nav:navalgs:pathMetrics:InvalidStateValidator3D');
            elseif (isa(obj.Path.StateSpace,'stateSpaceSE2') && ~(isa(stateValidator,'validatorOccupancyMap') || isa(stateValidator,'validatorVehicleCostmap')))
                coder.internal.error('nav:navalgs:pathMetrics:InvalidStateValidator2D');
            end

        end

        function plotPatches3D(obj, axHandle, gridCellCenter, halfGridCellSize, expColor)
        %plotPatches Plot patches and map face color values in
        % defined theme for 3D.

            [cubePtsX,cubePtsY,cubePtsZ] = obj.cubeVertics(gridCellCenter,halfGridCellSize);
            fill3(cubePtsX,cubePtsY,cubePtsZ, [1 0 0], 'Parent',axHandle,FaceAlpha=0.5);
            for j=1:6
                matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                    axHandle.Children(j), "FaceColor", expColor);
            end
        end
    end

    methods(Static, Access = private)
        function [cubePtsX,cubePtsY,cubePtsZ] = cubeVertics(center,halfsize)

        %Compute cube vertices for plotting.
            X = [-1 , -1 , +1 , +1 ; -1 , -1 , -1 , -1 ; -1 , -1 , +1 , +1 ; +1 , +1 , +1 , +1 ; -1 , +1 , +1 , -1 ; -1 , +1 , +1 , -1 ];
            Y = [-1 , -1 , -1 , -1 ; -1 , -1 , +1 , +1 ; +1 , +1 , +1 , +1 ; -1 , +1 , +1 , -1 ; -1 , -1 , +1 , +1 ; -1 , -1 , +1 , +1 ];
            Z = [+1 , -1 , -1 , +1 ; +1 , -1 , -1 , +1 ; +1 , -1 , -1 , +1 ; +1 , +1 , -1 , -1 ; +1 , +1 , +1 , +1 ; -1 , -1 , -1 , -1 ];
            cubePtsX = (ones(size(X))*center(1) +X*halfsize)';
            cubePtsY = (ones(size(Y))*center(2) +Y*halfsize)';
            cubePtsZ = (ones(size(Z))*center(3) +Z*halfsize)';
        end

        function [axHandle,metrics,cmapVals] = validateShowInput(input)

        %Parse the input parameters.
            parser = inputParser;
            addParameter(parser, "Parent", [], ...
                         @(x)robotics.internal.validation.validateAxesUIAxesHandle(x));
            metricsDefaultValue = "MinClearance";
            addParameter(parser, "Metrics", metricsDefaultValue);
            addParameter(parser, "Colormap", [], ...
                         @(x)validateattributes(x,'double',{'nonnan', 'finite', 'size', [NaN,3]}, 'show', 'Colormap'));

            parser.parse(input{:});
            axHandle = parser.Results.Parent;
            tempMetrics = parser.Results.Metrics;
            metrics = strings(1,numel(tempMetrics));
            % Validatestring error message was not clear to users g1885126
            % so using double validation
            validateattributes(tempMetrics, {'cell', 'string'}, {'nonempty'}, 'show', 'Metrics');
            % Validate positions
            for i=1:numel(tempMetrics)
                metrics(i) = validatestring(tempMetrics{i}, {'MinClearance', 'StatesClearance', 'Smoothness'}, 'show', 'Metrics');
            end

            cmapVals = parser.Results.Colormap;
            if isempty(cmapVals)
                % Color transition: "g" -> "o" -> "r"
                colorCodeValues = [0 0.8 0; 0.91 0.41 0.17; 0.8 0 0];
                colorDiff = diff(colorCodeValues);
                % Generate points to blur colorspace over
                x = linspace(0,1,50)';
                % Create colormap by transitioning colors between colorCodeValues
                cmapVals = [colorCodeValues(1,:) + x*colorDiff(1,:);  % Transition from low (green) to mid (orange)
                            colorCodeValues(2,:) + x*colorDiff(2,:)]; % Transition from mid (orange) to high (red)
            end
        end

        function lockPatchColor(axHandle, hPatch)
        %lockPatchColor Lock colormap values for the provided patch
        % object.

            if ~isempty(hPatch)
                map = colormap(axHandle);
                cdata = get(hPatch, 'FaceVertexCData');
                rgb = ind2rgb(floor(rescale(cdata,1,size(map,1))), map);
                set(hPatch, 'FaceVertexCData',squeeze(rgb));
            end
        end

        function plotPatches(axHandle,x,y,halfGridCellSize,faceAlphaValue, expColor)
        %plotPatches Plot patches and map face color values in
        % defined theme.

            patch('XData',[x-halfGridCellSize;x+halfGridCellSize;x+halfGridCellSize;x-halfGridCellSize],...
                  'YData',[y-halfGridCellSize;y-halfGridCellSize;y+halfGridCellSize;y+halfGridCellSize],...
                  'EdgeColor','none','FaceAlpha',faceAlphaValue,'Parent',axHandle);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                axHandle.Children(1), "FaceColor", expColor);
        end

        function plotLine(axHandle, clearancePts, lineStyle, lineWidth, expColor)
        %plotLine Plot line and map color values in defined theme for 2D.
            plot(clearancePts(:,1), clearancePts(:,2), ...
                 'LineStyle', lineStyle, 'LineWidth', lineWidth, ...
                 'Marker', nav.internal.Marker.Point, ...
                 'MarkerSize', nav.internal.Size.PathState,Parent=axHandle);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                axHandle.Children(1), "Color", expColor);
        end

        function plotLine3D(axHandle, clearancePts, lineStyle, lineWidth, expColor)
        %plotLine3D Plot line and map color values in defined theme for 3D.

            plot3(clearancePts(:,1), clearancePts(:,2), clearancePts(:,3),...
                  'LineStyle', lineStyle, 'LineWidth', lineWidth, .........
                  'Marker', nav.internal.Marker.Point, ...
                  'MarkerSize', nav.internal.Size.PathState,Parent=axHandle);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                axHandle.Children(1), "Color", expColor);
        end
    end
end
