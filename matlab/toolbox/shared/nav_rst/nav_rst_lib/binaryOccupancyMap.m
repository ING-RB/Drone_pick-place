classdef (Sealed) binaryOccupancyMap < matlabshared.autonomous.internal.MapLayer & ...
    matlabshared.autonomous.core.internal.CustomDisplay
%BINARYOCCUPANCYMAP Create a binary occupancy grid map
%   BINARYOCCUPANCYMAP creates an occupancy grid map. Each cell has
%   a value representing the occupancy status of that cell. An occupied
%   location is represented as true (1) and a free location is false (0).
%
%   MAP = binaryOccupancyMap creates a 2D binaryOccupancy grid map object
%   occupying a world space of width(W) = 10, height(H) = 10, and with
%   Resolution = 1.
%
%   MAP = binaryOccupancyMap(W, H) creates a 2D binary
%   occupancy grid map object representing a world space of width(W) and
%   height(H) in meters. The default grid resolution is 1 cell per meter.
%
%   MAP = binaryOccupancyMap(W, H, RES) creates a binaryOccupancyMap
%   object with resolution(RES) specified in cells per meter.
%
%   MAP = binaryOccupancyMap(W, H, RES, 'world') creates a
%   binaryOccupancyMap object and  specifies the map size (W and H)
%   in the world coordinates. This is also the default value.
%
%   MAP = binaryOccupancyMap(M, N, RES, 'grid') returns a
%   binaryOccupancyMap object and specifies a grid size of M rows and N
%   columns. RES specifies the cells per meter resolution.
%
%   MAP = binaryOccupancyMap(P) creates a binaryOccupancyMap object
%   from the values in the matrix, P. The size of the grid matches
%   the matrix with each cell value interpreted from that matrix
%   location. Matrix, P, may contain any numeric type with zeros(0) and ones(1).
%
%   MAP = binaryOccupancyMap(P, RES) creates a binaryOccupancyMap
%   object from matrix, P, with RES specified in cells per meter.
%
%   MAP = binaryOccupancyMap(SOURCEMAP) creates a binaryOccupancyMap using
%   values from another binaryOccupancyMap object.
%
%   MAP = binaryOccupancyMap(SOURCEMAP, RES) creates a binaryOccupancyMap
%   using values from another binaryOccupancyMap object, but resamples the
%   matrix to have the specified resolution = RES.
%
%   MAP = binaryOccupancyMap(___, Name, Value, ...)  specifies additional attributes
%   of the binaryOccupancyMap object with each specified property name set to the 
%   specified value. Name must appear inside single quotes (''). You can 
%   specify several name-value pair arguments in any order as 
%   Name1,Value1,...,NameN,ValueN. Properties not specified retain their 
%   default values.
%
%   binaryOccupancyMap properties:
%       GridSize            - Size of the grid in [rows, cols] (number of cells)
%       LayerName           - The name of this binaryOccupancyMap instance
%       Resolution          - Grid resolution in cells per meter
%       XLocalLimits        - Min and max values of X in local frame
%       YLocalLimits        - Min and max values of Y in local frame
%       XWorldLimits        - Min and max values of X in world frame
%       YWorldLimits        - Min and max values of Y in world frame
%       GridLocationInWorld - Location of the grid in world coordinates
%       LocalOriginInWorld  - Location of the local frame in world coordinates
%       GridOriginInLocal   - Location of the grid in local coordinates
%       DefaultValue        - Default value for uninitialized map cells
%
%   binaryOccupancyMap methods:
%       copy            - Create a copy of the object
%       checkOccupancy  - Check occupancy status for one or more positions
%       getOccupancy    - Get occupancy value for one or more locations
%       grid2world      - Convert grid indices to world coordinates
%       grid2local      - Convert grid indices to local coordinates
%       inflate         - Inflate each occupied grid location
%       insertRay       - Insert rays from laser scan observation
%       local2grid      - Convert local coordinates to grid indices
%       local2world     - Convert local coordinates to world coordinates
%       move            - Move map in world frame
%       occupancyMatrix - Export binaryOccupancyMap as a matrix
%       raycast         - Compute cell indices along a ray
%       rayIntersection - Compute map intersection points of rays
%       setOccupancy    - Set occupancy value for one or more locations
%       show            - Display the binary occupancy map in a figure
%       syncWith        - Sync map with overlapping map
%       world2grid      - Convert world coordinates to grid indices
%       world2local     - Convert world coordinates to local coordinates
%
%   Example:
%
%       % Create a 2x2 empty map.
%       map = binaryOccupancyMap(2,2);
%
%       % Create a 10x10 empty map with resolution 20.
%       map = binaryOccupancyMap(10, 10, 20);
%
%       % Create a map from a matrix with resolution 20.
%       p = eye(100);
%       map = binaryOccupancyMap(p, 20);
%
%       % Check occupancy of the world location [0.3 0.2].
%       value = getOccupancy(map, [0.3 0.2]);
%
%       % Set world position [1.5 2.1] as occupied.
%       setOccupancy(map, [1.5 2.1], 1);
%
%       % Get the grid cell indices for world position [2.5 2.1].
%       ij = world2grid(map, [2.5 2.1]);
%
%       % Set the grid cell indices to unoccupied.
%       setOccupancy(map, [1 1], 0, 'grid');
%
%       % Set the grid cell indices using partial string argument.
%       setOccupancy(map, [1 1], 0, 'g');
%
%       % Display binary occupancy map in a figure.
%       show(map);
%
%   See also mobileRobotPRM, controllerPurePursuit.

%   Copyright 2014-2024 The MathWorks, Inc.

