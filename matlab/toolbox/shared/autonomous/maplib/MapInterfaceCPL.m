classdef (Hidden) MapInterfaceCPL < matlabshared.autonomous.map.internal.InternalAccess
%MapInterfaceCPL interface class defines common properties for MapLayerCPL and
%   MultiLayerMapCPL

%   Copyright 2019-2024 The MathWorks, Inc.
    
%#codegen
    
    properties (Dependent)
        %GridLocationInWorld Location of the grid in world coordinates
        %   A vector defining the [X Y] location of the bottom-left
        %   corner of the grid, relative to the world frame.
        %   Default: [0 0]
        GridLocationInWorld
        
        %GridOriginInLocal Location of the grid in local coordinates
        %   A vector defining the [X Y] location of the bottom-left
        %   corner of the grid, relative to the local frame.
        %   Default: [0 0]
        GridOriginInLocal
        
        %LocalOriginInWorld Location of the local frame in world coordinates
        %   A vector defining the [X Y] location of the local frame,
        %   relative to the world frame.
        %   Default: [0 0]
        LocalOriginInWorld
    end
    
    properties (Dependent, SetAccess = {?matlabshared.autonomous.map.internal.InternalAccess})
        %Resolution Grid resolution in cells per meter
        Resolution
        
        %GridSize Size of the grid in [rows, cols] (number of cells)
        GridSize
    end

    properties (Dependent, Transient, GetAccess = public, SetAccess=immutable)
        %XLocalLimits Min and max values of X in local frame
        XLocalLimits
        
        %YLocalLimits Min and max values of Y in local frame
        YLocalLimits
        
        %XWorldLimits Min and max values of X in world frame
        %   A vector [MIN MAX] representing the world limits of the grid
        %   along the X axis.
        XWorldLimits

        %YWorldLimits Min and max values of Y in world frame
        %   A vector [MIN MAX] representing the world limits of the grid
        %   along the Y axis.
        YWorldLimits
    end
    
    properties (Hidden, Constant, Transient)
        %FPECorrFactor Tolerance for considering grid-based numbers 'whole'
        %   A scalar which defines floating-point error tolerance when 
        %   flooring/ceiling values that have been converted from xy to cells.
        %   A value of 2 is used to counteract error caused by summation of
        %   floating point numbers, larger tolerances can be used if other 
        %   operations may have been performed on the input
        FPECorrFactor = 2;
    end
    
    properties (Transient, Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})
        
        %Width length of the map along X direction
        Width
        
        %Height length of the map along Y direction
        Height
        
        %LocalOriginInWorldInternal stores world coordinate the lower left
        %of the current grid lower left [obj.GridSize(1),1]. In case of non
        %integer resolutions move the local origin in world is different from 
        %local origin in world.
        LocalOriginInWorldInternal
    end
    
	properties (Abstract, Access = ?matlabshared.autonomous.map.internal.InternalAccess)
        %SharedProperties Internal class containing shared properties
        SharedProperties
    end
    
    methods
        function [value, validIds] = getMapData(obj, varargin)
        %getMapData Retrieve data from map layers
        %   MAT = getMapData(MAP) returns an M-by-N-by-DATADIMS matrix of values, 
        %   where DATADIMS contains the values of MAP.DataSize beyond the
        %   first two dimensions.
        %   
        %   VALS = getMapData(MAP,LOCATIONS) returns an X-by-1-by-DATADIMS 
        %   array of values for X-by-2 array, LOCATIONS. Locations
        %   found outside the bounds of the map return MAP.DefaultValue.
        %
        %   VALS = getMapData(MAP,XY,'world') returns X-by-1-by-DATADIMS
        %   array of values for X-by-2 array XY in world coordinates.
        %   This is the default reference frame.
        %
        %   VALS = getMapData(MAP,XY,'local') returns X-by-1-by-DATADIMS
        %   array of values for X-by-2 array XY in local coordinates.
        %
        %   VALS = getMapData(MAP,IJ,'grid') returns X-by-1-by-DATADIMS
        %   array of values for X-by-2 array IJ. Each row of the array IJ 
        %   refers to a grid cell index [i j].
        %
        %   [VALS, VALIDIDS] = getMapData(MAP,LOCATIONS,__) returns
        %   X-by-1-by-DATADIMS array of values for X-by-2 array, LOCATIONS.
        %   The optional third input argument is either 'world' (default), 
        %   'local', or 'grid'. The output argument VALIDIDS returns an 
        %   X-by-1 vector of logicals indicating whether input LOCATIONS 
        %   are inside map boundaries.
        %
        %   MAT = getMapData(MAP,BOTTOMLEFT,MATSIZE) returns an M-by-N-by-DATADIMS
        %   matrix of values in a subregion defined by BOTTOMLEFT and 
        %   MATSIZE. BOTTOMLEFT is the bottom-left point of the region 
        %   in the world frame, given as [X Y], and MATSIZE is the size of the
        %   region given as [width height].
        %   
        %   MAT = getMapData(MAP,BOTTOMLEFT,MATSIZE,'world') returns an 
        %   M-by-N-by-DATADIMS matrix of state values. BOTTOMLEFT is an [X Y] point
        %   in the world frame, and MATSIZE corresponds to the width and height
        %   of the region.
        %
        %   MAT = getMapData(MAP,BOTTOMLEFT,MATSIZE,'local') returns an 
        %   M-by-N-by-DATADIMS matrix of state values. BOTTOMLEFT is an [X Y] point 
        %   in the local frame, and MATSIZE corresponds to the width and height 
        %   of the region.
        %
        %   MAT = getMapData(MAP,TOPLEFT,MATSIZE,'grid') returns an 
        %   M-by-N-by-DATADIMS matrix of state values. TOPLEFT is an [I J] 
        %   index in the grid frame, and MATSIZE is a 2-element vector 
        %   corresponding to [rows cols].
        %
        %   Example:
        %       % Create a 10x20x3 mapLayer used to store velocity vectors.
        %       dx = linspace(-4,4,20);
        %       dy = linspace(0,5,10);
        %       dz = linspace(0,1,10)'*linspace(-1,1,20);
        %       [DY,DX] = ndgrid(flipud(dy),dx);
        %       V = DX; V(:,:,2) = DY; V(:,:,3) = dz;
        %       velocityMap = mapLayer(V);
        %
        %       % Retrieve the velocities for all cells in the map.
        %       vMat = getMapData(velocityMap);
        %       
        %       % Get the velocity of grid cell [1 1].
        %       vCell = getMapData(velocityMap, [1 1], 'grid');
        %
        %       % Retrieve velocities for a set of local points and determine 
        %       % whether the points lie in the map bounds.
        %       localPts = [randi(velocityMap.XLocalLimits,10,1) randi(velocityMap.XLocalLimits,10,1)]*2;
        %       [velocities,inBounds] = getMapData(velocityMap,localPts,'local');
        %
        %   See also multiLayerMap
            [value,ptIsValid] = obj.getMapDataImpl(varargin{:});

            if nargout > 1
                % If second output argument is requested, return N-by-1
                % vector of logicals corresponding to the vector of xy or
                % ij points. Any points that lie outside of boundaries, or
                % that contain nan or non-finite coordinates return false.
                validIds = ptIsValid;
            end
        end
        
        function validIds = setMapData(obj, varargin)
        %setMapData Assign data to one or more locations
        %   setMapData(MAP,INPUTMAT) overwrites all values in MAP
        %   using the M-by-N-by-DATADIMS matrix of values, INPUTMATRIX. 
        %   DATADIMS represents all elements of MAP.DataSize beyond the
        %   first two dimensions.
        %   
        %   setMapData(MAP,LOCATIONS,VAL) assigns the values of the
        %   X-by-1-by-DATADIMS array, VAL, into cells of the M-by-N-by-DATADIMS 
        %   matrix, whose cells are located at the X-by-2 array, LOCATIONS.
        %   Locations found outside map boundaries are ignored. Locations 
        %   are specified in world coordinates by default.
        %
        %   setMapData(MAP,XY,VAL,'world') assigns X-by-1-by-DATADIMS
        %   VAL to corresponding X-by-2 [x y] matrix of world coordinates, XY.
        %
        %   setMapData(MAP,XY,VAL,'local') assigns X-by-1-by-DATADIMS
        %   VAL to corresponding X-by-2 [x y] matrix of local coordinates, XY.
        %
        %   setMapData(MAP,IJ,VAL,'grid') assigns X-by-1-by-DATADIMS
        %   VAL to corresponding X-by-2 [i j] matrix of grid indices, IJ.
        %
        %   VALIDIDS = setMapData(MAP,LOCATIONS,___) optionally returns 
        %   X-by-1 vector of logicals, VALIDIDS, indicating whether input
        %   LOCATIONS are inside map boundaries. The third input argument 
        %   is either 'world' (default), 'local', or 'grid'.
        %
        %   setMapData(MAP,BOTTOMLEFT,INPUTMAT) assigns an M-by-N-by-DATADIMS
        %   matrix, INPUTMAT, to the MAP. The subregion starts in the 
        %   bottom-left [X Y] position, BOTTOMLEFT, and assigns cells 
        %   M rows up and N columns to the right based on the size of
        %   INPUTMAT.
        %   
        %   setMapData(MAP,BOTTOMLEFT,INPUTMAT,'world') assigns INPUTMAT 
        %   to the subregion starting in the bottom-left [X Y] position, 
        %   BOTTOMLEFT, in world coordinates and extends M rows up 
        %   and N columns to the right.
        %
        %   setMapData(MAP,BOTTOMLEFT,INPUTMAT,'local') assigns INPUTMAT 
        %   to the subregion starting in the bottom-left [X Y] position, 
        %   BOTTOMLEFT, in local coordinates and extends M rows up 
        %   and N columns to the right.
        %
        %   setMapData(MAP,TOPLEFT,INPUTMAT,'grid') assigns INPUTMAT  
        %   to the subregion starting in the top-left [I J] cell, TOPLEFT, 
        %   in grid indices and extends M rows down and N columns to the right.
        %
        %   Example:
        %       % Create a 10x20x3 mapLayer used to store velocity vectors.
        %       dx = linspace(-4,4,20);
        %       dy = linspace(0,5,10);
        %       dz = linspace(0,1,10)'*linspace(-1,1,20);
        %       [DY,DX] = ndgrid(flipud(dy),dx);
        %       V = DX; V(:,:,2) = DY; V(:,:,3) = dz;
        %       velocityMap = mapLayer(zeros(10,20,3));
        %
        %       % Set velocities for all cells in the map.
        %       setMapData(velocityMap,V);
        %       
        %       % Get the velocity of grid cell [1 1].
        %       vCell = getMapData(velocityMap, [1 1], 'grid');
        %
        %       % Negate the velocities contained in the left half of the map.
        %       setMapData(velocityMap,[0 0],-getMapData(velocityMap,[1 1],velocityMap.GridSize./[1 2],'g'));
        %       
        %       % Retrieve all values in the map.
        %       velocities = getMapData(velocityMap);
        %
        %   See also multiLayerMap
        
            [vals, ptIsValid, isMat, isGrid, isLocal] = obj.setParser('setMapData', varargin{:});
            
            % Apply transform function
            if ~isempty(obj.SetTransformFcn)
                vals = obj.SetTransformFcn(obj, vals, varargin{:});
            end
            
            if nargin == 2
                obj.setValueMatrixImpl(vals);
            elseif ~isMat
                % Individual points
                if isGrid
                    obj.setValueAtIndicesInternal(varargin{1}, vals);
                elseif isLocal
                    obj.setValueAtIndicesLocalImpl(varargin{1}, vals);
                else
                    obj.setValueAtIndicesWorldImpl(varargin{1}, vals);
                end
            else
                % Block syntax
                if isGrid
                    obj.setBlockInternal(varargin{1}, vals);
                elseif isLocal
                    obj.setValueLocalBlockImpl(varargin{1}, vals);
                else
                    obj.setValueWorldBlockImpl(varargin{1}, vals);
                end
            end
            
            if nargout == 1
                % If output argument is requested, return N-by-1
                % vector of logicals corresponding to the vector of xy or
                % ij points. Any points that lie outside of boundaries, or
                % that contain nan or non-finite coordinates return false.
                validIds = ptIsValid;
            end
        end
        
        function pos = grid2local(obj, idx)
        %GRID2LOCAL Convert grid indices to local coordinates
        %   XY = GRID2LOCAL(MAP, IJ) converts an N-by-2 array of grid
        %   indices, IJ, to an N-by-2 array of local coordinates, XY. The
        %   input grid indices, IJ, are in [ROW COL] format. The output,
        %   XY, is in [X Y] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(idx,{'numeric'}, {'integer', 'nonempty', '2d', 'ncols', 2}, ...
                'grid2local', 'idx', 2);

            % Convert grid index to world coordinate
            pos = obj.grid2localImpl(idx);
        end
        
        function pos = grid2world(obj, idx)
        %GRID2WORLD Convert grid indices to world coordinates
        %   XY = GRID2WORLD(MAP, IJ) converts an N-by-2 array of grid
        %   indices, IJ, to an N-by-2 array of world coordinates, XY. The
        %   input grid indices, IJ, are in [ROW COL] format. The output,
        %   XY, is in [X Y] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(idx,{'numeric'}, {'integer', 'nonempty', '2d', 'ncols', 2}, ...
                'grid2world', 'idx', 2);

            % Convert grid index to world coordinate
            pos = obj.grid2worldImpl(idx);
        end
        
        function idx = local2grid(obj, pos)
        %LOCAL2GRID Convert local coordinates to grid indices
        %   IJ = LOCAL2GRID(MAP, XY) converts an N-by-2 array of local
        %   coordinates, XY, to an N-by-2 array of grid indices, IJ. The
        %   input, XY, is in [X Y] format. The output grid indices, IJ,
        %   are in [ROW COL] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(pos, {'numeric'}, ...
                {'real', 'nonempty', '2d', 'ncols', 2}, 'local2grid', 'xy', 2);

            % Convert world coordinate to grid indices
            idx = obj.local2gridImpl(pos);
        end
        
        function xyWorld = local2world(obj, pos)
        %LOCAL2WORLD Convert local coordinates to world coordinates
        %   XYWORLD = LOCAL2WORLD(MAP, XYLOCAL) converts an N-by-2 array of 
        %   local coordinates, XYLOCAL, to an N-by-2 array of world 
        %   coordinates, XYWORLD. The input, XYLOCAL, and output, XYWORLD,
        %   are in [X Y] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(pos, {'numeric'}, ...
                {'real', 'nonempty', '2d', 'ncols', 2}, 'local2world', 'xy', 2);

            % Convert world coordinate to grid indices
            xyWorld = obj.local2worldImpl(pos);
        end
        
        function idx = world2grid(obj, pos)
        %WORLD2GRID Convert world coordinates to grid indices
        %   IJ = WORLD2GRID(MAP, XY) converts an N-by-2 array of world
        %   coordinates, XY, to an N-by-2 array of grid indices, IJ. The
        %   input, XY, is in [X Y] format. The output grid indices, IJ,
        %   are in [ROW COL] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(pos, {'numeric'}, ...
                {'real', 'nonempty', '2d', 'ncols', 2}, 'world2grid', 'xy', 2);

            % Convert world coordinate to grid indices
            idx = obj.world2gridImpl(pos);
        end
        
        function xyLocal = world2local(obj, pos)
        %WORLD2LOCAL Convert world coordinates to local coordinates
        %   XYLOCAL = WORLD2LOCAL(MAP, XYWORLD) converts an N-by-2 array of 
        %   world coordinates, XYWORLD, to an N-by-2 array of local 
        %   coordinates, XYLOCAL. The input, XYWORLD, and output, XYLOCAL,
        %   are in [X Y] format.
            
            narginchk(2,2);
            % Validate the input format and type
            validateattributes(pos, {'numeric'}, ...
                {'real', 'nonempty', '2d', 'ncols', 2}, 'world2local', 'xy', 2);

            % Convert world coordinate to grid indices
            xyLocal = obj.world2localImpl(pos);
        end
    end
    
    methods % get/set Redirects
        function location = get.GridLocationInWorld(obj)
        %get.GridLocationInWorld Getter for bottom-left corner of the grid
            location = obj.SharedProperties.GridLocationInWorld;
        end
        
        function set.GridLocationInWorld(obj, loc)
        %set.GridLocationInWorld Setter for bottom-left corner of the grid
            obj.validateLocationInput(loc, 'GridLocationInWorld');
            change = loc - obj.SharedProperties.GridLocationInWorld;
            obj.LocalOriginInWorld = obj.SharedProperties.LocalOriginInWorld + change;
        end
        
        function location = get.GridOriginInLocal(obj)
            location = obj.SharedProperties.GridOriginInLocal;
        end
        
        function set.GridOriginInLocal(obj, gridOrig)
            validateattributes(gridOrig, {'numeric'}, {'nonempty', 'real',...
                'nonnan', 'finite', 'vector', 'numel', 2}, 'EgoCentricMap','GridOriginInLocal');
            obj.SharedProperties.GridOriginInLocal = gridOrig;
        end
        
        function location = get.LocalOriginInWorld(obj)
            location = obj.SharedProperties.LocalOriginInWorld;
        end
        
        function set.LocalOriginInWorld(obj, locOrig)
            validateattributes(locOrig, {'numeric'}, {'nonempty', 'real',...
                'nonnan', 'finite', 'vector', 'numel', 2}, 'EgoCentricMap','LocalOriginInWorld');
            obj.setLocalOriginInWorld(locOrig);
        end
        
        function orig = get.LocalOriginInWorldInternal(obj)
            orig = obj.SharedProperties.LocalOriginInWorldInternal;
        end
        
        function val = get.XLocalLimits(obj)
            val = obj.SharedProperties.XLocalLimits;
        end
        
        function val = get.YLocalLimits(obj)
            val = obj.SharedProperties.YLocalLimits;
        end
        
        function xlims = get.XWorldLimits(obj)
        %get.XWorldLimits Getter for XWorldLimits property
            xlims = obj.SharedProperties.XWorldLimits;
        end

        function ylims = get.YWorldLimits(obj)
        %get.YWorldLimits Getter for YWorldLimits property
            ylims = obj.SharedProperties.YWorldLimits;
        end
        
        function gSize = get.GridSize(obj)
            gSize = obj.SharedProperties.GridSize;
        end
        
        function set.GridSize(obj, sz)
            obj.SharedProperties.GridSize = sz;
        end
        
        function res = get.Resolution(obj)
            res = obj.SharedProperties.Resolution;
        end
        
        function set.Resolution(obj, res)
            obj.SharedProperties.Resolution = res;
        end
        
        function width = get.Width(obj)
            width = obj.SharedProperties.Width;
        end
        
        function set.Width(obj, w)
            obj.SharedProperties.Width = w;
        end
        
        function height = get.Height(obj)
            height = obj.SharedProperties.Height;
        end
        
        function set.Height(obj, h)
            obj.SharedProperties.Height = h;
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})
        function [value, ptIsValid, isGrid] = getMapDataImpl(obj, varargin)
        %getMapDataImpl Parse inputs and return data stored in map
            if nargin == 1
                value = obj.getValueGrid();
                ptIsValid = [];
                isGrid = false;
            else
                [ptIsValid, matSize, isGrid, isLocal] = obj.getParser('getMapData', varargin{:});
                
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
                        value = obj.getValueGrid(varargin{1}, matSize(1), matSize(2));
                    elseif isLocal
                        value = obj.getValueLocal(varargin{1}, matSize(1), matSize(2));
                    else
                        value = obj.getValueWorld(varargin{1}, matSize(1), matSize(2));
                    end
                end
            end
            
            % Apply transform function
            if ~isempty(obj.GetTransformFcn)
                value = obj.GetTransformFcn(obj, value, varargin{:});
            end
        end

        function setLocalOriginInWorld(obj,orig)
            %setLocalOriginInWorld sets the local origin in world dependent properties
            res = obj.SharedProperties.Resolution;
            obj.SharedProperties.LocalOriginInWorld = orig; %#ok<*MCSUP>
            obj.SharedProperties.LocalOriginInWorldInternal = obj.counterFPECeil(orig*res-1/2)/res;
        end
        
        function worldXY = grid2worldImpl(obj,gridInd)
        %grid2worldImpl Convert grid coordinates to world coordinates
            
            localXY = obj.grid2localImpl(gridInd);
            worldXY = obj.local2worldImpl(localXY);
        end
        
        function localXY = grid2localImpl(obj, gridInd)
        %grid2localImpl Convert grid coordinates to local coordinates
            gOrig  = obj.SharedProperties.GridOriginInLocal;
            res    = obj.SharedProperties.Resolution;
            
            xlimit = [gOrig(1),gOrig(1)+obj.SharedProperties.Width];
            ylimit = [gOrig(2),gOrig(2)+obj.SharedProperties.Height];
            localXY = [xlimit(1) + (gridInd(:,2)-1)/res,...
                ylimit(1) + (obj.SharedProperties.GridSize(1) - gridInd(:,1))/res] + (1/(2*res));
        end
        
        function gridInd = world2gridImpl(obj, worldXY)
        %world2gridImpl Convert world coordinates to grid coordinates
        
            localXY = obj.world2localImpl(worldXY);
            gridInd = obj.local2gridImpl(localXY);
        end
        
        function gridInd = local2gridImpl(obj,localXY)
        %local2gridImpl Convert local coordinates to grid coordinates
            gOrig  = obj.SharedProperties.GridOriginInLocal;
            res    = obj.SharedProperties.Resolution;
            
            xlimit = [gOrig(1),gOrig(1)+obj.SharedProperties.Width];
            ylimit = [gOrig(2),gOrig(2)+obj.SharedProperties.Height];
            gridXY = [-ylimit(1) + localXY(:,2),-xlimit(1) + localXY(:,1)]*res;
            gridInd = ceil(gridXY);
            
            % Including the grid lines passing through grid origin in the
            % cells touching them from the right or top. This is done to
            % include grid borders lines in the grid rather than
            % considering them as unexplored. The upper limit for the
            % floating point error while finding the grid lines passing
            % through is computed using the grid limits 
            % (since fpe(v1-v2) < 2*fpe(max(v1,v2))).
            originIdx = abs(gridXY) < eps(max(abs([xlimit,ylimit])*res))*obj.FPECorrFactor;
            if any(originIdx(:))
                gridInd(originIdx) = 1;
            end
            
            % Set grid index increase along -ve y direction
            gridInd(:,1) = obj.SharedProperties.GridSize(1) + 1 - gridInd(:,1);
        end
        
        function localXY = world2localImpl(obj,worldXY)
        %world2localImpl Convert world coordinates to local coordinates
            locWorld = obj.SharedProperties.LocalOriginInWorld;
            localXY = worldXY - locWorld;
        end
        
        function worldXY = local2worldImpl(obj,localXY)
        %local2worldImpl Convert local coordinates to world coordinates
            locWorld = obj.SharedProperties.LocalOriginInWorld;
            worldXY = localXY + locWorld;
        end
        
        function gridInd = cart2grid(obj, worldXY, dir)
        %cart2grid Converts a world-xy point to grid index without
        %discontinuities at map limits
            gOrig = obj.SharedProperties.GridOriginInLocal;
            gSize = obj.SharedProperties.GridSize;
            res   = obj.SharedProperties.Resolution;
            localXY = obj.world2localImpl(worldXY);
            
            xlimit = [gOrig(1),gOrig(1)+obj.SharedProperties.Width];
            ylimit = [gOrig(2),gOrig(2)+obj.SharedProperties.Height];
            if dir
                % BottomLeft edges are inclusive
                gridInd = obj.counterFPEFloor([-ylimit(1) + localXY(:,2),-xlimit(1) + localXY(:,1)]*res+[0 1]);
                gridInd(:,1) = gSize(1) - gridInd(:,1);
            else
                % TopRight edges are inclusive
                gridInd = obj.counterFPECeil([-ylimit(1) + localXY(:,2),-xlimit(1) + localXY(:,1)]*res);
                gridInd(:,1) = gSize(1) + 1 - gridInd(:,1);
            end
        end
    end
    
    methods (Hidden)
        function [v1,v2] = createInterpVectors(obj,frame)
        %createInterpVectors Generate interpolation vectors for map of given size/resolution
            
            gSz = obj.SharedProperties.GridSize;
            res = obj.SharedProperties.Resolution;
            mSz = max(gSz);
            v = (1:mSz)';
            switch frame
                case 'g'
                    if gSz(1) == mSz
                        [v1,v2] = deal(v,v(1:gSz(2)));
                    else
                        [v1,v2] = deal(v(1:gSz(1)),v);
                    end
                otherwise
                    switch frame
                        case 'l'
                            offset = obj.GridOriginInLocal;
                        case 'w'
                            offset = obj.GridLocationInWorld;
                        otherwise
                            validatestring(frame,{'g','l','w'},'frame','createInterpVectors');
                    end
                    v = v/res - 1/(2*res)+offset;
                    if gSz(1) == mSz
                        [v1,v2] = deal(v(1:gSz(2),1),v(:,2));
                    else
                        [v1,v2] = deal(v(:,1),v(1:gSz(1),2));
                    end
            end
        end

        function [XX,YY,TF] = block2localPoints(obj,cornerPoint,blockSize,frame)
        %block2localPoints Discretizes a rectangular region in local coords
        %
        %   [XX,YY] = block2localPoints(OBJ,CORNERPOINT,BLOCKSIZE,FRAME)
        %   converts a rectangular region defined by 1x2 CORNERPOINT 
        %   closest to FRAME origin, and 1x2 BLOCKSIZE, defined in FRAME
        %   coordinates, and returns XX and YY matrices corresponding to 
        %   LOCAL X and Y coordinates of all cell-centers underlying the 
        %   block.
        %
        %   [XX,YY,TF] = block2localPoints(OBJ,CORNERPOINT,BLOCKSIZE,FRAME)
        %   optionally returns a logical matrix, TF, indicating whether the
        %   corresponding XX,YY points are in/out of bounds.

            narginchk(4,4);
            props = obj.SharedProperties;
            switch frame(1)
                case 'g'
                    i0 = cornerPoint;
                    i1 = cornerPoint+blockSize-1;
                    rows = blockSize(1);
                    cols = blockSize(2);
                case {'w','l'}
                    if frame(1) == 'l'
                        gridVecToBotLeft = cornerPoint-props.GridOriginInLocal;
                    else
                        gridVecToBotLeft = cornerPoint-props.LocalOriginInWorld-props.GridOriginInLocal;
                    end
                    [i0,~,rows,cols] = obj.computeBlockCorners(gridVecToBotLeft,blockSize(1),blockSize(2));
                    i1 = i0 + [rows,cols]-1;
                otherwise
                    % Error
                    obj.parseOptionalFrameInput(frame,'block2localPoints');
            end

            % Convert grid to cell centers
            P = obj.grid2localImpl([i0;i1]);
            x = linspace(P(1,1),P(2,1),cols);
            y = linspace(P(1,2),P(2,2),rows);
            [XX,YY] = meshgrid(x,y);

            if nargout > 2
                limx = props.XLocalLimits;
                limy = props.YLocalLimits;
    
                % Verify whether points are in bounds
                TF = (y(:) >= limy(1) & y(:) <= limy(2)) & (x >= limx(1) & x <= limx(2));
            end
        end
        
        function [values, validIdx, isMat, isGrid, isLocal] = setParser(map, fcnName, varargin)
        %setParser This parses inputs to setMapData and setOccupancy
            % Validates user inputs, formats arguments for internal
            % implementation, and returns in-bound/out-of-bound point
            % information for N-by-2 point-vector inputs
            
            isGrid = false;
            isLocal = false;
            isMat = false;
            validIdx = logical([]);
            
            if nargin == 3
                % Syntax: set___(MAP, INPUTMATRIX)
                values = varargin{1};
                isMat = true;
            else
                narginchk(3,5)
                if nargin == 4
                    if numel(varargin{1}) == 2 && numel(varargin{2}) > 1
                        % Syntax: set___(MAP, BOTTOMLEFT, INPUTMAT)
                        map.validateMatrixInput(varargin{2}, class(map), fcnName)
                        values = varargin{2};
                        isMat = true;
                    else
                        % Syntax: set___(MAP, XY, VAL)
                        % Validate position or subscripts and convert it to indices
                        [~, validIdx] = map.getLocations(varargin{1}, isGrid, isLocal, fcnName);
                        values = varargin{2};
                    end
                elseif nargin == 5
                    if numel(varargin{1}) == 2 && numel(varargin{2}) > 1
                        % Syntax: set___(MAP, BOTTOMLEFT, INPUTMAT, {'world', 'local', 'grid'})
                        map.validateMatrixInput(varargin{2}, class(map), fcnName)
                        [isGrid, isLocal] = map.parseOptionalFrameInput(varargin{3}, fcnName);
                        if isGrid
                            validateattributes(varargin{1},{'numeric'},{'integer'},fcnName,'topLeftIJ',2)
                        end
                        values = varargin{2};
                        isMat = true;
                    else
                        % Syntax: set___(MAP, XY, VAL, {'world', 'local', 'grid'})
                        [isGrid, isLocal] = map.parseOptionalFrameInput(varargin{3}, fcnName);
                        [~, validIdx] = map.getLocations(varargin{1}, isGrid, isLocal, fcnName);
                        values = varargin{2};
                    end
                end
            end
        end
        
        function [validIdx, matSize, isGrid, isLocal] = getParser(map, fcnName, varargin)
        %getParser This parses inputs to getMapData, getOccupancy, and checkOccupancy
            % Validates user inputs, formats arguments for internal
            % implementation, and returns in-bound/out-of-bound point
            % information for N-by-2 point-vector inputs
            narginchk(2,5)
            
            isGrid = false;
            isLocal = false;
            
            if nargin == 3
                % Syntax: VAL = get___(MAP, XY)
                % Validate position or subscripts and convert it to indices
                [~, validIdx] = map.getLocations(varargin{1}, isGrid, isLocal, fcnName);
                matSize = [];
            elseif nargin == 4
                if ischar(varargin{2})||isstring(varargin{2})
                    % Syntax: VAL = get___(MAP, XY, {'world', 'local', 'grid'})
                    [isGrid, isLocal] = map.parseOptionalFrameInput(varargin{2}, fcnName);
                    
                    [~, validIdx] = map.getLocations(varargin{1}, isGrid, isLocal, fcnName);
                    
                    matSize = [];
                else
                    % Syntax: MAT = get___(MAP, BOTTOMLEFT, MATSIZE)
                    matSize = varargin{2};
                    coder.internal.prefer_const(matSize);
                    validateattributes(matSize,{'numeric'},{'numel',2},fcnName,'matSize',3);
                    validIdx = logical([]);
                end
            else
                % Syntax: MAT = get___(MAP, BOTTOMLEFT, MATSIZE, {'world', 'local', 'grid'})
                validIdx = logical([]);
                matSize = varargin{2};
                coder.internal.prefer_const(matSize);
                
                validateattributes(matSize,{'numeric'},{'numel',2},fcnName,'matSize',3);
                [isGrid, isLocal] = map.parseOptionalFrameInput(varargin{3}, fcnName);
                if isGrid
                    validateattributes(varargin{1},{'numeric'},{'integer'},fcnName,'topLeftIJ',2)
                    validateattributes(matSize,{'numeric'},{'integer'},fcnName,'matSize',3)
                end
            end
        end
        
        function [moveValue, syncObj, fillValInternal] = moveParser(map, moveValue, varargin)
            %moveParser Parses and validates inputs to the move method
            isMultiMap = MapInterfaceCPL.isaMultiMap(map);
            if isMultiMap
                defVal = {map.DefaultValue};
            else
                defVal = map.DefaultValue;
            end
            defaultValues = coder.internal.constantPreservingStruct('MoveType','Absolute','SyncWith',[],'FillValue',defVal);
            nvPairs = coder.internal.nvparse(defaultValues,varargin{:});
            moveType = nvPairs.MoveType;
            syncObj = nvPairs.SyncWith;
            fillVal = nvPairs.FillValue;
            
            if isequal(fillVal,map.DefaultValue)
                fillValInternal = map.DefaultValueInternal;
            else
                if iscell(fillVal) && iscell(fillVal{1})
                    fillValInternal = map.setDefaultValueConversion(fillVal{:});
                else
                    fillValInternal = map.setDefaultValueConversion(fillVal);
                end
            end
            
            validatestring(moveType,{'Absolute','Relative'},'move','MoveType');
            map.validateLocationInput(moveValue, 'moveValue');
            
            if (strcmpi(moveType,'Absolute'))
                % Convert absolute position to relative motion
                moveValue = (map.removeFPE(moveValue*map.Resolution)-map.removeFPE(map.LocalOriginInWorld*map.Resolution))/map.Resolution;
            end
        end
        
        function [locations, idxs] = getLocations(obj, inPos, isGrid, isLocal, fcnName)
            %getLocations Validates incoming locations based on the provided frame
            
            if isGrid               % Use grid indices
                [locations, idxs] = obj.validateGridIndices(inPos,...
                    obj.GridSize, fcnName, 'IJ');
            elseif isLocal          % Use local coordinates
                [locations, idxs] = obj.validatePosition(inPos,...
                    obj.XLocalLimits, obj.YLocalLimits, fcnName, 'XY', 2);
            else                    % Use world coordinates
                [locations, idxs] = obj.validatePosition(inPos,...
                    obj.XWorldLimits, obj.YWorldLimits, fcnName, 'XY', 2);
            end
        end
    end
    
    methods (Hidden, Static)
        function input = applyUpperBounds(input,bounds,inputIsMatrix)
        %applyUpperBounds Applies bounds to size vector or matrix
            if ~coder.target('MATLAB') && coder.const(~coder.internal.eml_option_eq('VariableSizing','DisableInInference'))
                % Apply upper bounds during code-generation
                if nargin == 2
                    inputIsMatrix = false;
                end
                errorID = 'shared_autonomous:maplayer:UnboundedVariableDimension';
                coder.unroll;
                for i = 1:numel(bounds)
                    if inputIsMatrix
                        coder.internal.assert(size(input,i) <= bounds(i), errorID);
                    else
                        coder.internal.assert(input(i) <= bounds(i), errorID);
                    end
                end
            end
        end
        
        function [isGrid, isLocal] = parseOptionalFrameInput(cframe, fcnName)
            %parseOptionalFrameInput Input parser for optional string
            
            validCoordFrames = {'grid','world','local'};
            frame = validatestring(cframe,validCoordFrames,fcnName);
            isGrid = frame(1) == 'g';
            isLocal = frame(1) == 'l';
        end
        
        function loc = validateLocationInput(loc, argName)
            %validateLocationInput Validate the input format and type
            validateattributes(loc,{'numeric', 'logical'}, ...
                {'real', 'nonnan', 'finite', 'size', [1 2]}, ...
                'GridLocationInWorld', argName)
            loc = double(loc);
        end
        
        function validateMatrixInput(P, className, fcnName, matSize)
            %validateMatrixInput Validates the matrix input
            if nargin == 4
                sizeCheck = {'size',matSize};
            else
                sizeCheck = {};
            end
            if any(strcmpi(className, {'binaryOccupancyMap','signedDistanceMap'}))
                validateattributes(P, {'numeric','logical'}, ...
                    {'real', '2d', 'nonempty','nonnan',sizeCheck{:}},fcnName, 'P', 1);
            elseif strcmpi(className, 'occupancyMap')
                if islogical(P)
                    validateattributes(P, {'logical'}, ...
                        {'real', '2d', 'nonempty',sizeCheck{:}}, ...
                        fcnName, 'P', 1);
                else
                    validateattributes(P, {'numeric','logical'}, ...
                        {'real', '2d', 'nonempty','nonnan','<=',1,'>=',0,sizeCheck{:}}, ...
                        fcnName, 'P', 1);
                end
            end
        end
        
        function [pos, validInd] = validateGridIndices(pos, gridsize, fcnName, argName)
            %validateGridIndices Validate the grid indices column matrix
            
            % Validate the input format and type
            validateattributes(pos,{'numeric'}, ...
                {'integer', 'nonempty', '2d', 'ncols', 2}, ...
                fcnName, argName);
            
            % Determine which points lie inside the map bounds
            validInd = pos(:,1) <= gridsize(1,1) & pos(:,2) <= gridsize(1,2) & ...
                pos(:,1) >= 1 & pos(:,2) >= 1;
        end
        
        function [pos, validPos] = validatePosition(pos, xlimits, ylimits, fcnName, argName, argNum)
            %validatePosition Validate the pos matrix against the provided limits
            
            % Validate the input format and type
            validateattributes(pos, {'numeric'}, ...
                {'real', 'nonempty', '2d', 'ncols', 2}, fcnName, argName, argNum);
            
            pos = double(pos);
            
            % Determine which points lie inside the map bounds
            validPos = pos(:,1) >= xlimits(1) & pos(:,1) <= xlimits(2) & ...
                pos(:,2) >= ylimits(1) & pos(:,2) <= ylimits(2);
        end
        
        function [M, N] = validateGridInput(M, N, fcnName)
            %validateGridInput Validates the grid inputs rows and columns
            validateattributes(M, ...
                {'numeric', 'logical'}, ...
                {'finite','real','positive','scalar','nonnan','integer'}, fcnName, 'M', 1);
            validateattributes(N, ...
                {'numeric', 'logical'}, ...
                {'scalar','real','positive','finite','nonnan','integer'}, fcnName, 'N', 2);
            M = double(M);
            N = double(N);
        end
        
        function [W, H] = validateWorldInput(W,H, fcnName)
            %validateWorldInput Validates the world inputs width and height
            validateattributes(W, ...
                {'numeric', 'logical'}, ...
                {'scalar','real','positive','nonnan', 'finite'}, fcnName, 'W', 1);
            validateattributes(H, ...
                {'numeric', 'logical'}, ...
                {'scalar','real','positive','nonnan', 'finite'}, fcnName, 'H', 2);
            W = double(W(1));
            H = double(H(1));
        end
        
        function val = counterFPEFloor(val)
        %counterFPEFloor Checks for floating point error when flooring
        %cartesian coords to cells
            lowFPE  = ceil(val)-val <= eps(val)*MapInterfaceCPL.FPECorrFactor;
            
            val( lowFPE) = ceil(val(lowFPE));
            val(~lowFPE) = floor(val(~lowFPE));
        end
        
        function val = counterFPECeil(val)
        %counterFPECeil Checks for floating point error when ceiling
        %cartesian coords to cells
            highFPE = val-floor(val) <= eps(val)*MapInterfaceCPL.FPECorrFactor;
            
            val( highFPE) = floor(val(highFPE));
            val(~highFPE) = ceil(val(~highFPE));
        end
        
        function valOut = removeFPE(valIn)
        %removeFPE Attempts to remove floating point error in xy->grid ops
        % Input 'val' should be a vector or matrix of cartesian values
        % multiplied by obj.Resolution.
        
            %https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html
                % Theorem 2, relative error in x-y | x+y <= 2eps. For inputs
                % that are potentially sums/differences provided by user,
                % mult = 2.
            
            if coder.internal.isConstTrue(isscalar(valIn))
                coder.internal.prefer_const(valIn);
            end
            lowFPE  = ceil(valIn)-valIn <= eps(valIn)*MapInterfaceCPL.FPECorrFactor;
            highFPE = valIn-floor(valIn) <= eps(valIn)*MapInterfaceCPL.FPECorrFactor;
            
            valOut = valIn;
            valOut( lowFPE) = ceil(valIn(lowFPE));
            valOut(highFPE) = floor(valIn(highFPE));
        end
        
        function [useGridSizeInitialization, rows, cols] = calculateMapDimensions(res, frame, arg1, arg2)
        %calculateMapDimensions Return matrix size and map footprint
            coder.internal.prefer_const(res);
            useGridSizeInitialization = nargin == 4;
            if useGridSizeInitialization
                % dim inputs
                coder.internal.prefer_const(arg1);
                coder.internal.prefer_const(arg2);
                if strcmp(frame,'grid')
                    rows = arg1;
                    cols = arg2;
                else
                    width = MapInterfaceCPL.removeFPE(arg1);
                    height = MapInterfaceCPL.removeFPE(arg2);
                    rows = ceil(height*res);
                    cols = ceil(width*res);
                end
            else
                % matrix input
                [rows, cols] = size(arg1,[1 2]);
                coder.internal.prefer_const(rows);
                coder.internal.prefer_const(cols);
            end
            
        end
        
        function [nvPairs, userSupplied] = subsetValidator(supersetDefaults, subsetValidators, varargin)
        %subsetValidator Parses and validates a subset of NV-pair names
        %
        %   supersetDefaults - N-element struct containing the default values for all possible NV-pairs
        %   subsetValidators - N-element struct with fields matching those in superset
        %                      Each struct element contains a 2-element cell array, where the
        %                      first element indicates whether the Name is allowed
        %                      to appear, and the second contains a function handle
        %                      to the corresponding validator or error message.
        %   varargin         - Inputs to NV-parser
            
            if numel(varargin) == 0
                nvPairs = supersetDefaults;
                names = fieldnames(nvPairs);
                inputs = cell(1,2*numel(names));
                [inputs{1:2:end}] = deal(names{:});
                [inputs{2:2:end}] = deal(false);
                userSupplied = coder.internal.constantPreservingStruct(inputs{:});
            else
                % Retrieve all possible NV-pair names
                names = fieldnames(supersetDefaults);
                
                % Parse all NV-Pair inputs
                [nvPairs, userSupplied] = coder.internal.nvparse(supersetDefaults, varargin{:});
                
                % Validate parsed outputs
                for i = 1:numel(names)
                    if userSupplied.(names{i})
                        % NV-pair was provided, validate
                        vFcn = subsetValidators.(names{i}){2};
                        vFcn(names{i},nvPairs.(names{i}));
                    end
                end
            end
        end
        
        function nvPairs = updateParsedResolution(className, nvPairsInit, userSupplied, optionalRes)
        %updateParsedResolution Use NV-pair Resolution if supplied, otherwise use optional input
            coder.internal.prefer_const(optionalRes);
            if ~userSupplied.Resolution
                f = MapInterfaceCPL.getValResolutionFcn(className);
                f('Resolution',optionalRes);
                if isa(nvPairsInit,'coder.internal.stickyStruct')
                    nvPairs = set(nvPairsInit,'Resolution',optionalRes);
                else
                    nvPairs = nvPairsInit;
                    nvPairs.Resolution = optionalRes;
                end
            else
                nvPairs = nvPairsInit;
            end
        end

        function validationFcn = getValDefaultValueFcn(methodName)
        %getValDefaultValueFcn Validator for DefaultValue
            validationFcn = @(name,val)validateattributes(val,{'numeric','logical'},{'nonempty','scalar'},methodName,name);
        end
        
        function f = getInvalidNVPairFcn(~)
        %getInvalidNVPairFcn Returns handle to error thrown by validators when provided invalid name
            f = @(name,val)coder.internal.error('shared_autonomous:validation:InvalidNVPair',name);
        end
        
        function f = getValResolutionFcn(methodName)
        %getValResolutionFcn Validator for Resolution
            f = @(name,val)validateattributes(val,{'numeric','logical'},{'positive','scalar','nonempty','nonnan','real','finite'},methodName,name);
        end
        
        function f = getValRefFrameValueFcn(methodName)
        %getValRefFrameValueFcn Validator for GridOriginInLocal/LocalOriginInWorld
            f = @(name,val)validateattributes(val,{'numeric','logical'},{'row','numel',2,'real','nonnan','finite'},methodName,name);
        end
        
        function f = getValLayerNameFcn(methodName)
        %getValLayerNameFcn Validator for LayerName
            f = @(name,val)validateattributes(val,{'char','string'},{'nonempty'},methodName,name);
        end
        
        function f = getValUseGPUFcn(methodName)
        %getValUseGPUFcn Validator for UseGPU
            f = @(name,val)validateattributes(val,{'numeric','logical'},{'binary'},methodName,name);
        end
        
        % -------------------------- CP-L Checks --------------------------
        
        function tf = isaLayer(input)
        %isaLayer Checks whether input is a valid map
            tf = isa(input,'matlabshared.autonomous.internal.MapLayer') || ...
                 isa(input,'MapLayerCPL');
        end
        
        function validateLayer(input,fcn,name)
        %validateLayer Verifies that input is a valid map
            validateattributes(input, {'MapLayerCPL','matlabshared.autonomous.internal.MapLayer'}, {}, fcn, name);
        end
        
        function tf = isaMultiMap(input)
        %isaMultiMap Checks whether input is a valid MultiLayerMapCPL
            tf = isa(input,'matlabshared.autonomous.internal.MultiLayerMap') || ...
                 isa(input,'MultiLayerMapCPL');
        end
        
        function validateMultiMap(input,fcn,name)
        %validateLayer Verifies that input is a valid MultiLayerMapCPL
            validateattributes(input, {'MultiLayerMapCPL','matlabshared.autonomous.internal.MultiLayerMap'}, {}, fcn, name);
        end
        
        function validateInterface(input,fcn,name)
        %validateLayer Verifies that input is a valid MapInterfaceCPL
            validateattributes(input, {'MapInterfaceCPL','matlabshared.autonomous.internal.MapInterface'}, {'scalar'}, fcn, name);
        end
    end
end
