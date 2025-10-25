classdef plannerAStarGrid < nav.algs.internal.InternalAccess&...
        matlabshared.tracking.internal.CustomDisplay
% plannerAStarGrid A* path planner for grid map.
%   A* path planning algorithm performs A* search on the occupancy map and
%   finds obstacle-free, shortest path between the given start grid and
%   goal grid guided by heuristic cost.
%
%   PLANNER = plannerAStarGrid creates a plannerAStarGrid object with a
%   binaryOccupancyMap with a width and height of 10 meters, and grid
%   resolution of one cell per meter.
%
%   PLANNER = plannerAStarGrid(MAP) creates a plannerAStarGrid object with
%   the specified map object, MAP. Specify the Map either as a
%   binaryOccupancyMap or occupancyMap object. The MAP input sets the
%   value of the Map property.
%
%   PLANNER = plannerAStarGrid(MAP, Name, Value, ...)  specifies additional
%   attributes of the plannerAStarGrid object with each specified property
%   name set to the specified value. Name must appear inside single
%   quotes (''). You can specify several name-value pair arguments in any
%   order as Name1,Value1,...,NameN,ValueN. Properties not specified retain
%   their default values.
%
%   plannerAStarGrid properties:
%       Map            - Map representation.
%       TieBreaker     - Toggle tie breaker.
%       DiagonalSearch - Toggle diagonal search.
%       GCost          - Cost of moving between any two points in a grid.
%       GCostFcn       - Custom gcost function.
%       HCost          - Heuristic cost between a point and goal in a grid.
%       HCostFcn       - Custom hcost function.
%
%   plannerAStarGrid methods:
%       plan      - Finds obstacle-free path between two points.
%       show      - Visualize the planned path.
%
%   Example:
%
%       % Create a binary occupancy map
%       map = binaryOccupancyMap(zeros(50,50));
%
%       % Create plannerAStarGrid object with map
%       planner = plannerAStarGrid(map);
%
%       % Find path between two grid coordinates
%       pathRowCol = plan(planner, [2 3], [28 46]);
%
%       % Visualize the map and path in a figure
%       show(planner)
%
%       % Adding legend to plot
%       legend
%
%   Example:
%
%       % Create a binary occupancy map
%       map = binaryOccupancyMap(zeros(50,50));
%
%       % Create plannerAStarGrid object with map
%       planner = plannerAStarGrid(map,'HCost','Manhattan');
%
%       % Find path between two grid coordinates
%       pathRowCol = plan(planner, [2 3], [28 46]);
%
%       % Visualize the map and path in a figure
%       show(planner)
%
%       % Adding legend to plot
%       legend
%
%   Example:
%
%       % Create a binary occupancy map
%       map = binaryOccupancyMap(zeros(50,50));
%
%       % Custom Manhattan distance function handle.
%       manhattan = @(pose1,pose2)sum(abs(pose1-pose2),2);
%
%       % Create plannerAStarGrid object with map and custom hcost function
%       planner = plannerAStarGrid(map,'HCostFcn',manhattan);
%
%       % Find path between two grid coordinates
%       pathRowCol = plan(planner, [2 3], [28 46]);
%
%       % Visualize the map and path in a figure
%       show(planner)
%
%       % Adding legend to plot
%       legend
%
%   See also binaryOccupancyMap, occupancyMap, plannerRRT,
%   plannerHybridAStar

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen


    properties

        %Map Map representation.
        %   Map representation, specified as the comma-separated pair
        %   consisting of 'Map' and a binaryOccupancyMap or occupancyMap
        %   object. This object represents the environment of the robot.
        %   The object is a matrix grid with values indicating the
        %   occupancy of locations in the map.
        %
        %   This property is read-only.
        %   Default: binaryOccupancyMap object
        Map

        %TieBreaker Toggle tie breaker mode.
        %   Toggle tie breaker mode, specified as the comma-separated pair
        %   consisting of 'TieBreaker' and either 'on' or 'off'.
        %
        %   The TieBreaker property will enable or disable the deterministic
        %   method of choosing one among the many paths with the same length
        %   by tweaking the heuristic cost value.
        %   Default: 'off'
        TieBreaker

        %DiagonalSearch Toggle the diagonal search on or off.
        %   Toggles diagonal search mode, specified as the Name-Value
        %   pair consisting of 'DiagonalSearch' and either 'on' or 'off'.
        %
        %   The DiagonalSearch property will enable or disable the search
        %   in diagonal direction. If it is off, the search only happens in
        %   four direction of the grid, and diagonals are skipped.
        %   Default: 'on'
        DiagonalSearch
    end

    properties(Hidden)

        %GCost Cost of moving between any two points in a grid.
        %   The cost of moving between any two points in a grid,
        %   specified as the comma-separated pair consisting of 'GCost' and
        %   one of the following predefined cost functions 'Euclidean',
        %   'Chebyshev', and 'Manhattan'.
        %
        %   Default: 'Euclidean'
        GCost

        %HCost Heuristic cost between a point and goal in a grid.
        %   The heuristic cost between a point and goal in a grid,
        %   specified as the comma-separated pair consisting of 'HCost' and
        %   one of the following predefined cost functions 'Euclidean',
        %   'Chebyshev', and 'Manhattan'.
        %
        %   Default: 'Euclidean'
        HCost
    end

    properties

        %GCostFcn Custom gcost functions.
        %   Custom gcost function, specified as the comma-separated pair
        %   consisting of 'GCostFcn' and a function handle. The function
        %   handle must accept 2 pose inputs and return a scalar of type
        %   double. Poses are assumed to be accepting grid coordinates.
        GCostFcn

        %HCostFcn Custom hcost function
        %   Custom hcost function, specified as the comma-separated pair
        %   consisting of 'HCostFcn' and a function handle. The function
        %   handle must accept 2 pose inputs and return a scalar of type
        %   double. Poses are assumed to be accepting grid coordinates.
        HCostFcn
    end

    properties  (Access = {?nav.algs.internal.InternalAccess})
        % OccupiedThreshold fetched from occupancyMap, to verify if a
        % is free or not.
        OccupiedThreshold
    end

    properties (Access = {?nav.algs.internal.InternalAccess})
        % Properties used internally for finding path from start to goal

        % Frame of planning. if '0', it denoted world frame.
        IsGrid=1

        % Default start position
        StartInGrid = [0 0];
        % Default goal position
        GoalInGrid = [0 0];

        % Stores the path indices from aStarCore algorithm
        Path
        % Stores the path position for occupancy maps
        PathXY
        PathInGrid
        % Stores the number of path output indices
        NumPathPoints = 0;

        % Stores the indices of nodes which were explored from aStarCore
        % algorithm
        NodesExploredIndices
        % Stores the position of nodes which were explored from aStarCore
        % algorithm for occupancy maps
        NodesExploredXY = [0 0];
        NodesExploredInGrid = [0 0];

        % Cost of path found by AStar algorithm
        PathCost
        % Number of nodes explored to find path
        NumNodesExplored = 0;

        % Stores node cost, so that its not calculated again
        NodeCostValue
        % Maximum number of nodes in a Occupancy map
        MaxNumNodes
        % Stores the index to position conversion
        IdPose
        PoseId

        % Default Limits of world coordinates for occupancy map
        Imax = 50;
        Jmax = 50;
        Kmax = 50;

        % Flag if any custom cost is used.
        UseCustomG =0;
        UseCustomH =0;

        % Flag for first run, useful for error out while 'SET' during
        % codegen
        isFirstRun=1;
    end
    properties(Dependent, Access=private)
        % Flag if tie breaker property is to be used or not.
        TieBreakConstant;
    end

    %%
    methods

        %% A Star Constructor
        function obj = plannerAStarGrid(varargin)
        % Check number of argument
            narginchk(0,7);

            %% Name Value parser
            % Creating struct with default values and parameters
            defaultStruct = struct('GCost','Euclidean','HCost','Euclidean',...
                                   'GCostFcn',@plannerAStarGrid.Euclidean,'HCostFcn',...
                                   @plannerAStarGrid.Euclidean,'TieBreaker','off','DiagonalSearch','on');

            if(nargin==0||isStringScalar(varargin{1})||ischar(varargin{1}))
                obj.Map = binaryOccupancyMap;
                initElement = 1;
            else
                obj.Map = varargin{1};
                initElement = 2;
            end

            % Parse name-value inputs (where the name-value inputs are
            % contained in varargin).

            % Create a parser struct 
            pstruct = coder.internal.parseParameterInputs(defaultStruct,...
                                                          struct(),varargin{initElement:nargin});

            % Verifying if 2 function is not provided for same cost.
            obj.validateCostInputs(nargin,varargin{initElement:end})

            %% Access parameter values using the parameterValue method.

            %Setting GCost and GCostFcn, and marking flag UseCustomG.
            gcostFc = coder.internal.getParameterValue(pstruct.GCostFcn,...
                                                       defaultStruct.GCostFcn,varargin{initElement:end});
            obj.GCostFcn = gcostFc;
            gcost = coder.internal.getParameterValue(pstruct.GCost,...
                                                     defaultStruct.GCost,varargin{initElement:end});
            obj.GCost = gcost;

            if(~strcmp(func2str(obj.GCostFcn),func2str(@plannerAStarGrid.Euclidean)))
                obj.UseCustomG=1;
            else
                obj.UseCustomG=0;
            end

            hcostFc = coder.internal.getParameterValue(pstruct.HCostFcn,...
                                                       defaultStruct.HCostFcn,varargin{initElement:end});
            obj.HCostFcn = hcostFc;
            hcost = coder.internal.getParameterValue(pstruct.HCost,...
                                                     defaultStruct.HCost,varargin{initElement:end});
            obj.HCost = hcost;
            if(~strcmp(func2str(obj.HCostFcn),func2str(@plannerAStarGrid.Euclidean)))
                obj.UseCustomH=1;
            else
                obj.UseCustomH=0;
            end

            % Setting occupied threshold from occupancyMap.
            if(~isa(obj.Map,'binaryOccupancyMap'))
                obj.OccupiedThreshold = obj.Map.OccupiedThreshold;
            else
                obj.OccupiedThreshold = 0.65;
            end

            % Setting TieBreaker.
            tieBreaker = coder.internal.getParameterValue(pstruct.TieBreaker,...
                                                          defaultStruct.TieBreaker,varargin{initElement:end});
            obj.TieBreaker = tieBreaker;

            % Setting DiagonalSearch
            diagSearch = coder.internal.getParameterValue(pstruct.DiagonalSearch,...
                                                          defaultStruct.DiagonalSearch,varargin{initElement:end});
            obj.DiagonalSearch = diagSearch;

            obj.isFirstRun =0;
        end

        %% SET functions and input validation
        function set.Map(obj,input)
        %Set function for the Map of plannerAStarGrid object.
            validateattributes(input,...
                               {'binaryOccupancyMap', ...
                                'occupancyMap'}, {'scalar'}, 'plannerAStarGrid', 'Map', 1);
            obj.Map = input;

            % Initialize dependent parameters like size, indices of
            % each grid and others.
            setInputState(obj);
        end
        function val = get.Map(obj)
            val = obj.Map;
        end

        % Setting the tiebreaker variable and accordingly modify the
        % multiplier a bit for calculating heuristics.
        function set.TieBreaker(obj,TieBreak)
            validStringsDist = {'on','off'};
            str = validatestring(TieBreak,validStringsDist,'');
            switch str
              case "on"
                obj.TieBreaker = 1;
              otherwise
                obj.TieBreaker = 0;
            end
        end
        function value = get.TieBreakConstant(obj)
            if obj.TieBreaker
                value = 1.07;
            else
                value = 1.0;
            end
        end

        % Setting the diagonal-search variable
        function set.DiagonalSearch(obj,diagVal)
            validStringsDist = {'on','off'};
            str = validatestring(diagVal,validStringsDist,'');
            switch str
              case "on"
                obj.DiagonalSearch = 1;
              otherwise
                obj.DiagonalSearch = 0;
            end
        end

        % Setter and getter function for HCostFcn.
        function set.HCostFcn(obj,input)
            validateCustomCostFunction(obj,input);
            verifyCodegenCompatibility(obj,'HCostFcn')
            setCustomH(obj,1);
            obj.HCostFcn = input;
        end
        function val = get.HCostFcn(obj)
            val = obj.HCostFcn;
        end

        % Setter and getter function for GCostFcn.
        function set.GCostFcn(obj,input)
            validateCustomCostFunction(obj,input);
            verifyCodegenCompatibility(obj,'GCostFcn')
            setCustomG(obj,1);
            obj.GCostFcn = input;
        end
        function val = get.GCostFcn(obj)
            val = obj.GCostFcn;
        end

        % Setter and getter function for HCost.
        function set.HCost(obj,input)
            verifyCodegenCompatibility(obj,'HCost')
            setCustomH(obj,0);
            [~,obj.HCost] = nav.internal.validation.validateAStarBuiltinCostFunction(input);
        end
        function val = get.HCost(obj)
        % Returning the HCost after truncating extra spaces.
            val = obj.HCost;
        end

        % Setter and getter function for GCost.
        function set.GCost(obj,input)
            verifyCodegenCompatibility(obj,'GCost')
            setCustomG(obj,0);
            [~,obj.GCost] = nav.internal.validation.validateAStarBuiltinCostFunction(input);
        end
        function val = get.GCost(obj)
        % Returning GCost after truncating extra spaces.
            val = obj.GCost;
        end

        % Getters to return user properties
        function val = get.Path(obj)
            val = obj.Path(1:obj.NumPathPoints,:);
        end
        function val = get.NodesExploredIndices(obj)
            val = obj.NodesExploredIndices(1:obj.NumNodesExplored,:);
        end
        function val = get.PathInGrid(obj)
            val = obj.PathInGrid(1:obj.NumPathPoints,:);
            if(isempty(val))
                % If no path found, it will return the first pose of
                % PathInGrid which is start coordinates.
                val =  obj.PathInGrid(1,:);
            end
        end
        function val = get.PathXY(obj)
            val = obj.PathXY(1:obj.NumPathPoints,:);
            if(isempty(val))
                % If no path found, it will return the first pose of
                % PathXY which is start coordinates.
                val = obj.PathXY(1,:);
            end
        end

        %% Public Functions
        function [path,debugInfo] = plan(obj,start, goal,varargin)
        % plan Find obstacle-free path between two points.
        %   [PATH,DEBUGINFO] = plan(plannerObj, start, goal) searches an
        %   obstacle-free shortest path between start and goal grids,
        %   specified as [row, col] in grid frame with origin at top left
        %   corner, using as input.
        %
        %   [PATH,DEBUGINFO] = plan(plannerObj, start, goal,'world')
        %   searches an obstacle-free shortest path between start and goal
        %   coordinates in world frame specified as [x, y] with origin at
        %   bottom left corner, using as input.
        %
        %   DEBUGINFO, as a second output that gives additional
        %   details regarding the planning solution.
        %   DEBUGINFO has the following fields:
        %
        %       PathCost:           Cost of path which is found.
        %
        %       NumNodesExplored:   Number of nodes which are expanded or
        %                           explored while searching for path.
        %
        %       GCostMatrix:        A 2d grid showcasing the gcost of each
        %                           explored node from the start.
        %
        %   The plan function also returns debugInfo with path cost, number
        %   of nodes explored and gcost for each explored node from start.
        %
        %   If there is no connectivity between the start and the goal
        %   point, it returns an empty array.
        %
        %   Example:
        %
        %       rng('default');
        %       % Create a binary occupancy map
        %       map = mapClutter("MapResolution",1);
        %
        %       % Create plannerAStarGrid object with map
        %       planner = plannerAStarGrid(map);
        %
        %       % Find path between two grid
        %       [pathRowCol,debugInfo] = plan(planner, [1 1], [50 50]);
        %
        %       % Visualize the map and path in a figure
        %       show(planner)
            narginchk(3,4);

            if(nargin==3)
                frameIn = 'grid';
            else
                validTypes = {'world','grid'};
                frameIn = validatestring(varargin{1},validTypes,'plan');
            end

            validateattributes(start,...
                               {'numeric'}, {'size',[1,2],'nonnan','nonempty','finite'}, 'plannerAStarGrid', 'Start');
            validateattributes(goal,...
                               {'numeric'}, {'size',[1,2],'nonnan','nonempty','finite'}, 'plannerAStarGrid', 'Goal');
            obj.IsGrid = 0;
            if(strcmp(frameIn,'grid'))
                obj.IsGrid = 1;
                % Validation of start and goal points for grid.
                coder.internal.errorIf((~all(start==floor(start))),'nav:navalgs:plannerastargrid:ValidateGridInput','Start');
                coder.internal.errorIf((~all(goal==floor(goal))),'nav:navalgs:plannerastargrid:ValidateGridInput','Goal');
            end

            % Converts 'world' frame points to 'grid' frame.
            if(~obj.IsGrid)
                startgrid = obj.Map.world2grid(double(start));
                goalgrid = obj.Map.world2grid(double(goal));
            else
                startgrid = double(start);
                goalgrid = double(goal);
            end

            map = obj.Map;
            % Validation of input size of start/goal.
            validateattributes(startgrid,{'double'},{'size',[1 2]});
            validateattributes(goalgrid,{'double'},{'size',[1 2]});

            validateStartGoal(obj,map,startgrid,goalgrid);
            obj.StartInGrid = startgrid(1,1:2);
            obj.GoalInGrid = goalgrid(1,1:2);

            % Create internal astar planner object
            astarInternal = initializeInternalPlanner(obj);            

            % Calling internal plannerAStarGrid plan function.
            runPlan(obj,astarInternal,obj.StartInGrid,obj.GoalInGrid);
            
            % Function to fetch essential debug informations.
            getEssentialOutput(obj,astarInternal);

            if(nargout>0)
                % Post processing of path
                path = getPathOutput(obj);           
            end
            if(nargout==2)
               GCostMatrix = getGCostMatrix(obj,astarInternal);
               debugInfo = struct('PathCost',obj.PathCost,'NumNodesExplored',...
                              obj.NumNodesExplored,'GCostMatrix',GCostMatrix); 
            end
        end

        function ax = show(obj,varargin)
        %show Visualize the planned path
        %   show(planner) plots the A* explored nodes and the
        %   planned path in the map.
        %
        %   AXHANDLE = show(planner) outputs the axes handle of the
        %   figure used to plot the path.
        %
        %   show(planner,'Name',Value) provided additional options
        %   specified by one or more name-value pairs. Options include:
        %
        %       'Parent'      - Axes handle for plotting the path.
        %
        %       'ExploredNodes'  - Displays the explored nodes, specified
        %                          as 'on' or 'off'
        %                          Default: 'on'
        %
        %   Example:
        %
        %       % Create a binary occupancy map
        %       map = binaryOccupancyMap(zeros(50,50));
        %
        %       % Create plannerAStarGrid object with map
        %       planner = plannerAStarGrid(map);
        %
        %       % Find path between two grid
        %       [pathRowCol,debugInfo] = plan(planner, [2 3], [28 46]);
        %
        %       % Visualize the map and path in a figure
        %       show(planner)
        %
        %       % Adding legend to plot
        %       legend

            % If called in code generation, throw incompatibility error
            coder.internal.errorIf(~coder.target('MATLAB'), 'nav:navalgs:prm:GraphicsSupportCodegen', 'show')

            % Name Value parser
            % Create parameter name cell array
            names = {'Parent','ExploredNodes'};

            % Create default value cell array
            defaults = {[],'On'};

            % Create a parser
            parser = robotics.core.internal.NameValueParser( ...
                names,defaults);

            % Parse name-value inputs (where the name-value inputs are
            % contained in varargin).
            parse(parser, varargin{1:nargin-1});
            showNodes = parameterValue(parser,'ExploredNodes');
            showNodes = validatestring(showNodes,{'on','off'},1);

            if(~isempty(parameterValue(parser, 'Parent')))
                % Validating input axis handle
                robotics.internal.validation.validateAxesUIAxesHandle(parameterValue(parser, 'Parent'));
            end
            parentHandle = parameterValue(parser, 'Parent');

            % Calls implementation function
            axHandle =  showPath(obj,showNodes,parentHandle);
            if (nargout>0)
                ax=axHandle;
            end
        end

    end

    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
        %getPropertyGroups Custom property group display
        %   This function overrides the function in the
        %   CustomDisplay base class.
            propList = struct("Map", obj.Map);

            if obj.TieBreaker
                propList.TieBreaker = 'on';
            else
                propList.TieBreaker = 'off';
            end

            if obj.DiagonalSearch
                propList.DiagonalSearch = 'on';
            else
                propList.DiagonalSearch = 'off';
            end

            [~,~,ValidStringsDist]=nav.internal.validation.validateAStarBuiltinCostFunction('Eu');
            if(obj.UseCustomG==1)
                propList.GCostFcn=obj.GCostFcn;
            else
                str = ValidStringsDist{obj.GCost};
                propList.GCost=str;
            end

            if(obj.UseCustomH==1)
                propList.HCostFcn=obj.HCostFcn;
            else
                str = ValidStringsDist{obj.HCost};
                propList.HCost=str;
            end

            propgrp = matlab.mixin.util.PropertyGroup(propList);

        end
    end

    methods(Access = private)

        function validateCustomCostFunction(~,costFcn)
        %validateCustomCostFunction Validates if the provided cost function
        %is default one or not, and verifies inputs and outputs.

            validateattributes(costFcn, {'function_handle'}, {'scalar'}, ...
                               'plannerAStarGrid', 'CustomCostFcn');
            inNum = nargin(costFcn);
            outNum = nargout(costFcn);
            if(inNum~=2||~(outNum==1||outNum==-1))
                coder.internal.error('nav:navalgs:plannerastargrid:InvalidCostFunctionHandle');
            end
        end

        function validateCostInputs(~,numIn,varargin)
        %validateCostInputs Validates if GCost and GCostFcn or HCost and HCostFcn,
        % both are not given as input simultaneously.

            gc = 0;
            hc = 0;
            for i=1:2:(numIn-1)
                name = validatestring(varargin{i},{'GCost','GCostFcn','HCost','HCostFcn','TieBreaker','DiagonalSearch'},'');
                if(strcmp(name,'GCost')||strcmp(name,'GCostFcn'))
                    gc = gc+1;
                elseif(strcmp(name,'HCost')||strcmp(name,'HCostFcn'))
                    hc = hc+1;
                end
            end
            if(hc>1)
                coder.internal.error('nav:navalgs:plannerastargrid:MultipleCostFunctionInput','HCost','HCostFcn');
            end
            if(gc>1)
                coder.internal.error('nav:navalgs:plannerastargrid:MultipleCostFunctionInput','GCost','GCostFcn');
            end
        end

        function setInputState(obj)
        %setInputState Initialize dependent parameters like size, indices
        %   of each grid and other parameters.
            map = obj.Map;
            size_map = map.GridSize;
            row = size_map(1);
            col = size_map(2);
            obj.Imax = row;
            obj.Jmax = col;
            obj.Kmax = 1;
            
            %Setting the maximum number of nodes to be explored by
            %AStar.
            MaxBaseGridNumNodes = (obj.Jmax*obj.Imax);
            obj.MaxNumNodes = MaxBaseGridNumNodes*obj.Kmax;

            % Variables to store the position [x,y,z] for corresponding
            % indices and their node cost.
            obj.IdPose = zeros(obj.MaxNumNodes,3);
            [obj.IdPose(:,1),obj.IdPose(:,2),obj.IdPose(:,3)] = ...
                ind2sub([obj.Imax obj.Jmax obj.Kmax],1:(obj.Imax*obj.Jmax*obj.Kmax));

            % Temporary variable to store poseId, which is later reshaped
            % and stored in PoseId.
            poseIdTemp = obj.IdPose(:,1) + (obj.IdPose(:,2) -1)*obj.Imax + ...
                (obj.IdPose(:,3) - 1)*obj.Imax*obj.Jmax;
            obj.PoseId = reshape(poseIdTemp,[obj.Imax obj.Jmax obj.Kmax]);
            obj.NodeCostValue = zeros(obj.MaxNumNodes,1)-1;
        end

        function verifyCodegenCompatibility(obj,arg)
        % If called in code generation, throw incompatibility error
            coder.internal.errorIf(~coder.target('MATLAB')&&obj.isFirstRun==0,'nav:navalgs:plannerastargrid:PropertySetInCodeGeneration', arg)
        end

        function setCustomG(obj,flag)
            obj.UseCustomG=flag;
        end
        function setCustomH(obj,flag)
            obj.UseCustomH=flag;
        end

        function [StartInGrid,GoalInGrid,startNode,goalNode] = validateStartGoal(obj,map,StartInGrid,GoalInGrid)
        %validateStartGoal Verification of Start and Goal is done by
        % binaryOccupancyMap while converting x,y coordinates to
        % grid coordinates.

            gridSize = map.GridSize();
            % Verifies if start and goal are within map bounds.
            [~,validIdx] = matlabshared.autonomous.internal.MapInterface.validateGridIndices(...
                [StartInGrid;GoalInGrid], gridSize, 'plan', 'startGoal');
            if any(~validIdx)
                if(~obj.IsGrid)
                    mapSizeX = map.XWorldLimits;
                    mapSizeY = map.YWorldLimits;
                    strX = 'X direction';
                    strY = 'Y direction';
                else
                    mapSizeX = [1 gridSize(1)];
                    mapSizeY = [1 gridSize(2)];
                    strX = 'rows';
                    strY = 'columns';
                end
                if coder.target('MATLAB')
                    error(message('nav:navalgs:plannerastargrid:CoordinateOutside', ...
                                  sprintf('%0.1f',mapSizeX(1)), sprintf('%0.1f',mapSizeX(2)),strX, ...
                                  sprintf('%0.1f',mapSizeY(1)), sprintf('%0.1f',mapSizeY(2)),strY));
                else
                    coder.internal.error('nav:navalgs:plannerastargrid:CoordinateOutside', ...
                                         coder.internal.num2str(mapSizeX(1)), coder.internal.num2str(mapSizeX(2)),strX, ...
                                         coder.internal.num2str(mapSizeY(1)), coder.internal.num2str(mapSizeY(2)),strY);
                end

            end

            % Fetching indices for start and goal.
            goalNode = obj.PoseId(GoalInGrid(1),GoalInGrid(2),1);
            startNode = obj.PoseId(StartInGrid(1),StartInGrid(2),1);

            %Checking for start and goal to be free.
            isStartOccupied = getNodeCostOMDefault(obj,startNode)==Inf;
            if isStartOccupied
                if coder.target('MATLAB')
                    error(message('nav:navalgs:plannerastargrid:OccupiedLocation', 'start'));
                else
                    coder.internal.error('nav:navalgs:plannerastargrid:OccupiedLocation', 'start');
                end
            end

            isGoalOccupied = getNodeCostOMDefault(obj,goalNode)==Inf;
            if isGoalOccupied
                if coder.target('MATLAB')
                    error(message('nav:navalgs:plannerastargrid:OccupiedLocation', 'goal'));
                else
                    coder.internal.error('nav:navalgs:plannerastargrid:OccupiedLocation', 'goal');
                end
            end
        end

        function ax = showPath(obj,showNodes,parentHandle)
        %showPath Implementation of show function
        %   showPath(planner) plots the A* explored nodes and the
        %   planned path in the map.

            % Assigning an empty axes handle for plotting.
            if(~isempty(parentHandle))
                axHandle = parentHandle;
            else
                axHandle = newplot;
            end

            % Plotting binaryOccupancyMap/occupancyMap.
            if(obj.IsGrid)
                imageHandle = obj.Map.show('grid','Parent',axHandle);
            else
                imageHandle = obj.Map.show('world','Parent',axHandle);
            end

             % Update title to 'AStar'
            axHandle.Title.String = message('nav:navalgs:plannerastargrid:FigureTitle').getString;

            % Adding manual colors to colormap
            % Path Color
            axHandle.Colormap(1,:)= validatecolor(plannerLineSpec.path{2});
            % Start Color
            axHandle.Colormap(3,:)= validatecolor(plannerLineSpec.start{2});
            % Goal Color
            axHandle.Colormap(4,:)= validatecolor(plannerLineSpec.goal{2});
            % Explored nodes Color
            axHandle.Colormap(2,:)= validatecolor(plannerLineSpec.tree{2});

            hold(axHandle, 'on');

            % Only return handle if user requested it.
            if nargout > 0
                ax = axHandle;
            end

            % If plan is not run NumNodesExplored will be 0, hence
            % skipping further plots
            if(obj.NumNodesExplored<=0)
                return
            end

            % Extract visualization data for explored nodes
            getExploredNodeOutput(obj);
            getPathOutput(obj);

            if(~obj.IsGrid)
                path = obj.PathXY;
                start = obj.Map.grid2world([obj.StartInGrid(1) obj.StartInGrid(2)]);
                goal = obj.Map.grid2world([obj.GoalInGrid(1) obj.GoalInGrid(2)]);
            else
                path = flip(obj.PathInGrid,2);
                start = flip(obj.StartInGrid,2);
                goal = flip(obj.GoalInGrid,2);
            end

            % Plotting Path, Start and Goal
            p1 = plot(axHandle,path(1:end,1),path(1:end,2),plannerLineSpec.path{:});

            p2 = plot(axHandle,start(1),start(2),plannerLineSpec.start{:});

            p3 = plot(axHandle,goal(1),goal(2), plannerLineSpec.goal{:});

            if(strcmp(showNodes,'on'))
                % Nodes Explored is marked as tree color. Setting the
                % RGB values for Nodes Indices.
                imageHandle.CData(obj.NodesExploredIndices)=axHandle.Colormap(2,1);
                imageHandle.CData(obj.NodesExploredIndices+prod(obj.Map.GridSize))=axHandle.Colormap(2,2);
                imageHandle.CData(obj.NodesExploredIndices+2*prod(obj.Map.GridSize))=axHandle.Colormap(2,3);
            end

            if(~isempty(obj.Path))
                % Path point grids are colored as path color. Setting the RGB
                % values for Path indices.
                imageHandle.CData(obj.Path)=axHandle.Colormap(1,1);
                imageHandle.CData(obj.Path+prod(obj.Map.GridSize))=axHandle.Colormap(1,2);
                imageHandle.CData(obj.Path+2*prod(obj.Map.GridSize))=axHandle.Colormap(1,3);
            end

            % Start grid is marked
            imageHandle.CData(obj.StartInGrid(1,1),obj.StartInGrid(1,2),:)=axHandle.Colormap(3,:);
            % Goal grid is marked
            imageHandle.CData(obj.GoalInGrid(1,1),obj.GoalInGrid(1,2),:)=axHandle.Colormap(4,:);

            % Setting legends.
            set(get(get(p1,'Annotation'),'LegendInformation'),...
               'IconDisplayStyle','off');
            set(get(get(p2,'Annotation'),'LegendInformation'),...
               'IconDisplayStyle','off');
            set(get(get(p3,'Annotation'),'LegendInformation'),...
               'IconDisplayStyle','off');

            plot(axHandle,NaN,NaN,'Marker','s','MarkerSize',10,...
                 'MarkerFaceColor',axHandle.Colormap(1,:),...
                 'MarkerEdgeColor',[0 0 0],'LineStyle','None' );
            plot(axHandle,NaN,NaN,'Marker','s','MarkerSize',10,...
                 'MarkerFaceColor',axHandle.Colormap(3,:),...
                 'MarkerEdgeColor',[0 0 0],'LineStyle','None' );
            plot(axHandle,NaN,NaN,'Marker','s','MarkerSize',10,...
                 'MarkerFaceColor',axHandle.Colormap(4,:),...
                 'MarkerEdgeColor',[0 0 0],'LineStyle','None' );
            plot(axHandle,NaN,NaN,'Marker','s','MarkerSize',10,...
                 'MarkerFaceColor',axHandle.Colormap(2,:),...
                 'MarkerEdgeColor',[0 0 0],'LineStyle','None' );

            % Setting the legends.
            if(strcmp(showNodes,'on'))
                legend(axHandle,'Path','Start','Goal','GridsExplored',...
                       'Location','southoutside','color','white','Visible','on',...
                       'Orientation','horizontal');
            else
                legend(axHandle,'Path','Start','Goal',...
                       'Location','southoutside','color','white','Visible','on',...
                       'Orientation','horizontal');
            end

            hold (axHandle,'off');
            legend(axHandle,'off');

            % Only return handle if user requested it.
            if nargout > 0
                ax = axHandle;
            end
        end

        function cost= getNodeCostOMDefault(obj,currentNode)
        % getNodeCostOMDefault will calculate the node cost for the
        % current node using the occupancy map.
        % It will return infinity if OM says the value is beyond the
        % cost for obstacle threshold.
            occMat = double(obj.Map.occupancyMatrix);
            cost = occMat(currentNode);

            cost= round(cost*10000)/10000;
            cost(cost>obj.OccupiedThreshold) = inf;
            cost(cost<=obj.OccupiedThreshold) = 0;
        end
    end
    methods (Access = {?nav.algs.internal.InternalAccess})
        function astarInternal = initializeInternalPlanner(obj)
        %initializeInternalPlanner Set the internal planner

            % Setting occupied threshold from occupancyMap.
            if(~isa(obj.Map,'binaryOccupancyMap'))
                obj.OccupiedThreshold = obj.Map.OccupiedThreshold;
            else
                obj.OccupiedThreshold = 0.65;
            end
            occMat = double(obj.Map.occupancyMatrix);
            if(size(size(occMat),2)==2)
                sizeMap =[size(occMat),1];
            else
                sizeMap =size(occMat);
            end
            %Initializing Input Arguments for internal plannerAStarGrid:
            m = round(occMat*10000)/10000;
            r = sizeMap(1);
            c = sizeMap(2);
            z = sizeMap(3);
            th = obj.OccupiedThreshold;
            res = obj.Map.Resolution;

            % Calling internal plannerAStarGrid to find path
            astarInternal = nav.algs.internal.plannerAStarGrid(m,r,c,z,...
                                                               th,res,'GCostFcn',obj.GCostFcn,'HCostFcn',obj.HCostFcn);

            % Setting cost functions when no custom cost functions are provided.
            if(obj.UseCustomH==0)
                astarInternal.setHeuristicMethod(obj.HCost);
            end
            if(obj.UseCustomG==0)
                astarInternal.setGCostMethod(obj.GCost);
            end

            astarInternal.setTieBreakerConstant(obj.TieBreakConstant);
            astarInternal.setDiagonalSearchFlag(obj.DiagonalSearch);
        end

        function runPlan(obj,astarInternal,start,goal)
            astarInternal.plan(start,goal);
        end
        function path = getEssentialOutput(obj,astarInternal)
            %getEssentialOutput Post processing of path and other outputs to extract useful information.
            path = double(astarInternal.getPathIndices);
            obj.NumPathPoints = height(path);
            nodesExIn = double(astarInternal.getNodesExploredIndices);
            obj.NumNodesExplored = double(astarInternal.getNumNodesExplored);
            if(obj.NumPathPoints==0)
                obj.PathCost = Inf;
                if coder.target('MATLAB')
                    warning(message('nav:navalgs:plannerastargrid:NoPathFound'));
                else
                    coder.internal.warning('nav:navalgs:plannerastargrid:NoPathFound');
                end
            else
                obj.PathCost = double(astarInternal.getPathCost);
            end
            
            if(~coder.target('MATLAB'))
                % Setting local parameters to be of variable size with max of number of grid nodes.
                coder.internal.assert(all(size(path)<=[obj.MaxNumNodes 1]),'nav:navalgs:plannerastargrid:AssertionFailedLessThan','NumPathNodes',obj.MaxNumNodes);
                obj.NumPathPoints = height(path);
                % Temporary variable of equivalent size as of class property, to be copied.
                pathTemp = zeros(obj.MaxNumNodes,1);
                pathTemp(1:obj.NumPathPoints,1) = path(1:obj.NumPathPoints,1);
                obj.Path= pathTemp;
    
                % Setting local parameters to be of variable size with max of number of grid nodes.
                nodesExIn = double(astarInternal.getNodesExploredIndices);
                obj.NumNodesExplored = double(astarInternal.getNumNodesExplored);
                coder.internal.assert(size(nodesExIn,1)<=obj.MaxNumNodes,'nav:navalgs:plannerastargrid:AssertionFailedLessThan','NodesExploredSize',obj.MaxNumNodes);
                coder.internal.assert(obj.NumNodesExplored<=obj.MaxNumNodes,'nav:navalgs:plannerastargrid:AssertionFailedLessThan','NumNodesExplored',obj.MaxNumNodes);
                % Temporary variable of equivalent size as of class property, to be copied.
                nodesExpTemp = zeros(obj.MaxNumNodes,1);
                nodesExpTemp(1:obj.NumNodesExplored,:)=nodesExIn;
                obj.NodesExploredIndices = nodesExpTemp;
            else
                obj.Path = path;
                obj.NodesExploredIndices = nodesExIn;
            end
            
        end

        function pathOut = getPathOutput(obj)
        %getPathOutput Post process the path output to give output in
        %required format.

            path = obj.Path;
            % Setting max size for class properties 
            obj.PathXY = NaN(obj.MaxNumNodes,2);
            obj.PathInGrid = NaN(obj.MaxNumNodes,2);

            if(isempty(path))               
                obj.PathCost = Inf;
                pathOut = [];
            else
                pose = obj.IdPose(obj.Path,:);
                % Temporary variable to copy to class property
                pathXYTemp = NaN(obj.MaxNumNodes,2);
                pathXYTemp(1:obj.NumPathPoints,:) = obj.Map.grid2world([pose(:,1:2)]);
                obj.PathXY = pathXYTemp;

                % Assigning the path and nodes explored.
                pathGridTemp = NaN(obj.MaxNumNodes,2);
                pathGridTemp(1:obj.NumPathPoints,:) = pose(:,1:2);
                obj.PathInGrid = pathGridTemp;
                if(obj.IsGrid)
                    pathOut = obj.PathInGrid;
                else
                    pathOut = obj.PathXY;
                end
            end
        end

        function GCostMatrix = getGCostMatrix(obj,astarInternal)
            %getGCostMatrix Post process and get GCostMatrix
            if ~coder.target('MATLAB')
                costMat = double(astarInternal.getGCostMatrix);
                costMat(costMat==-1)=Inf;
                GCostMatrix = reshape(costMat,[obj.Imax obj.Jmax obj.Kmax]);
            else
                GCostMatrix = inf([obj.Imax obj.Jmax obj.Kmax]);
                GCostMatrix(obj.NodesExploredIndices) = astarInternal.getGCostMatrix;
            end
        end

        function getExploredNodeOutput(obj)
        %getExploredNodeOutput Post process explored nodes data to required
        %format for visualization.

            nodesExIn = obj.NodesExploredIndices;
            pose = obj.IdPose(nodesExIn,:);

            if ~coder.target('MATLAB')
                % Allocating maximum memory for variables.
                obj.NodesExploredInGrid = NaN(obj.MaxNumNodes,2);
                neGridTemp = zeros(obj.MaxNumNodes,2);
                % Copying to temporary variable.
                neGridTemp(1:obj.NumNodesExplored,:)=pose(:,1:2);
                obj.NodesExploredInGrid = neGridTemp;
    
                % Allocating maximum memory for variables.
                obj.NodesExploredXY = NaN(obj.MaxNumNodes,2);
                neXYTemp = zeros(obj.MaxNumNodes,2);
                % Copying to temporary variable.
                neXYTemp(1:obj.NumNodesExplored,:) = obj.Map.grid2world([pose(:,1:2)]);
                obj.NodesExploredXY = neXYTemp;
            else
                obj.NodesExploredInGrid = pose(:,1:2);
                obj.NodesExploredXY = obj.Map.grid2world([pose(:,1:2)]);
            end
        end
    end
    methods(Static, Access = private)
        function dist = Euclidean(pose1,pose2)
        %Euclidean Finds the euclidean distance between the two poses.
            dist = sqrt(sum((pose1-pose2).^2));
        end
    end
    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'Map','Imax','Jmax','Kmax','MaxNumNodes'};
        end
    end
end

% LocalWords:  GCost gcost HCost hcost manhattan RRT testdata astar occgridcommon southoutside