%#codegen

    properties(Access = protected, Constant)
        %ShowTitle Title for the show method
        ShowTitle = message('nav:navalgs:binaryoccgrid:FigureTitle').getString;
    end

    properties (Access = protected,Constant,Transient)
        LoadableProps = robotics.core.internal.properties(...
                    'binaryOccupancyMap',AccessLevel='allowed',...
                    AccessType='SetAccess',ShowHidden=true);
    end

    properties (Hidden,Transient)
        %ThemeListener Listener to update visualization when Theme is modified
        ThemeListener
    end
    
    methods %Getter and setter methods for map properties
        function grid = get.Grid(obj)
        %get.Grid Getter for occupancyMatrix property
            grid = obj.getOccupancy;
        end
    end

    methods
        function [occupied, validIds] = checkOccupancy(obj, varargin)
        %checkOccupancy Check occupancy status for one or more positions
        %   MAT = checkOccupancy(MAP) returns an N-by-M matrix, MAT, that
        %   contains the occupancy status of each location. Values of 0
        %   refer to obstacle-free cells, 1 refers to occupied cells, and
        %   -1 refer to cells outside map bounds.
        %
        %   VAL = checkOccupancy(MAP, LOCATIONS) returns an N-by-1 array, VAL, 
        %   that contains the occupancy status for N-by-2 array, LOCATIONS.
        %
        %   VAL = checkOccupancy(MAP, XY, 'world') returns an N-by-1 array,
        %   VAL, that contains the occupancy status for N-by-2 array, XY. Each 
        %   row of XY corresponds to a point with [X Y] world coordinates. 
        %
        %   VAL = checkOccupancy(MAP, XY, 'local') returns an N-by-1 array,
        %   VAL, that contains the occupancy status for N-by-2 array, XY. 
        %   Each row of XY corresponds to a point with [X Y] local coordinates. 
        %
        %   VAL = checkOccupancy(MAP, IJ, 'grid') returns an N-by-1 array,
        %   VAL, that contains the occupancy status for N-by-2 array, IJ. 
        %   Each row of IJ refers to a grid cell index [i j].
        %
        %   [VAL, VALIDPTS] = checkOccupancy(MAP, LOCATIONS, ___ ) returns an
        %   N-by-1 array, VAL, for N-by-2 array, LOCATIONS. If a second
        %   output argument is specified, checkOccupancy also returns an
        %   N-by-1 array of logicals indicating whether input LOCATIONS
        %   are inside map boundaries.
        %
        %   MAT = checkOccupancy(MAP, BOTTOMLEFT, MATSIZE) returns a matrix of
        %   occupancy status in a subregion defined by BOTTOMLEFT and MATSIZE.
        %   By default, BOTTOMLEFT is an [X Y] point in the world frame, and
        %   MATSIZE corresponds to the width and height of the region. XY
        %   locations outside the map limits return -1 for unknown.
        %   
        %   MAT = checkOccupancy(MAP, BOTTOMLEFT, MATSIZE, 'world') returns a 
        %   matrix of occupancy status. BOTTOMLEFT is an [X Y] point in the
        %   world frame, and MATSIZE corresponds to the width and height 
        %   of the region.
        %
        %   MAT = checkOccupancy(MAP, BOTTOMLEFT, MATSIZE, 'local') returns a 
        %   matrix of occupancy status. BOTTOMLEFT is an [X Y] point in the
        %   local frame, and MATSIZE corresponds to the width and height 
        %   of the region.
        %
        %   MAT = checkOccupancy(MAP, TOPLEFT, MATSIZE, 'grid') returns a 
        %   matrix of occupancy status. TOPLEFT is an [I J] index in the
        %   grid frame, and MATSIZE is a 2-element vector corresponding to 
        %   [rows cols]
        %
        %   Example:
        %       % Create an occupancy grid map.
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Check occupancy status of the world coordinate [0 0].
        %       value = checkOccupancy(map, [0 0]);
        %
        %       % Check occupancy status of multiple coordinates.
        %       [X, Y] = meshgrid(0:0.5:5);
        %       values = checkOccupancy(map, [X(:) Y(:)]);
        %
        %       % Check occupancy status of the grid cell [1 1].
        %       value = checkOccupancy(map, [1 1], 'grid');
        %
        %       % Check occupancy status of multiple grid cells.
        %       [I, J] = meshgrid(1:5);
        %       values = checkOccupancy(map, [I(:) J(:)], 'grid');
        %
        %   See also getOccupancy
        
            if nargin == 1
                occupied = obj.getValueAllImpl;
            else
                [ptIsValid, matSize, isGrid, isLocal] = obj.getParser('checkOccupancy', varargin{:});
                
                occupied = obj.checkOccupancyImpl(varargin{1}, matSize, isGrid, isLocal);
            end
            
            if nargout == 2
                % If second output argument is requested, return N-by-1
                % vector of logicals corresponding to the vector of xy or
                % ij points. Any points that lie outside of boundaries, or
                % that contain nan or non-finite coordinates return false.
                validIds = ptIsValid;
            end
        end
        
        function cpObj = copy(obj)
        %copy Create a copy of the object
        %   cpObj = copy(obj) creates a deep copy of the Binary
        %   Occupancy Grid object with the same properties.
        %
        %   Example:
        %       % Create a binary occupancy grid map of 10x10 world
        %       % representation.
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Create a copy of the object.
        %       cpObj = copy(map);
        %
        %       % Access the class methods from the new object.
        %       setOccupancy(cpObj,[2 4],true);
        %
        %       % Delete the handle object.
        %       delete(cpObj)

            if isempty(obj)
                cpObj = binaryOccupancyMap.empty(0,1);
            else
                % Create a new object with the same properties
                if isstruct(obj.SharedProperties)
                    obj.SharedProperties = matlabshared.autonomous.internal.SharedMapProperties(...
                        obj.SharedProperties);
                end
                cpObj = binaryOccupancyMap(obj);
            end
        end
        
        function [value, validIds] = getOccupancy(obj, varargin)
        %getOccupancy Get occupancy value for one or more locations
        %   MAT = getOccupancy(MAP) returns an N-by-M matrix of occupancy
        %   values.
        %
        %   VAL = getOccupancy(MAP, LOCATIONS) returns an N-by-1 array of
        %   occupancy values for N-by-2 array, LOCATIONS. Locations found
        %   outside the bounds of the map return map.DefaultValue.
        %
        %   VAL = getOccupancy(MAP, XY, 'world') returns an N-by-1 array of
        %   occupancy values for N-by-2 array XY in world coordinates.
        %   This is the default reference frame.
        %
        %   VAL = getOccupancy(MAP, XY, 'local') returns an N-by-1 array of
        %   occupancy values for N-by-2 array, XY. Each row of the
        %   array XY corresponds to a point with [X Y] local coordinates.
        %
        %   VAL = getOccupancy(MAP, IJ, 'grid') returns an N-by-1
        %   array of occupancy values for N-by-2 array IJ. Each row of
        %   the array IJ refers to a grid cell index [i j].
        %
        %   [VAL, VALIDPTS] = getOccupancy(MAP, LOCATIONS, ___ ) returns an
        %   N-by-1 array of occupancy values for N-by-2 array, LOCATIONS. If 
        %   a second output argument is specified, getOccupancy also returns
        %   an N-by-1 vector of logicals indicating whether input LOCATIONS
        %   are inside map boundaries.
        %
        %   MAT = getOccupancy(MAP, BOTTOMLEFT, MATSIZE) returns a matrix of
        %   occupancy values in a subregion defined by BOTTOMLEFT and MATSIZE.
        %   BOTTOMLEFT is the bottom left point of the square region in the
        %   world frame, given as [X Y], and MATSIZE is the size of the
        %   region given as [width, height].
        %   
        %   MAT = getOccupancy(MAP, BOTTOMLEFT, MATSIZE, 'world') returns a 
        %   matrix of occupancy values. BOTTOMLEFT is an [X Y] point in the
        %   world frame, and MATSIZE corresponds to the width and height 
        %   of the region.
        %
        %   MAT = getOccupancy(MAP, BOTTOMLEFT, MATSIZE, 'local') returns a
        %   matrix of occupancy values. BOTTOMLEFT is an [X Y] point in the
        %   local frame, and MATSIZE corresponds to the width and height
        %   of the region.
        %
        %   MAT = getOccupancy(MAP, TOPLEFT, MATSIZE, 'grid') returns a
        %   matrix of occupancy values. TOPLEFT is an [I J] index in the
        %   grid frame, and MATSIZE is a 2-element vector corresponding to
        %   [rows cols]
        %
        %   Example:
        %       % Create a binary occupancy grid map and occupancy values
        %       % for a position relative to the world frame.
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Get occupancy of the world coordinate [0 0].
        %       value = getOccupancy(map, [0 0]);
        %
        %       % Get occupancy of multiple coordinates.
        %       [X, Y] = meshgrid(0:0.5:5);
        %       values = getOccupancy(map, [X(:) Y(:)]);
        %
        %       % Get occupancy of the grid cell [1 1].
        %       value = getOccupancy(map, [1 1], 'grid');
        %
        %       % Get occupancy of multiple grid cells.
        %       [I, J] = meshgrid(1:5);
        %       values = getOccupancy(map, [I(:) J(:)], 'grid');
        %
        %   See also binaryOccupancyMap, setOccupancy
            
            if nargout == 2
                % If second output argument is requested, return N-by-1
                % vector of logicals corresponding to the vector of xy or
                % ij points. Any points that lie outside of boundaries, or
                % that contain nan or non-finite coordinates return false.
                [value, validIds] = obj.getMapData(varargin{:});
            else
            	value = obj.getMapData(varargin{:});
            end
        end

        function inflate(obj, varargin)
        %INFLATE Inflate each occupied grid location
        %   INFLATE(MAP, R) inflates each occupied position of the binary
        %   occupancy grid map by at least R meters. Each cell of the binary
        %   occupancy grid is inflated by number of cells which is the
        %   closest integer higher than the value MAP.Resolution*R.
        %
        %   INFLATE(MAP, R, 'grid') inflates each cell of the binary
        %   occupancy grid by R cells.
        %
        %   Note that the inflate function does not inflate the
        %   positions past the limits of the grid.
        %
        %   Example:
        %       % Create a binary occupancy grid and inflate map.
        %       bmat = eye(100);
        %       map = binaryOccupancyMap(bmat);
        %
        %       % Create a copy of the map for inflation.
        %       cpMap = copy(map);
        %
        %       % Inflate occupied cells using inflation radius in meters.
        %       inflate(cpMap, 0.1);
        %
        %       % Inflate occupied cells using inflation radius in number
        %       % of cells.
        %       inflate(cpMap, 2, 'grid');
        %
        %   See also binaryOccupancyMap, copy

            narginchk(2,3);
            inflatedGrid = nav.algs.internal.MapUtils.inflateGrid(obj, ...
                                                              obj.getValueAllImpl, varargin{:});
            obj.setValueMatrixImpl(inflatedGrid);
        end
        
        function move(obj, moveValue, varargin)
        %MOVE Move map in world frame
        %   MOVE(MAP, MOVEVALUE) moves the local origin of MAP to a location, 
        %   MOVEVALUE, given as an [x y] vector and updates the map limits.
        %   The MOVEVALUE is truncated based on the resolution of the map. 
        %   Values at locations within the previous limits and map limits.
        %
        %   MOVE(MAP,___,Name,Value) provides additional options specified
        %   by one or more Name,Value pair arguments. Name must appear
        %   inside single quotes (''). You can specify several name-value
        %   pair arguments in any order as Name1,Value1,...,NameN,ValueN:
        %
        %       'MoveType'      - A string that modifies the meaning of
        %                         MOVEVALUE:
        %
        %                             'Absolute' (default) - MAP moves its
        %                             local origin to discretized [x y] world 
        %                             frame position.
        %
        %                             'Relative' - MAP translates by
        %                             discrete [x y] distance, relative to
        %                             its original location in world frame.
        %
        %       'FillValue'     - A scalar value, FILLVALUE, for filling
        %                         unset locations. New locations that fall
        %                         outside the original map frame are
        %                         initialized with FILLVALUE.
        %
        %       'SyncWith'      - A binaryOccupancyMap object, SOURCEMAP,
        %                         for syncing unset locations. New locations
        %                         outside the original map frame that exist
        %                         in SOURCEMAP are initialized with values
        %                         in SOURCEMAP. New locations outside of
        %                         SOURCEMAP are set with the DefaultValue
        %                         property or specified FILLVALUE.
        %
        %   Example:
        %       % Create a binaryOccupancyMap.
        %       map = binaryOccupancyMap(eye(20),2);
        %
        %       % Try to move the map to [1.25 3.75].
        %       move(map, [1.25 3.75])
        %
        %           % NOTE: Resolution = 2, so the map moves to discrete
        %           % world location [1 3.5]
        %
        %       % Translate the map by XY distance [5 5] relative to world 
        %       % frame.
        %       move(map, [5 5], 'MoveType', 'Relative')
        %
        %       % Translate the map by [0 3] and fill new locations with a
        %       % value of 1.
        %       move(map, [0 3], 'MoveType', 'Relative', 'FillValue', 1)
        %
        %       % Move the map back to [0 0] and fill new locations with
        %       % data from another map where the frames overlap.
        %       worldMap = binaryOccupancyMap(randi([0 1],100,200))
        %       move(map, [0 0], 'SyncWith', worldMap)
        %
        %       % Move the map to [-1 -1], and fill new locations with
        %       % data from another map. Fill all other new locations that
        %       % do not overlap with a value of 1.
        %       move(map, [-1 -1], 'SyncWith', worldMap, 'FillValue', 1)

        % Parse inputs
            [moveValue, sourceMap, fillVal] =  obj.moveParser(moveValue, varargin{:});

            % Call internal move command
            move@matlabshared.autonomous.internal.MapLayer(obj, moveValue, ...
                                                           'DownSamplePolicy','Max', 'FillWith', fillVal,'SyncWith',sourceMap);
        end
        
        function mat = occupancyMatrix(obj)
        %OCCUPANCYMATRIX Export binaryOccupancyMap as a matrix
        %   MAT = OCCUPANCYMATRIX(MAP) returns occupancy values stored
        %   in the binary occupancy grid object as a logical matrix of
        %   size GridSize.
        %
        %   Example:
        %       % Create an occupancy grid.
        %       map = binaryOccupancyMap(eye(10));
        %
        %       % Export occupancy grid as a matrix.
        %       mat = occupancyMatrix(map);
        %
        %   See also getOccupancy

            mat = obj.getValueAllImpl;
        end
        
        function insertRay(obj, varargin)
        %insertRay Insert rays from laser scan observation
        %   insertRay(MAP, POSE, SCAN, MAXRANGE) inserts range sensor
        %   readings in the occupancy grid map. POSE is a 3-element vector
        %   representing sensor pose [X, Y, THETA] in the world coordinate
        %   frame, SCAN is a scalar lidarScan object with range sensor
        %   readings, and MAXRANGE is the maximum range of the sensor.
        %   The cells along the ray except the end points are observed
        %   as obstacle-free and updated with probability of 0.
        %   The cells touching the end point are observed as occupied
        %   and updated with probability of 1. NaN values in the SCAN
        %   ranges are ignored. SCAN ranges above MAXRANGE are truncated
        %   and the end points are not updated for MAXRANGE readings.
        %
        %   insertRay(MAP, POSE, RANGES, ANGLES, MAXRANGE) allows
        %   you to pass range sensor readings as RANGES and ANGLES. The
        %   input ANGLES are in radians.
        %
        %   insertRay(MAP, STARTPT, ENDPTS) inserts cells between the
        %   line segments STARTPT and ENDPTS. STARTPT is 2-element vector
        %   representing the start point [X,Y] in the world coordinate frame.
        %   ENDPTS is N-by-2 array of end points in the world coordinate
        %   frame. The cells along the line segment except the end points
        %   are updated with probability of 0 and the cells touching the
        %   end point are updated with probability of 1.
        %
        %   Example:
        %       % Create a map
        %       map = binaryOccupancyMap(10,10,20);
        %
        %       % Insert two rays
        %       scan = lidarScan([5, 6], [pi/4, pi/6]);
        %       insertRay(map, [5,5,0], scan, 20);
        %
        %       % Visualize inserted rays
        %       show(map);
        %
        %       % Insert a line segment
        %       insertRay(map, [0,0], [3,3]);
        %
        %       % Visualize inserted ray
        %       show(map);
        %
        %   See also binaryOccupancyMap, raycast

            narginchk(3,5)

            gSize     = obj.SharedProperties.GridSize;
            res       = obj.SharedProperties.Resolution;
            gLocWorld = obj.SharedProperties.GridLocationInWorld;
            coder.internal.prefer_const(res);
            coder.internal.prefer_const(gSize);

            % Parse inputs to function
            [startPt, endPt, updateValues, maxRange, rangeIsMax] = ...
                nav.algs.internal.MapUtils.parseInsertRayInputs(obj, [0 1], varargin{:});
            coder.internal.prefer_const(maxRange);

            numRays = size(endPt,1);
            
            % Process rays in batches. Attempts to limit the size of allocated 
            % midpoint array <= 10MB. If a single ray is large enough to
            % exceed 10MB, insertRay processes the rays individually. See
            % raycastInternal for memory allocation rationale. To be 
            % conservative, the calculation assumes indices are stored as
            % 8-byte doubles.
            if coder.internal.isConstTrue(maxRange < max(gSize/res))
                maxRayLength = maxRange;
            else
                maxRayLength = max(gSize*res);
            end
            maxRaysPerIteration = ceil((10*1024*1024)/((4+3*maxRayLength)*2*8));

            if numRays == 0
                return;
            else
                startIdx = 1;
                while startIdx <= numRays
                    endIdx = min(numRays,startIdx+maxRaysPerIteration);
            
                    if ~isempty(rangeIsMax)
                        [endPts, middlePts] = nav.algs.internal.raycastCells(startPt, endPt(startIdx:endIdx,:), ...
                                                 gSize(1), gSize(2), res, gLocWorld, rangeIsMax);
                    else
                        [endPts, middlePts] = nav.algs.internal.raycastCells(startPt, endPt(startIdx:endIdx,:), ...
                                                 gSize(1), gSize(2), res, gLocWorld);
                    end

                    % Mark cells that were passed through as free
                    if ~isempty(middlePts)
                        obj.setValueAtIndicesInternal(middlePts, repmat(updateValues(1),size(middlePts,1),1));
                    end

                    % Mark cells with collisions as occupied
                    if ~isempty(endPts)
                        obj.setValueAtIndicesInternal(endPts, repmat(updateValues(2),size(endPts,1),1));
                    end
                    
                    startIdx = endIdx+1;
                end
            end
        end
        
        function [endPts, middlePts] = raycast(obj, varargin)
        %RAYCAST Compute cell indices along a ray
        %   [ENDPTS, MIDPTS] = RAYCAST(MAP, POSE, RANGE, ANGLE) returns
        %   cell indices of all cells traversed by a ray emanating from
        %   POSE at an angle ANGLE with length equal to RANGE. POSE is
        %   a 3-element vector representing robot pose [X, Y, THETA] in
        %   the world coordinate frame. ANGLE and RANGE are scalars.
        %   The ENDPTS are indices of cells touched by the
        %   end point of the ray. MIDPTS are all the cells touched by
        %   the ray excluding the ENDPTS.
        %
        %   [ENDPTS, MIDPTS] = RAYCAST(MAP, P1, P2) returns
        %   the cell indices of all cells between the line segment
        %   P1=[X1,Y1] to P2=[X2,Y2] in the world coordinate frame.
        %
        %   For faster insertion of range sensor data, use the insertRay
        %   method with an array of ranges or an array of end points.
        %
        %   Example:
        %       % Create a map
        %       map = binaryOccupancyMap(10, 10, 20);
        %
        %       % compute cells along a ray
        %       [endPts, midPts] = raycast(map, [5,3,0], 4, pi/3);
        %
        %       % Change occupancy cells to visualize
        %       setOccupancy(map, endPts, true, 'grid');
        %       setOccupancy(map, midPts, false, 'grid');
        %
        %       % Compute cells along a line segment
        %       [endPts, midPts] = raycast(map, [2,5], [6,8]);
        %
        %       % Change occupancy cells to visualize
        %       setOccupancy(map, endPts, true, 'grid');
        %       setOccupancy(map, midPts, false, 'grid');
        %
        %       % Visualize the raycast output
        %       show(map);
        %
        %   See also binaryOccupancyMap, insertRay

            [endPts, middlePts] = nav.algs.internal.MapUtils.raycast(obj, varargin{:});
        end
        
        function collisionPt = rayIntersection(obj, pose, angles, maxRange)
        %rayIntersection Compute map intersection points of rays
        %   PTS = rayIntersection(MAP, POSE, ANGLES, MAXRANGE) returns
        %   collision points PTS in the world coordinate frame for
        %   rays emanating from POSE. PTS is an N-by-2 array of points.
        %   POSE is a 1-by-3 array of sensor pose [X Y THETA] in the world
        %   coordinate frame. ANGLES is an N-element vector of angles
        %   at which to get ray intersection points. MAXRANGE is a
        %   scalar representing the maximum range of the range sensor. If
        %   there is no collision up-to the maximum range then [NaN NaN]
        %   output is returned.
        %
        %   Example:
        %       % Create a map
        %       map = binaryOccupancyMap(eye(10));
        %
        %       % Set occupancy of the world coordinate (5, 5)
        %       setOccupancy(map, [5 5], 0.5);
        %
        %       % Get collision points
        %       collisionPts = rayIntersection(map, [0,0,0], [pi/4, pi/6], 10);
        %
        %       % Visualize the collision points
        %       show(map);
        %       hold on;
        %       plot(collisionPts(:,1),collisionPts(:,2) , '*')
        %       hold off;
        %
        %   See also binaryOccupancyMap, raycast

            narginchk(4,5);

            collisionPt = nav.algs.internal.MapUtils.rayIntersection(obj,...
                                                              obj.getValueAllImpl, pose, angles, maxRange);
        end
        
        function validIds = setOccupancy(obj, varargin)
        %setOccupancy Set occupancy value for one or more locations
        %   setOccupancy(MAP, INPUTMATRIX) sets the MAP occupancy values to
        %   the values in INPUTMATRIX. The matrix must be the same size as
        %   GridSize property of MAP.
        %
        %   setOccupancy(MAP, LOCATIONS, VAL) assigns each element of the
        %   N-by-1 vector, VAL to the coordinate position of the
        %   corresponding row of the N-by-2 array, LOCATIONS. Locations
        %   found outside map boundaries are ignored.
        %
        %   setOccupancy(MAP, XY, VAL, 'world') assigns the occupancy
        %   values of the N-element array, VAL, to each location specified
        %   in the N-by-2 [x y] matrix, XY. Locations are specified in
        %   world coordinates. This is the default.
        %
        %   setOccupancy(MAP, XY, VAL, 'local') assigns the occupancy
        %   values of the N-element array, VAL, to each location specified
        %   in the N-by-2 [x y] matrix, XY. Locations are specified in
        %   local coordinates.
        %
        %   setOccupancy(MAP, IJ, VAL, 'grid') assigns the occupancy
        %   values of the N-element array, VAL, to each cell specified
        %   in the N-by-2 [i j] matrix, IJ.
        %
        %   VALIDPTS = setOccupancy(MAP, LOCATIONS, VAL, ___ ) assigns each
        %   element of the N-by-1 vector, VAL to the coordinate position of the
        %   corresponding row of the N-by-2 array, LOCATIONS. If an output
        %   argument is specified, setOccupancy returns an N-by-1 vector of
        %   logicals indicating whether the input points were inside the
        %   map boundaries.
        %
        %   setOccupancy(MAP, BOTTOMLEFT, INPUTMAT) assigns an N-by-M occupancy
        %   matrix, INPUTMAT, to the MAP. The subregion begins in the [I J]
        %   cell corresponding to [X Y] world position, BOTTOMLEFT, and
        %   extends [N M] rows/cols in the -I +J direction.
        %
        %   setOccupancy(MAP, BOTTOMLEFT, INPUTMAT, 'world') assigns an
        %   N-by-M occupancy matrix, INPUTMAT, to the MAP. The subregion
        %   begins in the [I J] cell corresponding to [X Y] world position,
        %   BOTTOMLEFT, and extends [N M] rows/cols in the -I +J direction.
        %
        %   setOccupancy(MAP, BOTTOMLEFT, INPUTMAT, 'local') assigns an
        %   N-by-M occupancy matrix, INPUTMAT, to the MAP. The subregion
        %   begins in the [I J] cell corresponding to [X Y] local position,
        %   BOTTOMLEFT, and extends [N M] rows/cols in the -I +J direction.
        %
        %   setOccupancy(MAP, TOPLEFT, INPUTMAT, 'grid') assigns an
        %   N-by-M occupancy matrix, INPUTMAT, to the MAP. The subregion
        %   begins in the [I J] cell, TOPLEFT, and extends [N M] rows/cols
        %   in the +I +J direction.
        %
        %   Example:
        %       % Create a map and set occupancy values for a position.
        %       map = binaryOccupancyMap(10, 10);
        %
        %       % Set occupancy of the world coordinate [0 0].
        %       setOccupancy(map, [0 0], 1);
        %
        %       % Set occupancy of multiple coordinates.
        %       [X, Y] = meshgrid(0:0.5:5);
        %       values = ones(numel(X),1);
        %       setOccupancy(map, [X(:) Y(:)], values);
        %
        %       % Set occupancy of the grid cell [1 1].
        %       setOccupancy(map, [1 1], 1, 'grid');
        %
        %       % Set occupancy of multiple grid cells to the same value
        %       [I, J] = meshgrid(1:5);
        %       setOccupancy(map, [I(:) J(:)], 1, 'grid');
        %
        %       % Set occupancy of multiple grid cells.
        %       [I, J] = meshgrid(1:5);
        %       values = randi([0 1], numel(I), 1);
        %       setOccupancy(map, [I(:) J(:)], values, 'grid');
        %
        %   See also getOccupancy
            
            if nargout == 1
                % If output argument is requested, return N-by-1
                % vector of logicals corresponding to the vector of xy or
                % ij points. Any points that lie outside of boundaries, or
                % that contain nan or non-finite coordinates return false.
                validIds = obj.setMapData(varargin{:});
            else
                obj.setMapData(varargin{:})
            end
        end
        
        function imageHandle = show(obj, varargin)
        %SHOW Display the binary occupancy map in a figure
        %   SHOW(MAP) displays the binaryOccupancyMap object, MAP, in the
        %   current axes with the axes labels representing the world
        %   coordinates.
        %
        %   SHOW(MAP, 'local') displays the binaryOccupancyMap object, MAP,
        %   in the current axes with the axes of the figure representing
        %   the local coordinates of the MAP. The default input is 'world',
        %   which shows the axes in world coordinates.
        %
        %   SHOW(MAP, 'grid') displays the binaryOccupancyMap object, MAP,
        %   in the current axes with the axes of the figure representing
        %   the grid indices.
        %
        %   HIMAGE = SHOW(MAP, ___) returns the handle to the image
        %   object created by show.
        %
        %   SHOW(MAP,___,Name,Value) provides additional options specified
        %   by one or more Name,Value pair arguments. Name must appear
        %   inside single quotes (''). You can specify several name-value
        %   pair arguments in any order as Name1,Value1,...,NameN,ValueN:
        %
        %       'Parent'        - Axes to plot the map, specified as an axes handle.
        %
        %                         Default: gca
        %
        %       'FastUpdate'    - Boolean value used to speed up show method
        %                         for existing map plots. If you have
        %                         previously plotted your map on the axes,
        %                         specify 1 to perform a lightweight update
        %                         to the map in the figure.
        %
        %                         Default: 0 (regular update)
        %
        %   Example:
        %       % Create a map.
        %       map = binaryOccupancyMap(eye(5));
        %
        %       % Display the occupancy with axes showing the world
        %       % coordinates.
        %       gh = show(map);
        %
        %       % Display the occupancy with axes showing the grid indices.
        %       gh = show(map, 'grid');
        %
        %       % Display the occupancy with axes showing the world
        %       % coordinates and specify a parent axes.
        %       fh = figure;
        %       ah = axes('Parent', fh);
        %       gh = show(map, 'world', 'Parent', ah);
        %
        %   See also binaryOccupancyMap

            [axHandle, isGrid, isLocal, fastUpdate] = ...
                nav.algs.internal.MapUtils.showInputParser(varargin{:});
            [axHandle, imghandle, fastUpdate] = ...
                nav.algs.internal.MapUtils.showGrid(obj, axHandle, isGrid, isLocal, fastUpdate);

            if ~fastUpdate
                axHandle.Title.String = obj.ShowTitle;
            end

            % Only return handle if user requested it.
            if nargout > 0
                imageHandle = imghandle;
            end
        end
        
        function syncWith(obj, sourceMap)
        %SYNCWITH Sync map with overlapping map
        %
        %   syncWith(MAP,SOURCEMAP) updates MAP with data from another
        %   binaryOccupancyMap, SOURCEMAP. Locations in MAP that are also
        %   found in SOURCEMAP are updated, all other cells retain their
        %   current values. 
        %
        %   Example:
        %       % Set a localMap's initial position and sync its data with
        %       % a world map
        %
        %       % Create a 100x100 world map.
        %       worldMap = binaryOccupancyMap(eye(100));
        %
        %       % Create a 10x10 local map.
        %       localMap = binaryOccupancyMap(10,10);
        %
        %       % Set the localMap's local-frame to [45 45].
        %       localMap.LocalOriginInWorld = [45 45];
        %
        %       % Sync localMap's data with worldMap.
        %       syncWith(localMap, worldMap)
        %
        %       % Set a localMap's initial position partially outside the
        %       % worldMap limits and sync.
        %
        %       localMap.LocalOriginInWorld = [-5 -5];
        %       syncWith(localMap, worldMap);
        %
        %   See also move

        % Validate source-map type
            validateattributes(sourceMap,{'binaryOccupancyMap'},{'scalar'},'syncWith','sourceMap');

            % Write data from overlapping region of sourceMap into map
            obj.writeFromOtherMap(sourceMap);
        end
    end
    
    methods (Hidden)
        function [value, ptIsValid] = getMapData(obj, varargin)
            if nargin == 1
                value = obj.getValueAllImpl;
            else
                [ptIsValid, matSize, isGrid, isLocal] = obj.getParser('getOccupancy', varargin{:});
                
                if isempty(matSize)
                    % Individual points
                    if isGrid
                        value = obj.getValueAtIndicesInternal(varargin{1});
                    elseif isLocal
                        value = obj.getValueLocalAtIndicesImpl(varargin{1});
                    else
                        value = obj.getValueWorldAtIndicesImpl(varargin{1});
                    end
                else
                    % Block syntax
                    if isGrid
                        value = obj.getValueGridBlockImpl(varargin{1}, matSize(1), matSize(2));
                    elseif isLocal
                        value = obj.getValueLocalBlockImpl(varargin{1}, matSize(1), matSize(2));
                    else
                        value = obj.getValueWorldBlockImpl(varargin{1}, matSize(1), matSize(2));
                    end
                end
            end
        end
        
        function validIds = setMapData(obj, varargin)
            [values, ptIsValid, isMat, isGrid, isLocal] = obj.setParser('setOccupancy', varargin{:});
            
            if nargin == 2
                obj.setValueMatrixImpl(values);
            elseif ~isMat
                nav.algs.internal.MapUtils.validateOccupancyValues(values(:), size(varargin{1}, 1), 'setOccupancy', 'VAL', 2);
                % Individual points
                if isGrid
                    obj.setValueAtIndicesInternal(varargin{1}, varargin{2}(:));
                elseif isLocal
                    obj.setValueAtIndicesLocalImpl(varargin{1}, varargin{2}(:));
                else
                    obj.setValueAtIndicesWorldImpl(varargin{1}, varargin{2}(:));
                end
            else
                % Block syntax
                if isGrid
                    obj.setBlockInternal(varargin{1}, varargin{2});
                elseif isLocal
                    obj.setValueLocalBlockImpl(varargin{1}, varargin{2});
                else
                    obj.setValueWorldBlockImpl(varargin{1}, varargin{2});
                end
            end
            
            if nargout == 1
                validIds = ptIsValid;
            end
        end
    end
    
    methods (Access = protected)
        function copyImpl(cpObj, obj)
        % Copies properties that were not set during construction

        % Set internal grid data
            cpObj.DefaultValue = obj.DefaultValue;
            cpObj.ImageTag = 'binaryOccupancyMap';
            if (cpObj.Resolution == obj.Resolution)
                copyImpl@matlabshared.autonomous.internal.MapLayer(cpObj, obj);
            end
        end
        
        function postConstructSet(obj, varargin)
        %postConstructSet Set additional properties after internal construction
        %
        %   This function is called after construction to set the occupancy
        %   values.
        
            numCtorIn = numel(varargin);
            if numCtorIn >= 1 && (isnumeric(varargin{1}) || islogical(varargin{1}))
                if numCtorIn == 1
                    obj.setOccupancy(varargin{1});
                elseif numCtorIn > 2 && ~(isnumeric(varargin{2}) || islogical(varargin{2}))
                    obj.setOccupancy(varargin{1});
                elseif ~isscalar(varargin{1}) || ~coder.internal.isConst(size(varargin{1}))
                    obj.setOccupancy(varargin{1});
                end
            end
        end
    end

    methods (Access = {?binaryOccupancyMap, ?nav.algs.internal.InternalAccess})
        function updateValues = validateInverseModel(~, updateValues)
        %validateInverseModel Overwritable validation function for inverseModel

        % inverseModelLogodds does not apply to binaryOccupancyMap's
        % insertRay function. This validation catches all code-paths
        % where a user tries to use insertRay syntaxes that include this
        % optional parameter and errors with 'Too Many Inputs'
            narginchk(0,0)
        end
    end

    methods (Access = {?matlabshared.autonomous.internal.MapInterface, ...
                       ?nav.algs.internal.InternalAccess})
        function occupied = checkOccupancyImpl(obj, locs, matSize, isGrid, isLocal)
            if isempty(matSize)
                % Individual points
                if isGrid
                    occupied = obj.getValueAtIndicesInternal(locs,-1);
                elseif isLocal
                    occupied = obj.getValueLocalAtIndicesImpl(locs,-1);
                else
                    occupied = obj.getValueWorldAtIndicesImpl(locs,-1);
                end
            else
                % Block syntax
                if isGrid
                    occupied = obj.getValueGridBlockImpl(locs, matSize(1), matSize(2),-1);
                elseif isLocal
                    occupied = obj.getValueLocalBlockImpl(locs, matSize(1), matSize(2),-1);
                else
                    occupied = obj.getValueWorldBlockImpl(locs, matSize(1), matSize(2),-1);
                end
            end
        end
    end
    
    methods (Static)
        function obj = loadobj(s)
        %LOADOBJ Load saved binaryOccupancyMap
            if (isstruct(s))
                if isfield(s,'XWorldLimits')
                    width  = diff(s.XWorldLimits);
                    height = diff(s.YWorldLimits);
                else
                    width  = s.GridSize(2)/s.Resolution;
                    height = s.GridSize(1)/s.Resolution;
                end
                obj = binaryOccupancyMap(width, height, s.Resolution);
                props = obj.LoadableProps;
                fields = fieldnames(s);
                for i = 1:length(fields)
                    if any(strcmp(fields{i},props))
                        obj.(fields{i}) = s.(fields{i});
                    end
                end
                if isfield(s,'Grid') && ~isempty(s.Grid)
                    % Backwards compatibility with pre-R2019b maps
                    obj.setOccupancy(s.Grid);
                end
            else
                obj = s;
            end
        end
    end

    properties (Access = {?nav.algs.internal.InternalAccess, ...
                          ?nav.algs.internal.GridAccess})
        Grid
    end

    properties (Access = {?nav.algs.internal.InternalAccess, ...
                          ?nav.algs.internal.MapUtils, ...
                          ?nav.algs.internal.GridAccess})
        %AxesTag Axes tag used for quick show updates
        AxesTag = 'binaryOccupancyMap';

        %ImageTag Image tag used for quick show update
        ImageTag = 'binaryOccupancyMap';
    end
    
    methods (Static, Hidden)
        function name = getDefaultLayerName()
        %getDefaultLayerName Returns the Compile-time constant default name for binaryOccupancyMap objects
            name = 'binaryLayer';
        end
        
        function defaultValue = getDefaultDefaultValue()
        %getDefaultDefaultValue Returns the Compile-time constant DefaultValue for binaryOccupancyMap objects
            defaultValue = false(1);
        end
        
        function [nvPairs, useGridSizeInit, rows, cols, sz, depth] = parseGridVsMatrix(className, parseFcn, varargin)
        %parseGridVsMatrix Calculates size of matrix based on inputs and NV-pairs
            [nvPairs, useGridSizeInit, rows, cols, sz, depth] = nav.algs.internal.MapUtils.parseGridVsMatrix(className, parseFcn, varargin{:});
        end
        
        function validationFcn = getValDefaultValueFcn(methodName)
        %getValDefaultValueFcn Validator for DefaultValue
            validationFcn = @(name,val)validateattributes(val,{'numeric','logical'},{'nonempty','scalar','binary'},methodName,name);
        end
        
        function validators = getValidators(methodName)
        %getValidators Returns validators for associated function calls
            
            invalidNV = binaryOccupancyMap.getInvalidNVPairFcn(methodName);
            validators = struct(...
                'Resolution',         {{1, binaryOccupancyMap.getValResolutionFcn(methodName)}},...
                'DefaultValue',       {{0, invalidNV}},...
                'GridOriginInLocal',  {{1, binaryOccupancyMap.getValRefFrameValueFcn(methodName)}},...
                'LocalOriginInWorld', {{1, binaryOccupancyMap.getValRefFrameValueFcn(methodName)}},...
                'LayerName',          {{1, binaryOccupancyMap.getValLayerNameFcn(methodName)}},...
                'GetTransformFcn',    {{0, invalidNV}},...
                'SetTransformFcn',    {{0, invalidNV}}, ...
                'UseGPU',             {{0, invalidNV}});
        end
    end
    
    methods (Hidden, Access = protected)
        function group = getPropertyGroups(~)
            group = matlab.mixin.util.PropertyGroup;
            group.PropertyList = {...
                'LayerName', ...
                'DataType', ...
                'DefaultValue', ...
                'Resolution', ...
                'GridSize', ...
                'GridLocationInWorld', ...
                'GridOriginInLocal', ...
                'LocalOriginInWorld', ...
                'XLocalLimits', ...
                'YLocalLimits', ...
                'XWorldLimits', ...
                'YWorldLimits'};
        end
    end
end
