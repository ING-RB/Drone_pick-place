classdef (Hidden) MapLayer < matlabshared.autonomous.internal.MapInterface
%This class is for internal use only. It may be removed in the future.

%MapLayer creates a single layer grid map that supports efficient move
%syntax
% MapLayer can be created using any of the following signatures:
%
% MAP = matlabshared.autonomous.internal.MapLayer(NAME, W, H) creates a map layer
% identified as NAME representing a metric space of width(W) and height(H)
% in meters. Default grid resolution is 1 cell per meter. Cells are filled
% with double precision nans. 
%
% MAP = matlabshared.autonomous.internal.MapLayer(NAME, M, N, 'grid') creates a
% map layer and specifies a grid size of M rows and N columns. 
%
% MAP = matlabshared.autonomous.internal.MapLayer(NAME, P) creates a map layer
% from the values in the matrix P. 
%
% MAP = matlabshared.autonomous.internal.MapLayer(LAYER, MAPS) extracts one layer
% named LAYER from the multi-layer MAPS as handle MCOS object.
%
% MAP = matlabshared.autonomous.internal.MapLayer(__, NAME-VALUE) specifies
% additional arguments using the following name-value pairs:
%   GetTransformFcn         - Applies transformation to values retrieved by getMapData
%   SetTransformFcn         - Applies transformation to values provided to setMapData
%   LayerName               - The name of this occupancyMap instance
%   DataSize                - Size of the ND data matrix in [rows, cols, D1, D2, ..., DN]
%   GridSize                - Size of the grid in [rows, cols] (number of cells)
%   Resolution              - Map resolution in cells per meter
%   GridOriginInLocal       - Grid origin in local frame 
%   LocalOriginInWorld      - Local frame origin in world frame 
%   DefaultValue            - Default value for uninitialized map cells

%   Copyright 2019-2023 The MathWorks, Inc.

%#codegen
    
    properties (Access = ?matlabshared.autonomous.map.internal.InternalAccess)
        %SharedProperties Internal class storing synchronized properties
        SharedProperties
    end

    properties (SetAccess = protected)
        %LayerName Name for the map layer
        LayerName
    end
    
    properties (SetAccess = {?matlabshared.autonomous.map.internal.InternalAccess})
        %DataType Data type of the values stored in the map
        DataType
    end
    
    properties (Dependent)
        %DefaultValue Default value used to initialize uninitialized map
        %cells when user writes a new value only value will be written, the
        %datatype of DefaultValueInternal will be retained
        DefaultValue 
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
                       ?matlab.unittest.TestCase})
        %Buffer Circular Buffer used to store map data
        Buffer
        
        %DefaultValueInternal Default value used to initialize
        %uninitialized map cells Introduced due to codegen limitation.
        DefaultValueInternal
        
        %HasParent flag specifying weather the map layer belongs to
        %multilayer map. True if the map layer belongs to a multi layer map.
        HasParent = false
    end

    properties (Dependent, Transient)
        %Index Circular Buffer Index
        Index
    end
    
    properties (SetAccess = protected)
        %DataSize Size of the ND data matrix in [rows, cols, D1, D2, ..., DN]
        DataSize
    end
    
    properties (SetAccess = ?matlabshared.autonomous.map.internal.InternalAccess)
        %GetTransformFcn Applies transformation to values retrieved by getMapData
        %
        %   This is a function handle called inside the getMapData method. It
        %   can be used to apply a transformation to values retrieved from 
        %   the mapLayer. The function must satisfy the following syntax:
        %
        %       MODIFIEDVALUES = GetTransformFcn(MAPLAYER, VALUES, VARARGIN)
        %
        %   The size of the output, MODIFIEDVALUES, must match the size of
        %   the input, VALUES. The function is also provided with all
        %   inputs given to the getMapData method.
        GetTransformFcn
        
        %SetTransformFcn Applies transformation to values provided to setMapData
        %
        %   This is a function handle called inside the setMapData method. It
        %   can be used to apply a transformation to values given to the
        %   mapLayer prior to storing them internally. The function must 
        %   satisfy the following syntax:
        %
        %       MODIFIEDVALUES = SetTransformFcn(MAPLAYER, VALUES, VARARGIN)
        %
        %   The size of the output, MODIFIEDVALUES, must match the size of
        %   the input, VALUES. The function is also provided with all
        %   inputs given to the setMapData method.
        SetTransformFcn
    end
    
    properties (Hidden, Access = protected)
        %UseGPU Determines whether map data is stored as gpuArray or standard matrix
        %
        %   Note: Requires GPU Coder
        UseGPU = false;
    end
    
    methods
        function obj = MapLayer(varargin)
        %MapLayer Construct an instance of this class
        %Supported syntaxes:
        %   MapLayer(matrix)
        %   MapLayer(w, h)
        %   MapLayer(w, h, frame)
        %   MapLayer(w, h, CellDataSize)
        %   MapLayer(w, h, CellDataSize, frame)
        %   MapLayer(MapLayer)
        %
        %   This parser handles construction for MapLayer (internal), 
        %   mapLayer (public), binaryOccupancyMap, and occupancyMap. The
        %   overall structure of the parser is the same for all classes, but
        %   portions of the code must be overridden by Static methods in 
        %   derived classes where their construction API differs from the base.
        
            narginchk(0,18);
            className = class(obj);
            childDefaults = obj.getChildNVPairDefaults();

            if nargin ~= 0 && obj.isaLayer(varargin{1})
            % newObj = constructor(oldObj)
            %        = constructor(oldObj, nvPairs)
                validateattributes(varargin{1},{className},{'scalar','nonempty'},className);
                map = varargin{1};
                if nargin == 1
                    % Pure deep copy
                    obj.SharedProperties = matlabshared.autonomous.internal.SharedMapProperties(varargin{1}.SharedProperties);
                    obj.DefaultValueInternal = map.DefaultValueInternal;
                    obj.Buffer = copy(map.Buffer);
                    obj.Index = obj.Buffer.Index;
                    obj.LayerName = map.LayerName;
                    obj.GetTransformFcn = map.GetTransformFcn;
                    obj.SetTransformFcn = map.SetTransformFcn;
                    
                    % Check if DataSize is missing (prior to R2021a, all maps were 2D)
                    if isempty(map.DataSize)
                        obj.DataSize = map.GridSize;
                    else
                        obj.DataSize = map.DataSize;
                    end

                    coder.unroll
                    for i = 1:2:numel(childDefaults)
                        obj.(childDefaults{i}) = childDefaults{i+1};
                    end
                else
                    % Copy Constructor

                    % Define the default values for ALL Name-Value pairs
                    % supported (superset) by the lower-most class (MapLayer)
                    supersetDefaults = coder.internal.constantPreservingStruct(...
                        'Resolution',map.Resolution,...
                        'DefaultValue',map.DefaultValueInternal,...
                        'GridOriginInLocal',map.GridOriginInLocal,...
                        'LocalOriginInWorld',map.LocalOriginInWorld, ...
                        'LayerName',map.LayerName, ...
                        'GetTransformFcn',map.GetTransformFcn, ...
                        'SetTransformFcn',map.SetTransformFcn,...
                        'UseGPU',map.UseGPU,...
                        childDefaults{:});
                    
                    constDefaults = coder.internal.constantPreservingStruct(...
                        'Resolution',map.Resolution,...
                        'DefaultValue',obj.getDefaultDefaultValue(),...
                        'GridOriginInLocal',[0 0],...
                        'LocalOriginInWorld',[0 0], ...
                        'LayerName',map.LayerName, ...
                        'GetTransformFcn',[], ...
                        'SetTransformFcn',[],...
                        'UseGPU',false,...
                        childDefaults{:});
                    
                    % Retrieve subset validators. Derived classes may
                    % control the validation or exposure of NV-pairs based
                    % on the validators they provide. Name-Value pairs that
                    % do not throw an error when provided make up the
                    % subset.
                    subsetValidators = obj.getValidators(className);

                    % Create NV-Pair validator
                    nvPairValidator = @(varargin)matlabshared.autonomous.internal.MapInterface.subsetValidator(supersetDefaults,subsetValidators,varargin{:});
                    constValidator = @(varargin)matlabshared.autonomous.internal.MapInterface.subsetValidator(constDefaults,subsetValidators,varargin{:});

                    % Parse inputs
                    isOccLayer = isa(varargin{1},'occupancyMap') || isa(varargin{1},'binaryOccupancyMap');
                    if isOccLayer && nargin > 1 && isnumeric(varargin{2})
                        % Resolution has been provided as optional input
                        nvPairs = nvPairValidator(varargin{3:end});
                        [constInit, constUserSupplied] = constValidator(varargin{3:end});
                        constNVPairs = obj.updateParsedResolution(className,constInit,constUserSupplied,varargin{2});
                    else
                        % No optional resolution input
                        nvPairs = nvPairValidator(varargin{2:end});
                        constNVPairs = constValidator(varargin{2:end});
                    end
                    
                    % Extract properties that must be constant from
                    % const-only struct and map properties
                    res = constNVPairs.Resolution;
                    layerName = char(constNVPairs.LayerName);

                    % New map will have the same footprint as current map
                    W = map.SharedProperties.Width;
                    H = map.SharedProperties.Height;

                    % GPU support is undocumented as of R2021a
                    if coder.target('MATLAB') && nvPairs.UseGPU
                        defaultValue = gpuArray(nvPairs.DefaultValue);
                    else
                        defaultValue = nvPairs.DefaultValue;
                    end
                    
                    % Depth is the same, but GridSize may differ based on resolution
                    depth = map.Buffer.BufferSize(3);
                    sz = [ceil([H W]*res) map.DataSize(3:end)];
                    
                    % Create SharedProperties object
                    obj.SharedProperties = matlabshared.autonomous.internal.SharedMapProperties(sz(1:2), res);    

                    obj.GridOriginInLocal = nvPairs.GridOriginInLocal;
                    obj.LocalOriginInWorld = nvPairs.LocalOriginInWorld;
                    obj.LayerName = layerName;
                    obj.GetTransformFcn = nvPairs.GetTransformFcn;
                    obj.SetTransformFcn = nvPairs.SetTransformFcn;
                    obj.UseGPU = nvPairs.UseGPU;
                    obj.DataSize = sz;
                    
                    coder.unroll
                    for i = 1:2:numel(childDefaults)
                        obj.(childDefaults{i}) = nvPairs.(childDefaults{i});
                    end

                    % Set defaultValueInternal
                    if isempty(nvPairs.SetTransformFcn)
                        obj.DefaultValueInternal = defaultValue;
                    else
                        baseType = underlyingType(defaultValue);
                        if strcmp(baseType,'logical')
                            obj.DefaultValueInternal = obj.SetTransformFcn(obj, defaultValue) == 1;
                        else
                            obj.DefaultValueInternal = cast(obj.SetTransformFcn(obj, defaultValue),baseType);
                        end
                    end
                    
                    % Create index and buffer
                    isSimilar = obj.checkSimilarity(map) == 1;
                    if coder.internal.isConstTrue(isSimilar)
                        % Copy index and buffer directly
                        obj.Buffer = copy(map.Buffer);
                        obj.Index = obj.Buffer.Index;
                    else
                        % Create resized index/buffer and update
                        index = matlabshared.autonomous.internal.CircularBufferIndex(sz(1:2));
                        obj.Buffer = matlabshared.autonomous.internal.CircularBuffer(index,obj.DefaultValueInternal,depth);
                        obj.setValueGrid(map,'DownSamplePolicy','Max');
                    end
                end
            else
            % newObj = constructor(W,H,nvPairs)
            %        = constructor(R,C,'g',nvPairs)
            %        = constructor(MAT,nvPairs)
            %
            %	NOTE: occupancyMap/binaryOccupancyMap can accept Resolution as optional arg
            %         whereas mapLayer accepts 'CellDataSize' as optional arg
            
                % Define the default values for ALL Name-Value pairs
                % supported (superset) by the lower-most class (MapLayer)
                supersetDefaults = coder.internal.constantPreservingStruct(...
                    'Resolution',1,...
                    'DefaultValue',obj.getDefaultDefaultValue(),...
                    'GridOriginInLocal',[0 0],...
                    'LocalOriginInWorld',[0 0], ...
                    'LayerName',obj.getDefaultLayerName(), ...
                    'GetTransformFcn',[], ...
                    'SetTransformFcn',[],...
                    'UseGPU',false,...
                    childDefaults{:});
                
                % Retrieve subset validators. Derived classes may
                % control the validation or exposure of NV-pairs based
                % on the validators they provide. Name-Value pairs that
                % do not throw an error when provided make up the
                % subset.
                subsetValidators = obj.getValidators(className);

                % Create NV-Pair validator
                nvPairValidator = @(varargin)matlabshared.autonomous.internal.MapInterface.subsetValidator(supersetDefaults,subsetValidators,varargin{:});
                
                % If the first input is non-numeric, parse for NV-pairs
                if nargin == 0 || ischar(varargin{1}) || isstring(varargin{1}) || isstruct(varargin{1})
                    nvPairs = nvPairValidator(varargin{:});
                    rows = ceil(10*nvPairs.Resolution); % Default width/height is 10x10
                    cols = ceil(10*nvPairs.Resolution); % Default width/height is 10x10
                    sz = [rows cols];
                    depth = 1; 
                    useGridSizeInit = true;
                else
                    % Parse remaining inputs using static parsers
                    [nvPairs, useGridSizeInit, rows, cols, sz, depth] = obj.parseGridVsMatrix(className, nvPairValidator, varargin{:});
                end

                % Convert defaultValue to GPU if allowed
                [defaultValue, obj.UseGPU] = obj.convertToGPUCPU(nvPairs.DefaultValue, nvPairs.UseGPU, nvPairs.DefaultValue);
                
                % Construct the SharedProperties reference object
                obj.SharedProperties = matlabshared.autonomous.internal.SharedMapProperties([rows,cols],nvPairs.Resolution);

                % Assign properties
                obj.GridOriginInLocal = nvPairs.GridOriginInLocal;
                obj.LocalOriginInWorld = nvPairs.LocalOriginInWorld;
                obj.LayerName = char(nvPairs.LayerName);
                obj.GetTransformFcn = nvPairs.GetTransformFcn;
                obj.SetTransformFcn = nvPairs.SetTransformFcn;
                obj.DataSize = sz;
                
                coder.unroll
                for i = 1:2:numel(childDefaults)
                    obj.(childDefaults{i}) = nvPairs.(childDefaults{i});
                end

                % Initially default value will be empty ([]) which is of type
                % double so when we try and retain that in the set method then
                % the user passed type will be overwritten. Due to the
                % DefaultValueInternal property is used which will store the
                % value at the time construction and not retain its type.
                
                % Create index and buffer
                index = matlabshared.autonomous.internal.CircularBufferIndex(obj.SharedProperties.GridSize);
                
                if ~useGridSizeInit
                % For constructor syntax: MapLayer(matrix)
                    % If matrix is logical, set default to 0 unless it is 1
                    baseType = underlyingType(varargin{1});
                    if isempty(obj.SetTransformFcn)
                        if strcmp(baseType,'logical')
                            obj.DefaultValueInternal = defaultValue == 1;
                        else
                            obj.DefaultValueInternal = cast(defaultValue,baseType);
                        end
                        matrixInternal = varargin{1};
                    else
                        if strcmp(baseType,'logical')
                            obj.DefaultValueInternal = obj.SetTransformFcn(obj, defaultValue) == 1;
                        else
                            obj.DefaultValueInternal = cast(obj.SetTransformFcn(obj, defaultValue),baseType);
                        end
                        matrixInternal = obj.SetTransformFcn(obj, varargin{1});
                    end
                    
                    % Convert buffer matrix to gpuArray if allowed.
                    [bufferMatrix, obj.UseGPU] = obj.convertToGPUCPU(matrixInternal, nvPairs.UseGPU, nvPairs.DefaultValue);
                    obj.Buffer = matlabshared.autonomous.internal.CircularBuffer(index, obj.DefaultValueInternal, depth, bufferMatrix);
                else
                    % Retaining the datatype of the specified default when P
                    % not passed
                    if isempty(obj.SetTransformFcn)
                        obj.DefaultValueInternal = defaultValue;
                    else
                        obj.DefaultValueInternal = obj.SetTransformFcn(obj, defaultValue);
                    end
                    obj.Buffer = matlabshared.autonomous.internal.CircularBuffer(index,obj.DefaultValueInternal,depth);
                end
            end

            % Set additional child-class properties
            obj.postConstructSet(varargin{:});
        end
    end
    
    methods (Static, Hidden)
        function [nvPairs, useGridSizeInit, rows, cols, sz, depth] = parseGridVsMatrix(className, parseFcn, varargin)
        %parseGridVsMatrix
            if numel(varargin) > 1 && isnumeric(varargin{2}) && isscalar(varargin{1}) && coder.internal.isConst(size(varargin{1}))
            % For constructor syntax: MapLayer(w, h, ...)
                validateattributes(varargin{1}, {'numeric','logical'}, { 'real', ...
                'scalar','nonnan', 'finite','positive'}, className, 'MapWidth');
                validateattributes(varargin{2}, {'numeric'}, {'scalar', 'real', ...
                    'nonnan', 'finite','positive'}, className, 'MapHeight');

                if numel(varargin) > 2
                % For constructor syntax: MapLayer(w, h, ...)
                %                         MapLayer(w, h, cellDataSize, ...)
                %                         MapLayer(r, c, 'g', ...)
                %                         MapLayer(r, c, cellDataSize, 'g', ...)
                    if isnumeric(varargin{3})
                    % cellDataSize present, check for grid after determining size
                        validateattributes(varargin{3},{'numeric'},{'nonempty','integer','positive','nonempty'},'MapLayer','CellDataSize');
                        cellDataSize = varargin{3};
                        [frame, nvPairs] = matlabshared.autonomous.internal.MapLayer.parseGridInitialization(className, parseFcn, varargin{4:end});
                    else
                        cellDataSize = 1;
                        [frame, nvPairs] = matlabshared.autonomous.internal.MapLayer.parseGridInitialization(className, parseFcn, varargin{3:end});
                    end
                else
                % For constructor syntax: MapLayer(w, h)
                    cellDataSize = 1;
                    [frame, nvPairs] = matlabshared.autonomous.internal.MapLayer.parseGridInitialization(className, parseFcn);
                end
                [useGridSizeInit, rows, cols] = matlabshared.autonomous.internal.MapLayer.calculateMapDimensions(nvPairs.Resolution,frame,varargin{1},varargin{2});
                depth = prod(cellDataSize);
                z = zeros([0 0 cellDataSize(:)']);
                sz = size(z);
                sz(1:2) = [rows cols];
            else
            % For constructor syntax: MapLayer(matrix, ...)
                matlabshared.autonomous.internal.MapLayer.validateMatrixInput(varargin{1}, className, className);
                if numel(varargin) > 1
                    validateattributes(varargin{2},{'char','string','struct'},{'nonempty'},className);
                end
                nvPairs = parseFcn(varargin{2:end});
                inputMatrix = varargin{1};
                validateattributes(inputMatrix, {'numeric','logical'}, {'nonempty'}, className, 'MapValue');
                [useGridSizeInit, rows, cols] = matlabshared.autonomous.internal.MapLayer.calculateMapDimensions(nvPairs.Resolution,'grid',inputMatrix);

                if coder.target('MATLAB') && (nvPairs.UseGPU || isa(inputMatrix,'gpuArray'))
                    nvPairs.DefaultValue = gpuArray(nvPairs.DefaultValue);
                end

                sz = size(inputMatrix);
                [~,~,depth] = size(inputMatrix);
            end
        end
        
        function [frame, nvPairs, userSupplied] = parseGridInitialization(className, parseFcn, varargin)
        %parseGridInitialization Determine inputs to parse and frame during grid initialization
            numInput = numel(varargin);
            if numInput == 0
                [nvPairs, userSupplied] = parseFcn();
                frame = 'world';
            else
                if ischar(varargin{1}) || isstring(varargin{1})
                    % Can be frame or start of NV-pairs
                    if mod(numInput,2) == 0
                        % Can be NV-pairs or frame+struct
                        if isstruct(varargin{end})
                            % Frame
                            frame = validatestring(varargin{1},{'grid','world'},className,'coordinate',4);
                            [nvPairs, userSupplied] = parseFcn(varargin{2:end});
                        else
                            % NV-pairs
                            frame = 'world';
                            [nvPairs, userSupplied] = parseFcn(varargin{:});
                        end
                    else
                        if isstruct(varargin{end})
                            frame = 'world';
                            [nvPairs, userSupplied] = parseFcn(varargin{:});
                        else
                            frame = validatestring(varargin{1},{'grid','world'},className,'coordinate',4);
                            [nvPairs, userSupplied] = parseFcn(varargin{2:end});
                        end
                    end
                else
                    frame = 'world';
                    [nvPairs, userSupplied] = parseFcn(varargin{:});
                end
            end
        end
        
        function [newValue, useGPU] = convertToGPUCPU(origValue, useGPU, defaultValue)
        %convertToGPUCPU Converts value to gpuArray if requested and allowed
            % Check whether GPU is allowed
            if ~coder.target('MATLAB')
                coder.internal.errorIf(useGPU,'shared_autonomous:maplayer:GPUArrayNotSupportedForCodegen');
            else
                useGPU = useGPU || (isa(defaultValue,'gpuArray') || isa(origValue,'gpuArray'));
            end
            if coder.internal.isConstTrue(useGPU)
                newValue = gpuArray(origValue);
            else
                newValue = origValue;
            end
        end
    end
        
    methods (Hidden)
        function areEqual = isequaln(this,other)
            if isa(this,class(other))
                if isempty(this) && isempty(other)
                    areEqual = true;
                else
                    areEqual = ...
                    isequaln(this.SharedProperties, other.SharedProperties) && ...
                    isequaln(this.LayerName, other.LayerName) && ...
                    isequaln(this.DefaultValue, other.DefaultValue) && ...
                    isequaln(this.DefaultValueInternal, other.DefaultValueInternal) && ...
                    isequaln(this.DataType, other.DataType) && ...
                    isequaln(this.DataSize, other.DataSize);
                    if areEqual && ~isequaln(this.Buffer, other.Buffer)
                        % Check if the issue is just with the shifted index
                        gSize = this.SharedProperties.GridSize;
                        shiftDiff = mod(this.Buffer.Index.Head - other.Buffer.Index.Head,gSize);
                        areEqual = isequaln(this.Buffer.Buffer,circshift(other.Buffer.Buffer,shiftDiff));
                    end
                end
            else
                areEqual = false;
            end
        end
        
        function val = getValueLocal(obj,varargin)
            %getValueLocal Read from the map layer using local coordinates.
            %
            %One of the following syntaxes can be used:
            %
            %   VAL = getValueLocal(MAP) reads all data from the MAP grid
            %   as a matrix 
            %
            %   VAL = getValueLocal(MAP, XY) reads grid values from the
            %   given [Nx2] local coordinates(XY) and return the values as
            %   [Nx1] vector
            %
            %   VAL = getValueLocal(MAP,XYLowerLeft, WIDTH, HEIGHT) reads
            %   grid values from the rectangular region identified with its
            %   lower left corner local coordinate XYLowLeft and its WIDTH
            %   (in meters) and HEIGHT (in meters). The value is returned
            %   as a matrix

            narginchk(1,4);
            if nargin==1
            % VAL = getValueLocal(MAP)
                val = getValueAllImpl(obj);
            elseif nargin==2
            % VAL = getValueLocal(MAP, XY)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'getValueLocal', 'XY');
                val = getValueLocalAtIndicesImpl(obj,varargin{1});
            elseif nargin==3
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueLocal');
            elseif nargin==4
            % VAL = getValueLocal(MAP, XYLowerLeft, WIDTH, HEIGHT)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'getValueLocal', 'XYLowerLeft');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueLocal', 'Width');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueLocal', 'Height');
                
                
                val = getValueLocalBlockImpl(obj,varargin{:});
            end
        end
        
        function val = getValueWorld(obj,varargin)
            %getValueWorld Read from the map layer using world coordinates.
            %
            %One of the following syntaxes can be used.
            %   VAL = getValueWorld(MAP) reads all data from the MAP grid
            %   as a matrix
            %
            %   VAL = getValueWorld(MAP, XY) reads grid values from the
            %   given [Nx2] world coordinates(XY) and return the values as
            %   [Nx1] vector
            %
            %   VAL = getValueWorld(MAP, XYLowerLeft, WIDTH, HEIGHT) reads
            %   grid values from the rectangular region identified with its
            %   lower left corner world coordinate XYLowLeft and its WIDTH
            %   (in meters) and HEIGHT (in meters). The value is returned
            %   as a matrix

            
            narginchk(1,4);
            if nargin==1
            % VAL = getValueWorld(MAP)
                val = getValueAllImpl(obj);
            elseif nargin==2
            % VAL = getValueWorld(MAP, XY)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'getValueWorld', 'XY');
                val = getValueWorldAtIndicesImpl(obj,varargin{1});
            elseif nargin==3
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueWorld');
            elseif nargin==4
            % VAL = getValueWorld(MAP, XYLowerLeft, WIDTH, HEIGHT)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'getValueWorld', 'XYLowerLeft');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueWorld', 'Width');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueWorld', 'Height');
                
                val = getValueWorldBlockImpl(obj,varargin{:});
            end
        end
    
        function val = getValueGrid(obj,varargin)
            %getValueGrid Read from the map layer using grid coordinates.
            %
            %One of the following syntaxes can be used.
            %   VAL = getValueGrid(MAP) reads all data from the MAP grid as
            %   a matrix
            %
            %   VAL = getValueGrid(MAP, XY) reads grid values from the
            %   given [Nx2] grid coordinates(XY) and return the values as
            %   [Nx1] vector
            %
            %   VAL = getValueGrid(MAP, XYLowerLeft, WIDTH, HEIGHT) reads
            %   grid values from the rectangular region identified with its
            %   lower left corner grid coordinate XYLowLeft and its WIDTH
            %   (number of cols) and HEIGHT (number of rows). The value is
            %   returned as a matrix

            
            narginchk(1,4);
            if nargin==1
            % VAL = getValueGrid(MAP)
                val = getValueAllImpl(obj);
            elseif nargin==2
            % VAL = getValueGrid(MAP, XY)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'getValueGrid', 'XY');
                val = getValueAtIndicesInternal(obj,varargin{1});
            elseif nargin==3
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueGrid');
            elseif nargin==4
            % VAL = getValueGrid(MAP, XYLowerLeft, WIDTH, HEIGHT)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'getValueGrid', 'XYLowerLeft');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueGrid', 'Width');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueGrid', 'Height');
                val = getValueGridBlockImpl(obj,varargin{:});
            end
        end
        
        function setValueLocal(obj,varargin)
            %setValueLocal Write into the map layer using local
            %coordinates. 
            %
            % One of the following syntaxes can be used:
            %   setValueLocal(MAP, SCALAR) initialize all cells in the MAP
            %   to SCALAR value 
            %
            %   setValueLocal(MAP, MATRIX) writes a MATRIX into the map.
            %   The MATRIX is of the same size as the MAP's grid size.
            %
            %   setValueLocal(MAP, LowerLeftXY, MATRIX) writes a MATRIX
            %   into the rectangular map region identified with its lower
            %   left local coordinate (LowerLeftXY). The size
            %   of the region is determined by the MAP size and resolution
            %   and the MATRIX size. MATRIX data that goes out of MAP
            %   boundary is ignored. 
            %
            %   setValueLocal(MAP, LowerLeftXY, Scalar, Width, Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left local coordinate (LowerLeftXY) and its
            %   size as Width (meters) X Height (meters)
            %
            %   setValueLocal(MAP, XYCoordinates, VAL) writes a scalar or
            %   [Nx1] vector of values VAL into cells identified by [Nx2]
            %   map local coordinates (XYCoordinates).
            %
            %   setValueLocal(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. If multiple
            %   cells in OTHERMAP corresponds to the same cell in MAP, the
            %   value is computed using method defined in
            %   "DownSamplePolicy". User can choose 
            %   "Max" to keep the maximum values,
            %   "Mean" to keep the mean values, 
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.

            narginchk(2,5);
            if nargin==2
                if obj.isaLayer(varargin{1})
                % setValueLocal(MAP, OTHERMAP)
                    writeFromOtherMap(obj,varargin{:});
                else
                    validateattributes(varargin{1}, {'numeric', 'logical'}, ...
                        {'real', 'nonempty'}, 'setValueLocal', 'Scalar or Matrix');
                    if isscalar(varargin{1})
                    % setValueLocal(MAP, SCALAR)
                        setValueScalarImpl(obj,varargin{1});
                    else
                    % setValueLocal(MAP, MATRIX)
                        if any(size(varargin{1}) ~= obj.DataSize)
                            coder.internal.error(...
                                'shared_autonomous:maplayer:InvalidWriteMatrix');
                        end
                        setValueMatrixImpl(obj,varargin{1});
                    end
                end
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'setValueLocal', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'numeric', 'logical'}, ...
                        {'real'}, 'setValueGrid', 'Val');
                if (size(varargin{1},1) == 1)&&(~isscalar(varargin{2}))
                % setValueLocal(MAP, LowerLeftXY, MATRIX)
                    setValueLocalBlockImpl(obj,varargin{:});
                else
                % setValueLocal(MAP, XYCoordinates, VAL)
                    if (size(varargin{1},1) ~= size(varargin{2},1))
                        coder.internal.error(...
                            'shared_autonomous:maplayer:InvalidWriteVals');
                    end
                    setValueAtIndicesLocalImpl(obj,varargin{:});
                end
            elseif nargin==4
            % setValueLocal(MAP, OTHERMAP, "DownSamplePolicy", "Max")
                obj.validateLayer(varargin{1}, 'setValueLocal', 'Othermap');
                writeFromOtherMap(obj,varargin{:});
            elseif nargin==5
            % setValueLocal(MAP, LowerLeftXY, Scalar, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'setValueLocal', 'LowerLeftXY');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar'}, 'setValueLocal', 'Scalar');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueLocal', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueLocal', 'Height');
                setValueLocalBlockUsingScalarImpl(obj,varargin{:});
            end
        end
        
        function setValueWorld(obj,varargin)
            %setValueWorld Write into the map layer using world
            %coordinates. 
            %
            % One of the following syntaxes can be used:
            %   setValueWorld(MAP, SCALAR) initialize all cells in the MAP
            %   to SCALAR value 
            %
            %   setValueWorld(MAP, MATRIX) writes a MATRIX into the map.
            %   The MATRIX is of the same size as the MAP's grid size.
            %
            %   setValueWorld(MAP, LowerLeftXY, MATRIX) writes a MATRIX
            %   into the rectangular map region identified with its lower
            %   left world coordinate (LowerLeftXY). The size of the
            %   region is determined by the MAP size and resolution and the
            %   MATRIX size. MATRIX data that goes out of MAP boundary is
            %   ignored.
            %
            %   setValueWorld(MAP, LowerLeftXY, Scalar, Width, Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left world coordinate (LowerLeftXY) and its
            %   size as Width (meters) X Height (meters)
            %
            %   setValueWorld(MAP, XYCoordinates, VAL) writes a scalar or
            %   [Nx1] vector of values VAL into cells identified by [Nx2]
            %   map world coordinates (XYCoordinates).
            %
            %   setValueWorld(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. If multiple
            %   cells in OTHERMAP corresponds to the same cell in MAP, the
            %   value is computed using method defined in
            %   "DownSamplePolicy". User can choose 
            %   "Max" to keep the maximum values, 
            %   "Mean" to keep the mean values,
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.
            
            narginchk(2,5);

            if nargin==2
                if obj.isaLayer(varargin{1})
                % setValueWorld(MAP, OTHERMAP)    
                    writeFromOtherMap(obj,varargin{:});
                else
                    validateattributes(varargin{1}, {'numeric', 'logical'}, ...
                        {'real', 'nonempty'}, 'setValueWorld', 'Scalar or Matrix');
                    if isscalar(varargin{1})
                    % setValueWorld(MAP, SCALAR)
                        setValueScalarImpl(obj,varargin{1});
                    else
                    % setValueWorld(MAP, MATRIX)
                        if any(size(varargin{1}) ~= obj.DataSize)
                            coder.internal.error(...
                                'shared_autonomous:maplayer:InvalidWriteMatrix');
                        end
                        setValueMatrixImpl(obj,varargin{1});
                    end
                end
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'setValueWorld', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'numeric', 'logical'}, ...
                        {'real'}, 'setValueGrid', 'Val');
                if (size(varargin{1},1) == 1)&&(~isscalar(varargin{2}))
                % setValueWorld(MAP, LowerLeftXY, MATRIX)
                    setValueWorldBlockImpl(obj,varargin{:});
                else
                % setValueWorld(MAP, LowerLeftXY, VAL)
                    if (size(varargin{1},1) ~= size(varargin{2},1))
                        coder.internal.error(...
                            'shared_autonomous:maplayer:InvalidWriteVals');
                    end
                    setValueAtIndicesWorldImpl(obj,varargin{:});
                end
            elseif nargin==4
            % setValueWorld(MAP, OTHERMAP, "DownSamplePolicy", "Max")
                obj.validateLayer(varargin{1},'setValueWorld','otherMap');
                writeFromOtherMap(obj,varargin{:});
            elseif nargin==5
            % setValueWorld(MAP, LowerLeftXY, Scalar, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'setValueWorld', 'LowerLeftXY');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar'}, 'setValueWorld', 'Scalar');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueWorld', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueWorld', 'Height');
                setValueWorldBlockUsingScalarImpl(obj,varargin{:});
            end
        end
        
        function setValueGrid(obj,varargin)
            %setValueGrid Write into the map layer using grid coordinates.
            %
            %One of the following syntaxes can be used:
            %   setValueGrid(MAP, SCALAR) initialize all cells in the MAP
            %   to SCALAR value 
            %
            %   setValueGrid(MAP, MATRIX) writes a MATRIX into the map. The
            %   MATRIX is of the same size as the MAP's grid size.
            %
            %   setValueGrid(MAP, LowerLeftXY, MATRIX) writes a MATRIX into
            %   the rectangular map region identified with its lower left
            %   grid coordinate (LowerLeftXY). The size of the region is
            %   determined by the MAP size and resolution and the MATRIX
            %   size. MATRIX data that goes out of MAP boundary is ignored.
            %
            %   setValueGrid(MAP, LowerLeftXY, Scalar, Width, Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left grid coordinate (LowerLeftXY) and its
            %   size as Width (number of columns) X Height (number of rows)
            %
            %   setValueGrid(MAP, XYCoordinates, VAL) writes a scalar or
            %   [Nx1] vector of values VAL into cells identified by [Nx2]
            %   map grid coordinates (XYCoordinates).
            %
            %   setValueGrid(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. If multiple
            %   cells in OTHERMAP corresponds to the same cell in MAP, the
            %   value is computed using method defined in
            %   "DownSamplePolicy". User can choose 
            %   "Max" to keep the maximum values, 
            %   "Mean" to keep the mean values, 
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.
            
            narginchk(2,5);
            if nargin==2
                if obj.isaLayer(varargin{1})
                % setValueGrid(MAP, OTHERMAP)    
                    writeFromOtherMap(obj,varargin{:});
                else
                    validateattributes(varargin{1}, {'numeric', 'logical'}, ...
                        {'real', 'nonempty'}, 'setValueGrid', 'Scalar or Matrix');
                    if isscalar(varargin{1})
                    % setValueGrid(MAP, SCALAR)
                        setValueScalarImpl(obj,varargin{1});
                    else
                    % setValueGrid(MAP, MATRIX)
                        if any(size(varargin{1}) ~= obj.DataSize)
                            coder.internal.error( ...
                                'shared_autonomous:maplayer:InvalidWriteMatrix');
                        end
                        setValueMatrixImpl(obj,varargin{1});
                    end
                end
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite'}, 'setValueGrid', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'numeric', 'logical'}, ...
                        {'real'}, 'setValueGrid', 'Val');
                if (size(varargin{1},1) == 1)&&(~isscalar(varargin{2}))
                % setValueGrid(MAP, LowerLeftXY, MATRIX)
                    setBlockInternal(obj,varargin{:});
                else
                % setValueGrid(MAP, LowerLeftXY, VAL)
                    if (size(varargin{1},1) ~= size(varargin{2},1))
                        coder.internal.error(...
                            'shared_autonomous:maplayer:InvalidWriteVals');
                    end
                    setValueAtIndicesGridImpl(obj,varargin{:});
                end
            elseif nargin==4
            % setValueGrid(MAP, OTHERMAP, "DownSamplePolicy", "Max")
                obj.validateLayer(varargin{1}, 'setValueGrid', 'Othermap');
                writeFromOtherMap(obj,varargin{:});       
            elseif nargin==5
            % setValueGrid(MAP, LowerLeftXY, Scalar, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'setValueGrid', 'LowerLeftXY');
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'scalar'}, 'setValueGrid', 'Scalar');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueGrid', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan', 'finite','positive'}, 'setValueGrid', 'Height');
                setValueGridBlockUsingScalarImpl(obj,varargin{:});
            end
        end
    end
    
    methods
        function move(obj, displacement,varargin)
            %move Move the map layer using displacement in meters
            %   move(MAP, XYTranslate) move the MAP relative to world frame
            %   with translation(XYTranslate) in meters in x-y directions,
            %   newly discovered map region are filled with
            %   MAP.DefaultValue move(__, NAME-VALUE) additionally accepts
            %   name value pairs that defines how to fill the newly
            %   discovered map region:
            %       "SyncWith"          - Fill the new map region with
            %       values from a new map at those world coordinates, which
            %       can be another map layer
            %
            %       "DownSamplePolicy"  - When syncing with a higher
            %       resolution map, user can define a downsample policy.
            %       User can choose 
            %       "Max" to keep the maximum values,
            %       "Mean" to keep the mean values, 
            %       "AbsMax" to keep values with absolute maximum.
            %       Default: "Max"
            %
            %       "FillWith"           - Fill the uninitialized new map
            %       region with a specific value. If fill with value is not
            %       specified, default value will be used.

            if obj.HasParent
                coder.internal.error('shared_autonomous:maplayer:InvalidMove');
            end
            validateattributes(displacement, {'numeric'}, {'nonempty', 'real',...
                'nonnan', 'finite', 'vector', 'numel', 2}, 'move', 'shift');
            supersetDefaults = coder.internal.constantPreservingStruct(...
                'SyncWith', [], ...
                'DownSamplePolicy', 'Max', ...
                'FillWith', obj.DefaultValue);
            [nvPairs, ~] = coder.internal.nvparse(supersetDefaults, varargin{:});
            samplePolicy = nvPairs.DownSamplePolicy;
            fillValue    = nvPairs.FillWith;
            syncLayer	 = nvPairs.SyncWith;

            validatestring(samplePolicy,{'AbsMax','Mean','Max'},'move','DownSamplePolicy');
            validateattributes(fillValue, {'numeric','logical'}, {'nonempty', 'real',...
                'scalar'}, 'move', 'FillWith Value');
            if ~isempty(nvPairs.SyncWith)
                obj.validateLayer(syncLayer, 'move', 'SyncWith Value');
            end
            
            % Find cells to move by comparing new location with previous
            % location. If they are in different cells, update the map,
            % otherwise just update obj.LocalOriginInWorld
            res = obj.SharedProperties.Resolution;
            cells = obj.counterFPEFloor(abs(displacement*res)).*sign(displacement);
                
            if any(cells ~= 0)
                
                obj.Index.shift([-cells(2),cells(1)]);
            
                if isempty(syncLayer)
                    obj.Buffer.fillNewRegionsWithScalar(fillValue);
                else
                    sync(obj,syncLayer,samplePolicy,fillValue);
                end
            end
            
            obj.Index.resetNewRegions();
            obj.LocalOriginInWorld = (obj.removeFPE(obj.SharedProperties.LocalOriginInWorld*res) + cells)/res;
        end
        
        function newObj = copy(obj)
            %copy creates a deep copy of map layer object.
            
            % Initializing a dummy map for copy. GridSize is considered to
            % be variable at compile time so the construction using P which
            % is variable sized the compiler will not be able to differentiate 
            % P and grid width.
            newObj = matlabshared.autonomous.internal.MapLayer(obj);
        end
    end
    
    methods (Access = ?matlabshared.autonomous.map.internal.InternalAccess)
        function value = setDefaultValueConversion(obj, val)
        %setDefaultValueConversion Default implementation of set.DefaultValue
            % Behavior can be overridden by child classes
            validateattributes(val, {'numeric','logical'}, {'nonempty','scalar'},'MapLayer','DefaultValue');
            % No implicit conversion from nan to logical. To support that
            % when the expected type is logical and a nan value is passed
            % then the default value is set to 0 of logical type.
            
            if isnan(val)&&islogical(obj.DefaultValueInternal)
                value = false;
            else
                value = cast(val,'like',obj.DefaultValueInternal);
            end
        end
        
        function val = getDefaultValueConversion(obj)
        %setDefaultValueConversion Default implementation of set.DefaultValue
            % Behavior can be overridden by child classes
            val = obj.DefaultValueInternal(1);
        end
        
        function dataType = getDataTypeConversion(obj)
        %getDataTypeConversion Default implementation of get.DataType
            % Behavior can be overridden by child classes
            dataType = underlyingType(obj.DefaultValueInternal); 
        end
    end
    
    methods
        function set.DefaultValue(obj, val)
            value = setDefaultValueConversion(obj, val);
            obj.DefaultValueInternal = value(1);
            obj.Buffer.ConstVal = value(1);
        end
        
        function val = get.DefaultValue(obj)
            val = getDefaultValueConversion(obj);
        end
        
        function dataType = get.DataType(obj)
            dataType = getDataTypeConversion(obj);
        end

        function index = get.Index(obj)
            index = obj.Buffer.Index;
        end

        function set.Index(obj, index)
            obj.Buffer.setIndex(index);
        end
    end
    
    methods  (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
                       ?matlab.unittest.TestCase})
        function setIndex(obj,index)
            obj.Index = index; 
            obj.Buffer.setIndex(index);
        end
        
        function val = getBaseMatrix(obj,region,blockSize)
            val = getBaseMatrix(obj.Buffer,region,blockSize);
        end
        
        function values = getBaseMatrixValuesAtIndices(obj, indices)
            values = getBaseMatrixValueAtIndices(obj.Buffer, indices);
        end
        
        function setBaseMatrix(obj,region,matrix)
            % sets the base matrix region with new values specified by
            % matrix
            setBaseMatrix(obj.Buffer, region, matrix);
        end
        
        function setBaseMatrixValueAtIndices(obj,indices,values)
            % Sets base matrix values at specified indices
            setBaseMatrixValueAtIndices(obj.Buffer,indices,values);
        end
        
        function setBaseMatrixBlockWithScalar(obj,region,constVal)
            % sets the base matrix region with new values specified by
            % matrix
            setBaseMatrixBlockWithScalar(obj.Buffer,region,constVal);
        end
        
        function fillNewRegionsWithScalar(obj,constVal)
            %fillNewRegionsWithScalar replaces regions effected by shift
            %with default value
            if nargin < 2
                obj.Buffer.fillNewRegionsWithScalar();
            else
                obj.Buffer.fillNewRegionsWithScalar(constVal);
            end
        end
        
        function similar = checkSimilarity(obj,layer)
        %checkSimilarity Checks for similarity between two layers
        %
        %   1: matching Resolution, GridOriginInLocal, LocalOriginInWorld, and DataSize
        %  -1: layers are similar, but have differently-sized matrices
        %   0: layers are not similar
            if obj.isaLayer(layer)
                sim = obj.SharedProperties.Resolution == layer.SharedProperties.Resolution && ...
                      all(obj.SharedProperties.GridOriginInLocal == layer.SharedProperties.GridOriginInLocal) && ...
                      all(obj.SharedProperties.LocalOriginInWorld == layer.SharedProperties.LocalOriginInWorld) && ...
                      all(obj.SharedProperties.GridSize == layer.SharedProperties.GridSize);
                    
                % If the two layers are similar, check whether they share
                % the same dimensions (1) or just similar footprints (-1)
                if sim
                    if ~isequaln(obj.DataSize,layer.DataSize)
                        similar = -1;
                    else
                        similar = 1;
                    end
                else
                    similar = 0;
                end
            else
                similar = 0;
            end
        end
        
        function synced = sync(obj,layer,samplePolicy,fillValue)
            %sync fills new data into the regions effected by move
            %operation.
            % The new values are extracted from the layer. Grid cells
            % overlapping the new regions are extracted and sampled
            % (down/up) to match the resolution of the current map layer.
            % Returns true if some overlapping region exists.
            res = obj.SharedProperties.Resolution;
            resOther = layer.SharedProperties.Resolution;

            gSize = obj.SharedProperties.GridSize;
            locWorld_ = obj.SharedProperties.LocalOriginInWorldInternal;
            gLoc = obj.SharedProperties.GridOriginInLocal;
            mapWidth = obj.counterFPECeil(obj.SharedProperties.Width*res);
            mapHeight = obj.counterFPECeil(obj.SharedProperties.Height*res);
            dataDim = obj.Buffer.BufferSize(3);
            synced = false;
            if obj.Index.DropEntireMap
                blockLowerLeft1 = [obj.removeFPE(locWorld_(1)*res)+...
                    obj.Index.NewRegions(4)+obj.removeFPE(gLoc(1)*res),...
                    obj.removeFPE(locWorld_(2)*res)-...
                    obj.Index.NewRegions(3)+obj.removeFPE(gLoc(2)*res)];
                [mat,gridOffset] = extractOverlappingMat(obj,layer,blockLowerLeft1,mapWidth,mapHeight,fillValue);
                for j = 1:dataDim
                    obj.Buffer.Buffer(:,:,j) = sample(layer,mat(:,:,j),gSize,samplePolicy,gridOffset,resOther,res);
                end
                obj.Index.Head = [1 1];
                synced = true;
            else
            
                w = mapWidth;
                h = abs(obj.Index.NewRegions(3));

                if all([w,h] > 0)
                    if obj.Index.NewRegions(3) < 0
                        % Extraction, sampling new values and replacing of block
                        % effected by -Y movement
                        blockLowerLeft1 = [obj.removeFPE(locWorld_(1)*res)+...
                            obj.Index.NewRegions(4)+obj.removeFPE(gLoc(1)*res),...
                            obj.removeFPE(locWorld_(2)*res)+mapHeight+...
                            obj.removeFPE(gLoc(2)*res)];
                        sz = [abs(obj.Index.NewRegions(3)),gSize(2)];
                        topLeftDestIdx = [1 1];
                        synced = sampleBlock(obj,layer,samplePolicy,blockLowerLeft1,topLeftDestIdx,w,h,fillValue,sz,dataDim);
                    else
                        % Extraction, sampling new values and replacing of block
                        % effected by +Y movement
                        blockLowerLeft1 = [obj.removeFPE(locWorld_(1)*res)+...
                            obj.Index.NewRegions(4)+obj.removeFPE(gLoc(1)*res),...
                            obj.removeFPE(locWorld_(2)*res)-...
                            abs(obj.Index.NewRegions(3))+obj.removeFPE(gLoc(2)*res)];
                        sz = [abs(obj.Index.NewRegions(3)),gSize(2)];
                        topLeftDestIdx = [gSize(1)-abs(obj.Index.NewRegions(3))+1,1];
                        synced = sampleBlock(obj,layer,samplePolicy,blockLowerLeft1,topLeftDestIdx,w,h,fillValue,sz,dataDim);
                    end
                end

                w = abs(obj.Index.NewRegions(4));
                h = mapHeight;
                if all([w,h]>0)
                    if obj.Index.NewRegions(4) < 0
                        % Extraction, sampling new values and replacing of block
                        % effected by -X movement
                        blockLowerLeft1 = [obj.removeFPE(locWorld_(1)*res)+...
                            obj.Index.NewRegions(4)+obj.removeFPE(gLoc(1)*res),...
                            obj.removeFPE(locWorld_(2)*res)-...
                            obj.Index.NewRegions(3)+obj.removeFPE(gLoc(2)*res)];
                        sz = [gSize(1),abs(obj.Index.NewRegions(4))];
                        topLeftDestIdx = [1,1];
                        synced = sampleBlock(obj,layer,samplePolicy,blockLowerLeft1,topLeftDestIdx,w,h,fillValue,sz,dataDim);
                    else
                        % Extraction, sampling new values and replacing of block
                        % effected by +X movement
                        blockLowerLeft1 = [obj.removeFPE(locWorld_(1)*res)+...
                            mapWidth+obj.removeFPE(gLoc(1)*res),...
                            obj.removeFPE(locWorld_(2)*res)-obj.Index.NewRegions(3)+obj.removeFPE(gLoc(2)*res)];
                        sz = [gSize(1),abs(obj.Index.NewRegions(4))];
                        topLeftDestIdx = [1,gSize(2)-abs(obj.Index.NewRegions(4))+1];
                        synced = sampleBlock(obj,layer,samplePolicy,blockLowerLeft1,topLeftDestIdx,w,h,fillValue,sz, dataDim);
                    end
                end
            end
        end
        
        function synced = sampleBlock(obj,layer,samplePolicy,blockLowerLeft1,topLeftDestIdx,w,h,fillValue,sz,dataDim)
            sz = obj.applyUpperBounds(sz, obj.SharedProperties.GridSize);
            bk = zeros(sz(1),sz(2),dataDim,'like',obj.DefaultValue);

            [mat,gridOffset] = extractOverlappingMat(obj,layer,blockLowerLeft1,w,h,fillValue);
            res = obj.SharedProperties.Resolution;
            resOther = layer.SharedProperties.Resolution;
            
            for i = 1:dataDim
                bk(:,:,i) = sample(layer,mat(:,:,i),sz,samplePolicy,gridOffset,resOther,res);
            end
            setBlock(obj.Buffer,topLeftDestIdx,bk);
            synced = true;
        end

        function newMat = sample(~,mat,newSize,type,gridOffset,resolution1,resolution2)
            %sample interpolates/downsamples to match the specified size
            newMat = matlabshared.autonomous.map.internal.sample(double(mat),newSize,type,gridOffset,resolution1,resolution2);
        end
        
        function gridOffset = computeGridOffset(obj, layer, worldXY)
        %computeGridOffset returns the ratio of the distance between
            %cell bottom left corners in obj and layer (in which worldXY
            %lies) and 1/resolution. This is considered as gridOffset in
            %sampling function.
            res   = obj.SharedProperties.Resolution;
            gOrig = obj.SharedProperties.GridOriginInLocal;
            resOther = layer.SharedProperties.Resolution;
            gOrigOther = layer.SharedProperties.GridOriginInLocal;
            
            % grid offset is the number layer cells (fractional) covered by
            % the region between lower left corners of grid cells
            % containing worldXY in obj and layer respectively
            gridOffset = obj.removeFPE(worldXY*res)-obj.removeFPE(worldXY*resOther)+...
                obj.counterFPEFloor(worldXY*resOther)-obj.counterFPEFloor(worldXY*res) ...
                +(obj.removeFPE(gOrigOther*resOther)-obj.counterFPECeil(gOrigOther*resOther-(1/2))) ...
                -(obj.removeFPE(gOrig*res)-obj.counterFPECeil(gOrig*res-(1/2)));
        end
        
        function written = writeFromOtherMap(obj, sourceMap, policyName, policyValue)
        %writeFromOtherMap extracts the overlapping region from the
            %othermap and downsamples or upsamples the extracted block to
            %match the block size in the current map and writes the sampled
            %block to the current map. written will be true if there is
            %some overlap between them. The syntax to call this function
            %is: writeFromOtherMap(map,othermap)
            narginchk(2,4);
            obj.validateLayer(sourceMap, 'MapLayer', 'OTHERMAP');
            parser = matlabshared.autonomous.core.internal.NameValueParser({'DownSamplePolicy'},{'Max'});
            
            if nargin > 2
                parse(parser,policyName,policyValue);
                policy = validatestring(parameterValue(parser,'DownSamplePolicy'),{'AbsMax','Mean','Max'},'MapLayer','DownSamplePolicy');
            else
                policy = 'Max';
            end
            
            res = obj.SharedProperties.Resolution;
            resOther = sourceMap.SharedProperties.Resolution;

            gOrig = obj.SharedProperties.GridOriginInLocal;
            locWorld_ = obj.SharedProperties.LocalOriginInWorldInternal;
            gOrigOther = sourceMap.SharedProperties.GridOriginInLocal;
            locWorldOther_ = sourceMap.SharedProperties.LocalOriginInWorldInternal;
            fillValue = obj.DefaultValueInternal;

            mapWidth1 = obj.counterFPECeil(obj.SharedProperties.Width*res)/res;
            mapHeight1 = obj.counterFPECeil(obj.SharedProperties.Height*res)/res;
            mapWidth2 = sourceMap.counterFPECeil(sourceMap.SharedProperties.Width*resOther)/resOther;
            mapHeight2 = sourceMap.counterFPECeil(sourceMap.SharedProperties.Height*resOther)/resOther;
            
            xlimmap1 = [0 mapWidth1]  + gOrig(1) + locWorld_(1);
            ylimmap1 = [0 mapHeight1] + gOrig(2) + locWorld_(2);
            xlimmap2 = [0 mapWidth2]  + gOrigOther(1) + locWorldOther_(1);
            ylimmap2 = [0 mapHeight2] + gOrigOther(2) + locWorldOther_(2);
            xlimOverlap = [max(xlimmap1(1),xlimmap2(1)),min(xlimmap1(2),xlimmap2(2))];
            ylimOverlap = [max(ylimmap1(1),ylimmap2(1)),min(ylimmap1(2),ylimmap2(2))];
            
            written = false;
            if (xlimOverlap(1) < xlimOverlap(2))&&(ylimOverlap(1) < ylimOverlap(2))
                w = obj.removeFPE(xlimOverlap(2)-xlimOverlap(1));
                h = obj.removeFPE(ylimOverlap(2)-ylimOverlap(1));
                gridVecToBotLeft1 = [xlimOverlap(1),ylimOverlap(1)] - locWorld_ - gOrig;
                if ((rem(res,resOther)==0)||(rem(resOther,res)==0))
                    bVec = obj.counterFPECeil(gridVecToBotLeft1*res-1/2);
                    gridVecToBotLeft1 = bVec/res;
                    bL = obj.removeFPE(bVec + locWorld_*res + gOrig*res);
                    bLeft = bL/res;
                    gridVecToBotLeft2 = (bL*resOther - ...
                        obj.removeFPE(locWorldOther_*res*resOther) - ...
                        sourceMap.removeFPE(gOrigOther*...
                        res*resOther))/(res*resOther);
                else
                    gridVecToBotLeft2 = [xlimOverlap(1),ylimOverlap(1)] - locWorldOther_ - gOrigOther;
                    bLeft = [xlimOverlap(1),ylimOverlap(1)];
                end
                [minGrid1, maxGrid1,~,~] = computeBlockCorners(obj, gridVecToBotLeft1, w, h);
                [minGrid2, ~,rows,cols] = computeBlockCorners(sourceMap, gridVecToBotLeft2, w, h);
                blockSize = maxGrid1 - minGrid1 + 1;
                gridOffset = computeGridOffset(obj, sourceMap, bLeft);
                
                dataDim = size(obj.Buffer.Buffer,3);
                sz = blockSize;
                sz = obj.applyUpperBounds(sz, obj.SharedProperties.GridSize);
                maxSz = obj.SharedProperties.GridSize*(resOther/res);
                maxSize = ceil([obj.removeFPE(maxSz(1)) obj.removeFPE(maxSz(2))]);
                mat = sourceMap.getBlockInternal(minGrid2,rows,cols,fillValue,maxSize);

                if dataDim == 1
                    block = cast(sample(sourceMap,mat(:,:),sz,policy,gridOffset,resOther,res),'like',obj.DefaultValue);
		    % setBlock included in both branches to resolve CG size mismatch (g2319142)
                    obj.Buffer.setBlock(minGrid1,block);
                else
                    block = zeros(sz(1),sz(2),dataDim,'like',obj.DefaultValue);
                    for i = 1:dataDim
                        block(:,:,i) = sample(sourceMap,mat(:,:,i),sz,policy,gridOffset,resOther,res);
                    end
		    % setBlock included in both branches to resolve CG size mismatch (g2319142)
                    obj.Buffer.setBlock(minGrid1,block);
                end
                
                written = true;
            else
                setValueScalarImpl(obj,sourceMap.DefaultValueInternal);
            end
        end
        
        function [mat,gridOffset] = extractOverlappingMat(obj,layer,blockLowerLeft,width,height,fillValue)
            %extractOverlappingMat extracts cells (effected by move
            %operation). If the new cells lie within the grid boundaries of
            %layer then it extracts those value, otherwise uses specified
            %fill value as the extracted cell value.
            res = obj.SharedProperties.Resolution;
            gOrig = obj.SharedProperties.GridOriginInLocal;
            locWorld_ = obj.SharedProperties.LocalOriginInWorldInternal;
            resOther = layer.SharedProperties.Resolution;
            
            if ((rem(res,resOther)==0)||(rem(resOther,res)==0))
                % if obj and layer resolutions are integer multiples of
                % each other then snap the lower left corner of the new
                % region to the nearest grid lines. 
                bVec = blockLowerLeft - obj.removeFPE(locWorld_*res) -...
                    obj.removeFPE(gOrig*res);
                % Find the cell owner of the block lower left.
                b = obj.counterFPECeil(bVec-1/2);
                blockLowerLeft = b + obj.removeFPE(locWorld_*res) + obj.removeFPE(gOrig*res);
            end
            gridVecToBotLeft = obj.removeFPE(blockLowerLeft*resOther - ...
                obj.removeFPE(layer.LocalOriginInWorldInternal*resOther*res) - ...
                obj.removeFPE(layer.GridOriginInLocal*resOther*res))/...
                (resOther*res);

            gridOffset = computeGridOffset(obj,layer,blockLowerLeft/res);
            [minGrid, ~,rows,cols] = computeBlockCorners(layer, gridVecToBotLeft, width/res, height/res);
            maxSz1 = ceil(obj.GridSize/res*resOther);
            maxSz2 = ceil(layer.GridSize/resOther*res);
            maxSize = obj.GridSize;
            maxSize(1) = max(maxSz1(1),maxSz2(1));
            maxSize(2) = max(maxSz1(2),maxSz2(2));
            mat = getBlockInternal(layer,minGrid,rows,cols,fillValue,maxSize);
        end
        
        function newcell = isNewCell(obj,layer,gridInd)
            %isNewCell returns true if the cell corresponding to gridInd in
            %layer lies outside of current grid boundaries
            lOrig = obj.SharedProperties.LocalOriginInWorld;
            resOther = obj.SharedProperties.Resolution;
            newcell = false;
            % computing world coordinate of cell center represented by grid
            % coordinate gridInd
            worldInd = grid2worldImpl(layer,gridInd);
            % world X limits of the cell 
            cellWorldXlim = [worldInd(1)-(resOther/2),worldInd(1)+(resOther/2)];
            cellWorldYlim = [worldInd(2)-(resOther/2),worldInd(2)+(resOther/2)];
            
            % Current grid world x limits
            gridWorldXlim = obj.SharedProperties.XLocalLimits + lOrig(1);
            gridWorldYlim = obj.SharedProperties.YLocalLimits + lOrig(2);
            
            % If at least small portion of the cell lies outside of the
            % grid limits that cell is assumed to be new
            
            % there as at least some portion cell outside of x and y limits 
            if ~((((cellWorldXlim(1) > gridWorldXlim(1))&&(cellWorldXlim(1) < gridWorldXlim(2)))||...
                    ((cellWorldXlim(2) > gridWorldXlim(1))&&(cellWorldXlim(2) < gridWorldXlim(2))))&&...
                    (((cellWorldYlim(1) > gridWorldYlim(1))&&(cellWorldYlim(1) < gridWorldYlim(2)))||...
                    ((cellWorldYlim(2) > gridWorldYlim(1))&&(cellWorldYlim(2) < gridWorldYlim(2)))))
                newcell = true;
            end
        end
        
        function block = getBlockInternal(obj,topLeftIJ,numRows,numCols,fillVal,maxSize)
        %getBlockInternal returns block filled with grid values at
        %regions within grid boundaries and with default value at all
        %other regions
            
            if nargin == 6
                % Explicitly upper bound the output size
                bSz = obj.applyUpperBounds([numRows numCols],maxSize,false);
                block = obj.allocateExternalBlock(fillVal,bSz(1),bSz(2));
            else
                block = obj.allocateExternalBlock(fillVal,numRows,numCols);
            end

            botRightIJ = [(topLeftIJ(1) + numRows - 1) , (topLeftIJ(2) + numCols - 1)];
            uLeft = max(topLeftIJ,[1,1]);
            bRight = min(botRightIJ,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            
            if all(sz>0)
                block((uLeft(1)-topLeftIJ(1)+1):(uLeft(1)-topLeftIJ(1)+sz(1)),...
                    (uLeft(2)-topLeftIJ(2)+1):(uLeft(2)-topLeftIJ(2)+sz(2)),:) = ...
                    obj.Buffer.getBlock(uLeft,bRight);
            end
        end
        
        function val = getValueAllImpl(obj)
            %getValueAllImpl returns the unwrapped buffer
            
            if all(obj.Index.Head==[1,1])
                val = obj.Buffer.Buffer;
            else
                val = circshift(obj.Buffer.Buffer,-(obj.Index.Head-[1 1]));
                if ~obj.HasParent
                    obj.Buffer.Buffer = val;
                    obj.Index.Head = [1,1];
                end
            end
            val = reshape(val,obj.DataSize);
        end
        
        function val = getValueAtIndicesInternal(obj,ind,fillVal)
            %getValueAtIndicesInternal returns values at grid indices
            %specified by ind if they lie within grid boundaries, otherwise
            %default value will be returned
            
            if nargin < 3
                fillVal = obj.DefaultValueInternal;
            end
            
            % Computing indices within grid limits
            gSize = obj.SharedProperties.GridSize;
            validInd = (ind(:,1)>0)&(ind(:,1) < (gSize(1)+1))&...
                (ind(:,2)>0)&(ind(:,2) < (gSize(2)+1));
            
            % Initializing val with default values
            nIdx = size(ind,1);
            val = obj.allocateExternalBlock(fillVal,nIdx,1);
            
            % Replacing the val at valid indices with its true value
            if any(validInd)
                val(validInd(:),:) = getValueAtIndices(obj.Buffer, ind(validInd(:),:));
            end
        end
        
        function val = getValueGridBlockImpl(obj,topLeftIJ,numRows,numCols,fillVal)
            %getValueGridBlockImpl returns block specified by
            %lowerLeft,numRows and numCols
            coder.internal.prefer_const(numRows); % g2607528
            coder.internal.prefer_const(numCols); % g2607528
            if nargin < 5
                fillVal = obj.DefaultValueInternal;
            end

            val = getBlockInternal(obj,topLeftIJ,numRows,numCols,fillVal);
        end
        
        function val = getValueLocalAtIndicesImpl(obj,localXY,fillVal)
            %getValueLocalAtIndicesImpl returns values at local xy coordinates
            %specified by localXY
            
            if nargin < 3
                fillVal = obj.DefaultValueInternal;
            end
            
            localGridInd =  obj.local2gridImpl(localXY);
            val = getValueAtIndicesInternal(obj,localGridInd,fillVal);
        end
        
        function val = getValueLocalBlockImpl(obj,botLeftXY,width,height,fillVal)
            %getValueLocalBlockImpl returns block specified by lowerLeft,width and height
            coder.internal.prefer_const(width); % g2607528
            coder.internal.prefer_const(height); % g2607528

            if nargin < 5
                fillVal = obj.DefaultValueInternal;
            end
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.GridOriginInLocal;
            [topLeftIJ, ~, rows, cols] = computeBlockCorners(obj, gridVecToBotLeft, width, height);
            
            val = getBlockInternal(obj,topLeftIJ,rows,cols,fillVal);
        end
        
        function val = getValueWorldAtIndicesImpl(obj,worldXY,fillVal)
            %getValueWorldAtIndicesImpl returns values at world xy coordinates
            %specified by worldXY
            
            if nargin < 3
                fillVal = obj.DefaultValueInternal;
            end
            
            localGridInd =  obj.world2gridImpl(worldXY);
            val = getValueAtIndicesInternal(obj,localGridInd,fillVal);
        end
        
        function val = getValueWorldBlockImpl(obj,botLeftXY,width,height,fillVal)
            %getValueWorldBlockImpl returns block specified by lowerLeft,width and height
            coder.internal.prefer_const(width); % g2607528
            coder.internal.prefer_const(height); % g2607528

            if nargin < 5
                fillVal = obj.DefaultValueInternal;
            end
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.LocalOriginInWorld - obj.SharedProperties.GridOriginInLocal;
            [topLeftIJ, ~,rows,cols] = computeBlockCorners(obj, gridVecToBotLeft, width, height);
            val = getBlockInternal(obj,topLeftIJ,rows,cols,fillVal);
        end
        
        function setValueMatrixImpl(obj,mat)
            %setValueMatrixImpl replaces base matrix with specified mat
            
            obj.Buffer.Buffer(:) = mat(:);
            obj.Index.Head = [1,1];
        end
        
        function setBlockInternal(obj,topLeftIJ,val)
            %setBlockInternal fill the region specified by bottomLeft,
            %topRight and within grid boundaries with specified values in
            %val
            
            botRightIJ = topLeftIJ + size(val,1:2)-1;
            uLeft = max(topLeftIJ,[1,1]);
            bRight = min(botRightIJ,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            
            if all(sz>0)
                block = val((uLeft(1)-topLeftIJ(1)+1):(uLeft(1)-topLeftIJ(1)+sz(1)),...
                    (uLeft(2)-topLeftIJ(2)+1):(uLeft(2)-topLeftIJ(2)+sz(2)),:);
                obj.Buffer.setBlock(uLeft,block);
            end
        end
        
        function setBlockWithScalarInternal(obj,topLeftIJ,rows,cols,scalarVal)
            %setBlockWithScalarInternal fill the region specified by bottomLeft,
            %topRight and within grid boundaries with specified values in
            %val
            botRightIJ = topLeftIJ+[rows cols]-1;
            uLeft = max(topLeftIJ,[1,1]);
            bRight = min(botRightIJ,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            
            if all(sz>0)
                obj.Buffer.setBlockWithScalar(uLeft,sz,scalarVal);
            end
        end
        
        function setValueAtIndicesInternal(obj,ind,val)
            %setValueAtIndicesInternal sets values at grid indices
            %specified by ind if they are within grid boundaries and
            %ignores indices outsize of grid boundaries
            gSize = obj.SharedProperties.GridSize;
            
            % Computing indices within grid limits
            validInd = (ind(:,1)>0)&(ind(:,1) < (gSize(1)+1))&...
                (ind(:,2)>0)&(ind(:,2) < (gSize(2)+1));
            
            if isscalar(val)
                obj.Buffer.setValueAtIndices(ind(validInd,:),val);
            else
                obj.Buffer.setValueAtIndices(ind(validInd,:),val(validInd,1,:));
            end
        end
        
        function setValueScalarImpl(obj,scalarVal)
            %setValueScalarImpl sets the base matrix values with a
            %scalarValue specified by scalarVal
            
            obj.Buffer.Buffer(:) = scalarVal;
            obj.Index.Head = [1,1];
        end
        
        function setValueAtIndicesLocalImpl(obj,localXY,val)
            %setValueAtIndicesLocalImpl sets the values at local coordinates
            %specified by localXY with values specified by val.
            
            gridInd = obj.local2gridImpl(localXY);
            setValueAtIndicesInternal(obj,gridInd,val);
        end
        
        function setValueLocalBlockImpl(obj,botLeftXY,mat)
            %setValueLocalBlockImpl sets the block whose lower left is at
            %lowerLeft with new values specified by mat
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.GridOriginInLocal;
            
            minGrid = computeBlockTopfLeft(obj, gridVecToBotLeft, size(mat,1));
            setBlockInternal(obj,minGrid,mat);
        end
        
        function setValueLocalBlockUsingScalarImpl(obj,botLeftXY,scalarValue,width,height)
            %setValueLocalBlockUsingScalarImpl sets the block specified by
            %lowerLeft, width and height with a scalar value specified by
            %scalarValue.
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.GridOriginInLocal;
            [topLeftIJ, ~,rows,cols] = computeBlockCorners(obj, gridVecToBotLeft, width, height);
            setBlockWithScalarInternal(obj,topLeftIJ,rows,cols,scalarValue);
        end
        
        function setValueAtIndicesWorldImpl(obj,worldXY,val)
            %setValueAtIndicesWorldImpl sets the values at world coordinates
            %specified by worldXY with values specified by val.
            
            gridInd = obj.world2gridImpl(worldXY);
            setValueAtIndicesInternal(obj,gridInd,val);
        end
        
        function setValueWorldBlockImpl(obj,botLeftXY,mat)
            %setValueWorldBlockImpl sets the block whose lower left is at
            %lowerLeft with new values specified by mat
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.LocalOriginInWorld - obj.SharedProperties.GridOriginInLocal;
            
            topLeftIJ = computeBlockTopfLeft(obj, gridVecToBotLeft, size(mat,1));
            setBlockInternal(obj,topLeftIJ,mat);
        end
        
        function setValueWorldBlockUsingScalarImpl(obj,botLeftXY,scalarValue,width,height)
            %setValueWorldBlockUsingScalarImpl sets the block specified by
            %lowerLeft, width and height with a scalar value specified by
            %scalarValue.
            
            % Find cell corresponding to bottom left corner
            gridVecToBotLeft = botLeftXY - obj.SharedProperties.LocalOriginInWorld - obj.SharedProperties.GridOriginInLocal;
            [topLeftIJ, ~,rows,cols] = computeBlockCorners(obj, gridVecToBotLeft, width, height);
            setBlockWithScalarInternal(obj,topLeftIJ,rows,cols,scalarValue);
        end
        
        function setValueGridBlockUsingScalarImpl(obj,topLeftIJ,scalarValue,numCols,numRows)
            %setValueGridBlockUsingScalarImpl sets the block specified by
            %lowerLeft, numRows and numCols with a scalar value specified by
            %scalarValue.

            setBlockWithScalarInternal(obj,topLeftIJ,numRows,numCols,scalarValue);
        end
        
        function setValueAtIndicesGridImpl(obj,gridInd,val)
            %setValueAtIndicesGridImpl sets the values at grid indices
            %specified by gridInd with values specified by val.
            
            setValueAtIndicesInternal(obj,gridInd,val);
        end
        
        function [minGrid, maxGrid, rowBase, colBase] = computeBlockCorners(obj, gridVecToBotLeft, width, height)
        %computeBlockCorners computes grid lower left and top right
            %corners from local block lower left, width and height
            gSize = obj.SharedProperties.GridSize;
            res = obj.SharedProperties.Resolution;
            coder.internal.prefer_const(width); % g2607528
            coder.internal.prefer_const(height); % g2607528
            
            % Calculate topLeft corner of matrix in grid coords while taking
            % discretization error into account.
            minGrid = [obj.counterFPEFloor(gSize(1)-(obj.removeFPE(gridVecToBotLeft(2)*res)+obj.removeFPE(height*res))),...
                obj.counterFPEFloor(gridVecToBotLeft(1)*res)]+1;

            % including grid top and right borders in the cell while
            % computing max grid
            maxGrid = [obj.counterFPECeil(gSize(1)-obj.removeFPE(gridVecToBotLeft(2)*res)),...
                obj.counterFPECeil(obj.removeFPE(gridVecToBotLeft(1)*res)+obj.removeFPE(width*res))];

            % g2667413: Size inputs with upper-bounded values should support
            % codegen, but Coder's range analysis fails when bounded values
            % are combined with unbounded values. Size values calculated
            % purely from resolution and input width/height should be at 
            % most 1 cell off from the true rectangular region.
            rowBase = floor(height*res);
            colBase = floor(width*res);
            
            % g2667413: Depending on whether these values are >,<,= to the true 
            % value, we add or remove 1. This should preserve range 
            % information attached to entrypoint size inputs, and produce
            % the same results as the "correct" formulation.
            if rowBase < (maxGrid(1)-minGrid(1))+1
                rowBase = rowBase+1;
            elseif rowBase > (maxGrid(1)-minGrid(1))+1
                rowBase = rowBase-1;
            end
            
            if colBase < (maxGrid(2)-minGrid(2))+1
                colBase = colBase+1;
            elseif colBase > (maxGrid(2)-minGrid(2))+1
                colBase = colBase-1;
            end
        end
        
        function minGrid = computeBlockTopfLeft(obj, bottomLeftVec, numRows)
            %computeBlockTopLeft computed top left corner of the block
            %which will be the lower left corner in the grid from the
            %specified lower left and the number of rows in the set value
            %matrix. This is useful for setValue methods.
            res = obj.SharedProperties.Resolution;
            dIJ = flip(obj.counterFPEFloor(bottomLeftVec*res));
            botLeftIdx = [obj.SharedProperties.GridSize(1) - dIJ(1), 1+dIJ(2)];
            
            % Calculate top-left and bottom-right corners
            minGrid = botLeftIdx - [numRows-1 0];
        end

        function block = allocateExternalBlock(obj,defaultVal,rows,cols)
        %allocateExternalBlock Allocate block with user-facing dimensions
            coder.inline('always');
            dataSize = obj.DataSize;
            nDim = numel(dataSize);
            if nDim == 2
                block = repmat(defaultVal,rows,cols);
            else
                dSz = cell(nDim-2,1);
                coder.unroll;
                for i = 3:nDim
                    dSz{i-2} = dataSize(i);
                end
                block = repmat(defaultVal,rows,cols,dSz{:});
            end
        end
    end
    
    methods (Access = protected)
        function postConstructSet(obj, varargin) %#ok<INUSD> 
        %postConstructSet Set additional properties after internal construction
        %
        %   Override this function in derived classes to set the occupancy
        %   values.
        end
    end

    methods (Static, Hidden)
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

        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'LayerName','DataSize'};
        end
        
        function name = getDefaultLayerName()
        %getDefaultDefaultValue Returns the Compile-time constant LayerName for internal MapLayer objects
            name = 'DefaultLayer';
        end
        
        function defaultValue = getDefaultDefaultValue()
        %getDefaultDefaultValue Returns the Compile-time constant DefaultValue for internal MapLayer objects
            defaultValue = nan;
        end
        
        function validators = getValidators(methodName)
        %getValidators Returns validators for associated function calls
        %
        %   This static method can be overridden by derived classes,
        %   allowing classes like the binaryOccupancyMap to alter the
        %   behavior of the parser.
            validators = struct(...
                'Resolution',         {{1,matlabshared.autonomous.internal.MapInterface.getValResolutionFcn(methodName)}},...
                'DefaultValue',       {{1,matlabshared.autonomous.internal.MapInterface.getValDefaultValueFcn(methodName)}},...
                'GridOriginInLocal',  {{1,matlabshared.autonomous.internal.MapInterface.getValRefFrameValueFcn(methodName)}},...
                'LocalOriginInWorld', {{1,matlabshared.autonomous.internal.MapInterface.getValRefFrameValueFcn(methodName)}},...
                'LayerName',          {{1,matlabshared.autonomous.internal.MapInterface.getValLayerNameFcn(methodName)}},...
                'GetTransformFcn',    {{1,@(name,val)true}},...
                'SetTransformFcn',    {{1,@(name,val)true}}, ...
                'UseGPU',             {{1,matlabshared.autonomous.internal.MapInterface.getValUseGPUFcn(methodName)}});
        end

        function childNVPairDefaults = getChildNVPairDefaults()
        %getChildNVPairDefaults Returns additional NV-pair defaults
        %
        %   This static method can be overridden by derived classes,
        %   allowing classes like the binaryOccupancyMap to accept
        %   additional name-value pairs during construction.
            childNVPairDefaults = {};
        end
    end
end
