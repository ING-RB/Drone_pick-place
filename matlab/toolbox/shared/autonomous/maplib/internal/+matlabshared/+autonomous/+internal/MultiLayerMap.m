classdef MultiLayerMap < matlabshared.autonomous.internal.MapInterface
%This class is for internal use only. It may be removed in the future.

%MultiLayerMap stack of multiple MapLayers

%   Copyright 2019-2023 The MathWorks, Inc.

%#codegen
    
    properties (Access = ?matlabshared.autonomous.map.internal.InternalAccess)
        %SharedProperties Handle to properties shared with MapLayer
        SharedProperties
    end
    
    properties (Dependent)
        %LayerNames names of the layers in multi layer map
        LayerNames
    end
    
    properties (Dependent,SetAccess = {?matlabshared.autonomous.map.internal.InternalAccess})
        %DataType Data type of the values stored in the map
        DataType
    end
    
    properties (Dependent)
        %DefaultValue Default value used to initialize uninitialized map cells
        DefaultValue
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})
        %Index Circular Buffer Index
        Index
        
        %Layers map layers
        Layers
    end
    
    properties (GetAccess = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})     
        %LayerNamesInternal stores layer names as cell array of character
        %vectors. Because string arrays are not supported for
        %codegeneration
        LayerNamesInternal
    end

    properties (SetAccess = ?matlabshared.autonomous.map.internal.InternalAccess)
        %NumLayers Number of map layers stored internally
        NumLayers
    end
    
    methods
        function obj = MultiLayerMap(varargin)
            %MultiLayerMap Construct an instance of this class
            % MAP = matlabshared.autonomous.internal.MapLayer(NAME, W, H)
            % creates a map layer identified as NAME representing a metric
            % space of width(W) and height(H) in meters. Default grid
            % resolution is 1 cell per meter. Cells are filled with double
            % precision nans. MAP =
            % matlabshared.autonomous.internal.MapLayer(NAME, M, N, 'g')
            % creates a map layer and specifies a grid size of M rows and N
            % columns. MAP =
            % matlabshared.autonomous.internal.MapLayer(NAME, P) creates a
            % map layer from the values in the matrix P. MAP =
            % matlabshared.autonomous.internal.MapLayer(MAPS, LAYER)
            % extracts one layer named LAYER from the multi-layer MAPS as
            % handle MCOS object. MAP =
            % matlabshared.autonomous.internal.MapLayer(__, NAME-VALUE)
            % specifies additional arguments using the following name-value
            % pairs:
            %   Resolution              - Map resolution in cells per meter
            %   GridOriginInLocal       - Grid origin in local frame
            %   LocalOriginInWorld      - Local frame origin in world frame
            %   DefaultValue            - Default value for uninitialized
            %   map cells
            
            narginchk(0,19);
            className = class(obj);
            if nargin ~= 0 && obj.isaMultiMap(varargin{1})
            %MultiLayerMap(otherMultiMap)
                narginchk(1,1);
                otherMap = varargin{1};
                validateattributes(otherMap,{className},{'nonempty','scalar'},className);
                fCtor = str2func(className);
                % Create copies of all layers
                numLayers = numel(otherMap.Layers);
                layers = cell(1,numLayers);
                for i = 1:numLayers
                    layers{i} = copy(otherMap.Layers{i});
                    layers{i}.HasParent = false;
                end
                obj = fCtor(layers);
            elseif nargin ~= 0 && iscell(varargin{1}) && ~isempty(varargin{1}) && obj.isaLayer(varargin{1}{1})
            %MultiLayerMap({maps})
                % This syntax is simply used to wrap a set of maps within a MultiLayerMap
                narginchk(1,1)
                refLayer = varargin{1}{1};
                if obj.isaLayer(refLayer)
                    % Clearing the new regions computed by previous moves
                    refLayer.Index.resetNewRegions();
                    numLayers = numel(varargin{1});
                    
                    % Verify that all layers are compatible and not already
                    % parented to another map.
                    for k = 1:numLayers
                        sim = checkSimilarity(refLayer,varargin{1}{k});
                        coder.internal.errorIf(~(sim ~= 0),'shared_autonomous:multilayermap:InvalidMapLayerInput',varargin{1}{k}.LayerName,refLayer.LayerName);
                        coder.internal.errorIf(varargin{1}{k}.HasParent,'shared_autonomous:multilayermap:OneParentPerMap',varargin{1}{k}.LayerName);
                    end
                    
                    % Grab handle to SharedProperties object
                    obj.SharedProperties = refLayer.SharedProperties;
                    
                    % Preallocate MultiLayerMap
                    obj.Layers = cell(1,numLayers);
                    obj.NumLayers = numLayers;
                    dataType = cell(1,numLayers);
                    layerNames = cell(1,numLayers);
                    
                    % Assign layers to map
                    for k = 1:numLayers
                        obj.Layers{k} = varargin{1}{k};
                        layerNames{k} = char(varargin{1}{k}.LayerName);
                        dataType{k} = obj.Layers{k}.DataType;
                        obj.Layers{k}.SharedProperties = refLayer.SharedProperties;
                    end
                    
                    obj.LayerNamesInternal = layerNames;
                    obj.Index = refLayer.Index;
                else
                    coder.internal.assert(false,'shared_autonomous:multilayermap:InvalidLayerInputNone');
                end
            else
                if nargin == 0 || isempty(varargin{1})
                    layerNamesInternal = cell(1,0);
                    numLayers = 0;
                else
                    if isstring(varargin{1}) || (iscell(varargin{1}) && (isstring(varargin{1}{1}) || ischar(varargin{1}{1})))
                        layerNames = cell(1,length(varargin{1}));
                        for k = 1:length(varargin{1})
                            layerNames{k} = char(varargin{1}{k});
                        end

                        layerNamesInternal = layerNames;
                        numLayers = numel(layerNamesInternal);
                    else
                        coder.internal.assert(false,'shared_autonomous:multilayermap:InvalidLayerInputNone');
                    end
                end
                
                % Construct parser for NV-Pairs.
                dVals = repmat({obj.getDefaultDefaultValue},1,numLayers);
                parserDefaults = {dVals, 1, [0 0], [0 0], []};
                
                if nargin <= 1
                    nvPairs = obj.validateNVPairs(className, numLayers, parserDefaults{:});
                    [useGridSizeInitialization, rows, cols] = obj.calculateMapDimensions(nvPairs.Resolution,'grid',10,10);
                    cellDataSize = repmat({[1]},numLayers,1); %#ok<NBRAK>
                else
                    narginchk(2,18);
                    validateattributes(varargin{2}, {'numeric','cell'}, {}, 'MultiLayerMap', 'MapWidth or MapValue');

                    % Constructs a new MultiLayerMap from scratch using
                    % size and location information.
                    if ~iscell(varargin{2})
                        validateattributes(varargin{2}, {'numeric'}, {'scalar', 'real', ...
                            'nonnan', 'finite','positive'}, 'MultiLayerMap', 'MapWidth');
                        validateattributes(varargin{3}, {'numeric'}, {'scalar', 'real', ...
                            'nonnan', 'finite','positive'}, 'MultiLayerMap', 'MapHeight');

                        if nargin > 3
                            if isnumeric(varargin{4}) || iscell(varargin{4})
                                % cellDataSize present, check for grid after determining size
                                if isnumeric(varargin{4})
                                    % Numeric cellDataSize is applied to all layers
                                    cellDataSize = repmat({varargin{4}}, numLayers, 1);
                                else
                                    % Number of cells in cellDataSize must match number of layers
                                    nDataSize = numel(varargin{4});
                                    coder.internal.errorIf(numLayers ~= nDataSize, 'shared_autonomous:multilayermap:InvalidNumDataSizeInput',numLayers);
                                    cellDataSize = varargin{4};
                                end
                                [frame, nvPairs] = obj.parseGridInitialization(className, numLayers, parserDefaults, varargin{5:end});
                            else
                                % cellDataSize not provided, check for grid
                                cellDataSize = repmat({[1]},numLayers,1); %#ok<NBRAK>
                                [frame, nvPairs] = obj.parseGridInitialization(className, numLayers, parserDefaults, varargin{4:end});
                            end
                        else
                            frame = 'world';
                            cellDataSize = repmat({1},numLayers,1);
                            nvPairs = obj.validateNVPairs(className, numLayers, parserDefaults{:}, varargin{4:end});
                        end
                        [useGridSizeInitialization, rows, cols] = obj.calculateMapDimensions(nvPairs.Resolution, frame, varargin{2}, varargin{3});
                    else
                        inputMatrices = varargin{2};
                        coder.internal.assert((~isempty(inputMatrices)&&(length(inputMatrices)==numLayers)),...
                            'shared_autonomous:multilayermap:InvalidMatrixInput','Second input argument to MultiLayerMap');
                        for k = 1:numLayers
                            coder.internal.errorIf(any(size(inputMatrices{1},[1 2]) ~= size(inputMatrices{k},[1 2])) || ...
                                ~(isnumeric(varargin{2}{k}) || islogical(varargin{2}{k})), ...
                                'shared_autonomous:multilayermap:InvalidMatrixInput','Second input argument to MultiLayerMap');
                        end

                        nvPairs = obj.validateNVPairs(className, numLayers, parserDefaults{:}, varargin{3:end});
                        [useGridSizeInitialization, rows, cols] = obj.calculateMapDimensions(nvPairs.Resolution,'grid',inputMatrices{1});
                        cellDataSize = repmat({[1]},numLayers,1); %#ok<NBRAK>
                    end
                end
                
                % Validate map or matrix inputs
                baseIsMapLayer = false;
                if ~isempty(nvPairs.BaseMap)
                    if obj.isaLayer(nvPairs.BaseMap)
                        baseIsMapLayer = true;
                    elseif obj.isaMultiMap(nvPairs.BaseMap)
                        [lExist,lInd] = checkLayerExists(nvPairs.BaseMap,layerNamesInternal);
                        coder.internal.assert((length(find(lExist))==numLayers),...
                            'shared_autonomous:multilayermap:InvalidBaseMap');
                    else
                        coder.internal.assert(false,'shared_autonomous:multilayermap:InvalidBaseMap');
                    end
                end

                % Construct the SharedProperties reference object
                obj.SharedProperties = matlabshared.autonomous.internal.SharedMapProperties([rows,cols], nvPairs.Resolution);

                % Assign properties
                obj.GridOriginInLocal = nvPairs.GridOriginInLocal;
                obj.LocalOriginInWorld = nvPairs.LocalOriginInWorld;
                obj.LayerNamesInternal = layerNamesInternal;

                % Construct Index object
                obj.Index = matlabshared.autonomous.internal.CircularBufferIndex(obj.SharedProperties.GridSize);
                obj.Layers = cell(1,length(obj.LayerNamesInternal));

                % Get the default map object constructor
                layerConstructor = obj.getDefaultMapConstructor();
                for k = 1:length(obj.LayerNamesInternal)
                    if ~useGridSizeInitialization
                        % Initialize map using matrix
                        obj.Layers{k} = layerConstructor(inputMatrices{k},'Resolution',nvPairs.Resolution,'LayerName',obj.LayerNamesInternal{k});
                    else
                        % Initializing dummy map layer due to codegen
                        % limitation that P must be compile time constant
                        obj.Layers{k} = layerConstructor(rows,cols,cellDataSize{k},'g','Resolution',nvPairs.Resolution,'DefaultValue',nvPairs.DefaultValue{k},'LayerName',obj.LayerNamesInternal{k});
                        obj.Layers{k}.Index = obj.Index.copy();
                    end
                    obj.Layers{k}.SharedProperties = obj.SharedProperties;
                    obj.Layers{k}.Index = obj.Index;

                    if ~isempty(nvPairs.BaseMap)
                        if baseIsMapLayer
                            obj.Layers{k}.writeFromOtherMap(nvPairs.BaseMap);
                        else
                            obj.Layers{k}.writeFromOtherMap(nvPairs.BaseMap.Layers{lInd(k)});
                        end
                    end
                end
                obj.DefaultValue = nvPairs.DefaultValue;
            end
            % Verify that names of all layers are unique.
            for i = 1:numLayers
                coder.internal.errorIf(nnz(strcmpi(obj.LayerNamesInternal{i},obj.LayerNamesInternal)) > 1,'shared_autonomous:multilayermap:UniqueLayerNames');
            end
            for i = 1:numLayers
                obj.Layers{i}.HasParent = true;
            end
        end
    end
    
    methods (Static, Hidden)
        function nvPairs = validateNVPairs(className, numLayers, defVal, defRes, defGrid, defLocal, defBaseMap, varargin)
        %validateNVPairs Retrieve and validate all NV pairs from inputs
        
            % Define defaults
            defaults = struct(...
                'DefaultValue',{defVal}, ...
                'Resolution',defRes, ...
                'GridOriginInLocal',defGrid, ...
                'LocalOriginInWorld',defLocal, ...
                'BaseMap',defBaseMap);
            
            if isempty(varargin)
                nvPairs = defaults;
            else
                % Define all NV-Pair names
                nvPairNames = {'DefaultValue', 'Resolution', 'GridOriginInLocal', 'LocalOriginInWorld', 'BaseMap'};
                
                % Create parser
                pstruct = coder.internal.parseInputs(struct(), nvPairNames, [], varargin{:});
                nvPairs = coder.internal.vararginToStruct(pstruct, defaults, varargin{:});
                
                % Validate parsed inputs
                defaultValue = nvPairs.DefaultValue;
                coder.internal.assert((length(defaultValue) == numLayers)&&(iscell(defaultValue)),...
                'shared_autonomous:multilayermap:ExpectedCellArrayScalar','''DefaultValue''');
                
                numLayers = numel(defaultValue);
                for k = 1:numLayers
                    coder.internal.assert((isscalar(defaultValue{k})&&(islogical(defaultValue{k})||isnumeric(defaultValue{k}))),...
                        'shared_autonomous:multilayermap:ExpectedCellArrayScalar','''DefaultValue''');
                end
                
                validateattributes(nvPairs.Resolution, {'numeric'}, {'scalar', 'real', ...
                            'nonnan', 'finite'}, className, 'Resolution');
                
                validateattributes(nvPairs.GridOriginInLocal, {'numeric'}, {'nonempty', 'real',...
                        'nonnan', 'finite', 'vector', 'numel', 2}, className,'GridOriginInLocal');
                
                validateattributes(nvPairs.LocalOriginInWorld, {'numeric'}, {'nonempty', 'real',...
                        'nonnan', 'finite', 'vector', 'numel', 2}, className, 'LocalOriginInWorld');
            end
        end
    end
    
    methods (Hidden)
        function [frame, nvPairs] = parseGridInitialization(obj, className, numLayers, defaults, varargin)
        %parseGridInitialization Determine inputs to parse and frame during grid initialization
            numInput = numel(varargin);
            if numInput == 0
                nvPairs = obj.validateNVPairs(className, numLayers, defaults{:});
                frame = 'world';
            else
                if ischar(varargin{1}) || isstring(varargin{1})
                    % Can be frame or start of NV-pairs
                    if mod(numInput,2) == 0
                        % Can be NV-pairs or frame+struct
                        if isstruct(varargin{end})
                            % Frame
                            frame = validatestring(varargin{1},{'grid','world'},className,'coordinate',4);
                            nvPairs = obj.validateNVPairs(className, numLayers, defaults{:}, varargin{2:end});
                        else
                            % NV-pairs
                            frame = 'world';
                            nvPairs = obj.validateNVPairs(className, numLayers, defaults{:}, varargin{:});
                        end
                    else
                        if isstruct(varargin{end})
                            frame = 'world';
                            nvPairs = obj.validateNVPairs(className, numLayers, defaults{:}, varargin{:});
                        else
                            frame = validatestring(varargin{1},{'grid','world'},className,'coordinate',4);
                            nvPairs = obj.validateNVPairs(className, numLayers, defaults{:}, varargin{2:end});
                        end
                    end
                else
                    frame = 'world';
                    nvPairs = obj.validateNVPairs(className, numLayers, defaults{:}, varargin{:});
                end
            end
        end
    end
        
    methods
        function move(obj, displacement,varargin)
            %move Move the map layer using displacement in meters.
            %The following syntaxes can be used:
            %   move(MAP, XYTranslate) move the MAP relative to world frame
            %   with translation(XYTranslate) in meters in x-y directions.
            %   Fill the uninitialized cells with MAP.DefaultValue
            %
            %   move(__, NAME-VALUE) additionally accepts name value pairs that defines
            %   how to fill the newly discovered map region:
            %       "SyncWith"                  - Fill the new map region
            %       with values from another multi-layer map at those world
            %       coordinates with corresponding map layers that match
            %       map layer name.
            %
            %       "DownSamplePolicy"          - When syncing with a
            %       higher resolution map, user can define a downsample
            %       policy. The possible values are {"Max", "AbsMax",
            %       "Mean"}. User can choose DownSamplePolicy to be 
            %       "Max" to keep the maximum  values
            %       "Mean" to keep the mean values, or
            %       "AbsMax" to keep values with absolute maximum. 
            %       Default: "Max"
            %
            %       "FillWith"                  - Fill the uninitialized
            %       new map region with a user specified value instead of
            %       MAP.DefaultValue

            narginchk(2,8);
            numLayers = numel(obj.Layers);
            validateattributes(displacement, {'numeric'}, {'nonempty', 'real',...
                'nonnan', 'finite', 'vector', 'numel', 2}, 'move','shift');
            parser = matlabshared.autonomous.core.internal.NameValueParser({'SyncWith','DownSamplePolicy',...
                'FillWith' },{[],'Max',obj.DefaultValue});
            
            parse(parser,varargin{:});
            
            syncLayers = parameterValue(parser,'SyncWith');

            samplePolicy = validatestring(parameterValue(parser,'DownSamplePolicy'),{'AbsMax','Mean','Max'},'MultiLayerMap','DownSamplePolicy');
            
            fillValue = parameterValue(parser,'FillWith');
            coder.internal.assert((length(fillValue) == numLayers),'shared_autonomous:multilayermap:ExpectedCellArrayScalar','''FillWith'' Value');
            validateattributes(fillValue, {'cell'},{'nonempty'}, 'move', 'fillValue');
            
            % Find cells to move by comparing new location with previous
            % location. If they are in different cells, update the map,
            % otherwise just update obj.LocalOriginInWorld
            res   = obj.SharedProperties.Resolution;
            lOrig = obj.SharedProperties.LocalOriginInWorld;
            
            cells = obj.counterFPECeil((lOrig+displacement)*res-1/2) - ...
                    obj.counterFPECeil(lOrig*res-1/2);
            
            if any(cells ~= 0)
                
                obj.Index.shift([-cells(2),cells(1)]);
                
                if isempty(syncLayers)
                    for k = 1:numLayers
                        validateattributes(fillValue{k}, {'numeric'},{'scalar','real'}, 'move', 'fillValue');
                        obj.Layers{k}.fillNewRegionsWithScalar(fillValue{k});
                    end
                else
                    sync(obj,syncLayers,samplePolicy,fillValue);
                end
            end
            obj.Index.resetNewRegions();
            obj.LocalOriginInWorld = (obj.removeFPE(lOrig*res) + obj.removeFPE(displacement*res))/res;
        end
        
        function newObj = copy(obj)
        %copy creates a deep copy of the object
            
            % Create dummy map for copy
            if isempty(obj.LayerNamesInternal)
                % The size of the map cannot be passed when we absolve
                % mapValues if a map is empty. So using grid size
                % initialization while copying.
                newObj = matlabshared.autonomous.internal.MultiLayerMap(obj.LayerNamesInternal,...
                    obj.GridSize(1),obj.GridSize(2),'g');
            else
                % This syntax guarantees the data type of all the layers in
                % dummy map matches the original map
                newObj = matlabshared.autonomous.internal.MultiLayerMap(obj);
            end
        end
    end
    
    methods (Hidden)
        function [status] = addlayer(obj,varargin)
            %addLayer adds new layers named LAYERNAMES filled with constVal and
            % dataType of layer will be equal to type of constVal
            
            % Supported signatures are below
            %   addlayer(MAP, LAYERNAMES, DEFAULTVALS) adds new layers named
            %   LAYERNAMES filled with default values. Added layer's datatype
            %   is equal to the type of corresponding DEFAULTVAL. LAYERNAMES can be
            %   string array or cell array of character vectors. DEFAULTVALS
            %   specify default values for added layers and is cell array of
            %   scalars with length equal to LAYERNAMES.
            %
            %   addlayer(MAP, LAYERNAMES, DEFAULTVALS, CELLDATASIZE) adds new 
            %   layers and allocates memory for matrices whose cell size is
            %   determined by CELLDATASIZE. CELLDATASIZE can either be an array
            %   of positive integers applied to all new layers, or a 
            %   cell-array containing numeric arrays for each layer
            %   individually. Each added layer's datatype is equal to 
            %   the type of corresponding DEFAULTVAL. LAYERNAMES can be
            %   string array or cell array of character vectors. DEFAULTVALS
            %   specify default values for added layers and is cell array of
            %   scalars with length equal to LAYERNAMES.
            %
            %   addlayer(MAP, MAPLAYERS) adds MapLayer handles to the MAP,
            %   the MapLayer must have the same size, resolution, coordinate
            %   definitions and data type as the multi-layer map. addlayer
            %   returns double row vector status of length equals to LAYERNAMES.
            %   The value at the corresponding index of each LAYERNAME or
            %   MAPLAYER will have one of the values mentioned below:
            %   0 - layer added without any issues
            %   1 - layer not added due to resolution mismatch
            %   2 - layer not added due to GridSize mismatch
            %   3 - layer not added due to GridOriginInLocal mismatch
            %   4 - layer not added due to LocalOriginInWorld mismatch
            %   5 - layer not added because it's already present in the map
            
            narginchk(2,4);
            validateattributes(varargin{1}, {'cell','string'}, {'nonempty'}, 'addlayer','LAYERNAMES or MAPLAYERS');
            
            if iscell(varargin{1})
                for k = 1:length(varargin{1})
                    validateattributes(varargin{1}{k}, {'char','matlabshared.autonomous.internal.MapLayer','MapLayerInternal'}, {'nonempty'}, 'addlayer','LAYERNAMES or MAPLAYERS');
                end
            end
            
            lExist = checkLayerExists(obj, varargin{1});
            
            len = length(varargin{1});
            status = zeros(1,len);
            cellDataSize = {1};
            if nargin < 3
            %For addlayer syntax: addlayer(MAP, MAPLAYERS)
                dVals = repmat({nan},1,len);
            else
            %For addlayer syntax: addlayer(MAP, LAYERNAMES, DEFAULTVALS, ...)
                validateattributes(varargin{2}, {'cell'}, {'numel',len}, 'addlayer','DEFAULTVALS');
                dVals = cell(1,len);
                for k = 1:len
                    validateattributes(varargin{2}{k}, {'numeric','logical'}, {'nonempty', 'real',...
                        'nonnan', 'finite', 'scalar'}, 'MultiLayerMap','DEFAULTVALS cell contents');
                    dVals = varargin{2};
                end
                
                if nargin == 4
                %For addlayer syntax: addlayer(MAP, LAYERNAMES, DEFAULTVALS, CELLDATASIZE)
                    if iscell(varargin{3})
                        cellDataSize = varargin{3};
                        nCell = numel(cellDataSize);
                        coder.internal.errorIf(len ~= nCell, 'shared_autonomous:multilayermap:InvalidNumDataSizeInput', len);
                    else
                        cellDataSize = repmat({varargin{3}},len,1);
                    end
                else
                    cellDataSize = repmat({1},len,1);
                end
            end
            
            isMapLayer = false;
            if obj.isaLayer(varargin{1}{1})
                isMapLayer = true;
            else
                lNames = varargin{1};
            end
            
            gSize = obj.SharedProperties.GridSize;
            res   = obj.SharedProperties.Resolution;
            gOrig = obj.SharedProperties.GridOriginInLocal;
            lOrig = obj.SharedProperties.LocalOriginInWorld;
            
            for k = 1:len
                if lExist(k)
                    % Filling status 5 when tried adding a layer which is already
                    % present in the map.
                    status(k) = 5;
                else
                    if isMapLayer
                        mLayer = varargin{1}{k};
                        [sim,sts] = checkSimilarityOfLayer(obj,mLayer);
                    else
                        mLayer = matlabshared.autonomous.internal.MapLayer(gSize(1),gSize(2),cellDataSize{k},...
                            'g','Resolution',res,'GridOriginInLocal',gOrig,...
                            'LocalOriginInWorld',lOrig,'DefaultValue',dVals{k},'LayerName',lNames{k});
                        sim = true;
                        sts = 0;
                    end
                    if sim
                        mLayer.HasParent = true;
                        mLayer.Index = obj.Index;
                        obj.Layers{end+1} = mLayer;
                        obj.LayerNamesInternal{end+1} = char(mLayer.LayerName);
                        obj.NumLayers = obj.NumLayers + 1;
                    else
                        status(k) = sts;
                    end
                end
            end
            
        end
        
        function removed = rmlayer(obj,layerNames)
            %rmlayer removes map layers identified by LAYERNAMES, which is
            %an array of strings or cell array of character vectors.
            %   rmlayer(MAP, LAYERNAMES) removes map layers identified by
            %   LAYERNAMES, which is an array of strings.
            %
            %   Note: this function is not code-generation compatible

            narginchk(2,2);
            [removed,lId] = checkLayerExists(obj, layerNames);
            
            flid = find(lId);
            for k = 1:length(flid)
                % after removing the map layer from multimap the enables
                % individual map layer move 
                obj.Layers{flid(k)}.HasParent = false;
            end
            obj.Layers = obj.Layers(~lId);
            obj.LayerNamesInternal = obj.LayerNamesInternal(~lId);
            obj.NumLayers = obj.NumLayers - length(flid);
            
        end
        
        function val = getValueLocal(obj,varargin)
            %getValueLocal Read from the map layer using local coordinates
            %One of the following syntaxes can be used.
            %   VAL = getValueLocal(MAP) reads all data from the MAP grid as
            %   cell array of matrices with length equal to number of
            %   layers.
            %
            %   VAL = getValueLocal(MAP, XY) reads grid values from the
            %   given [Nx2] local coordinates(XY) from all the layers and
            %   return the values as cell array filled with [Nx1] vectors.
            %
            %   VAL = getValueLocal(MAP, XYLowerLeft, WIDTH, HEIGHT) reads
            %   grid values from the rectangular region identified with its
            %   lower left corner local coordinate XYLowLeft and its WIDTH
            %   (in meters) and HEIGHT (in meters) from all the layers. The
            %   value is returned as a  cell array of matrices
            %
            %  The values corresponding to coordinates which lie outside of
            %  grid boundaries will be equal to default values
            
            narginchk(1,4);
            numLayers = numel(obj.Layers);
            if numLayers > 0
                if nargin==1
                % VAL = getValueLocal(MAP)
                    val = cell(1,numLayers);
                    if all(obj.Index.Head==[1,1])
                        for k = 1:numLayers
                            val{k} = reshape(obj.Layers{k}.Buffer.Buffer,obj.Layers{k}.DataSize);
                        end
                    else
                        [region,~] = computeGetBoundaries(obj.Index,[1,1],obj.GridSize);
                        for k = 1:numLayers
                            v = getBaseMatrix(obj.Layers{k},region,obj.GridSize);
                            val{k} = reshape(v,obj.Layers{k}.DataSize);
                            obj.Layers{k}.Buffer.Buffer = v;
                        end
                        obj.Index.Head = [1 1];
                    end
                elseif nargin==2
                % VAL = getValueLocal(MAP, XY)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2, 'nonnan','finite'}, 'getValueLocal', 'XY');
                    localGridInd =  obj.Layers{1}.local2gridImpl(varargin{1});
                    val = getValueAtIndicesInternal(obj,localGridInd);
                elseif nargin==3
                    coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueLocal');
                elseif nargin==4
                % VAL = getValueLocal(MAP, XYLowerLeft, WIDTH, HEIGHT)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2, 'nrows', 1,'nonnan', 'finite'}, 'getValueLocal', 'XYLowerLeft');
                    validateattributes(varargin{2}, {'numeric'}, ...
                        {'real', 'scalar','nonnan', 'finite','positive'}, 'getValueLocal', 'Width');
                    validateattributes(varargin{3}, {'numeric'}, ...
                        {'real', 'scalar','nonnan','finite','positive'}, 'getValueLocal', 'Height');
                    
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.GridOriginInLocal;
                    [minGrid, ~, rows, cols] = computeBlockCorners(obj.Layers{1}, bottomLeftVec, varargin{2}, varargin{3});
                    
                    val = getBlocksInternal(obj,minGrid,rows,cols);
                end
            else
                val = cell(1,0);
            end
        end
        
        function val = getValueWorld(obj,varargin)
            %getValueWorld Read from the map layer using world coordinates
            %One of the following syntaxes can be used.
            %   VAL = getValueWorld(MAP) reads all data from the MAP grid as
            %   cell array of matrices with length equal to number of
            %   layers.
            %
            %   VAL = getValueWorld(MAP, XY) reads grid values from the
            %   given [Nx2] world coordinates(XY) from all the layers and
            %   return the values as cell array filled with [Nx1] vectors.
            %
            %   VAL = getValueWorld(MAP, XYLowerLeft, WIDTH, HEIGHT) reads
            %   grid values from the rectangular region identified with its
            %   lower left corner world coordinate XYLowLeft and its WIDTH
            %   (in meters) and HEIGHT (in meters) from all the layers. The
            %   value is returned as a  cell array of matrices
            %
            %  The values corresponding to coordinates which lie outside of
            %  grid boundaries will be equal to default values
            
            narginchk(1,4);
            numLayers = numel(obj.Layers);
            if numLayers > 0
                if nargin==1
                % VAL = getValueWorld(MAP)
                    val = cell(1,numLayers);
                    if all(obj.Index.Head==[1,1])
                        for k = 1:numLayers
                            val{k} = reshape(obj.Layers{k}.Buffer.Buffer,obj.Layers{k}.DataSize);
                        end
                    else
                        [region,~] = computeGetBoundaries(obj.Index,[1,1],obj.GridSize);
                        for k = 1:numLayers
                            v = getBaseMatrix(obj.Layers{k},region,obj.GridSize);
                            val{k} = reshape(v,obj.Layers{k}.DataSize);
                            obj.Layers{k}.Buffer.Buffer = v;
                        end
                        obj.Index.Head = [1 1];
                    end
                elseif nargin==2
                % VAL = getValueWorld(MAP, XY)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2,'nonnan','finite'}, 'getValueWorld', 'XY');
                    localGridInd =  obj.Layers{1}.world2gridImpl(varargin{1});
                    val = getValueAtIndicesInternal(obj,localGridInd);
                elseif nargin==3
                    coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueWorld');
                elseif nargin==4
                % VAL = getValueWorld(MAP, XYLowerLeft, WIDTH, HEIGHT)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2, 'nrows', 1,'nonnan','finite'}, 'getValueWorld', 'XYLowerLeft');
                    validateattributes(varargin{2}, {'numeric'}, ...
                        {'real', 'scalar','nonnan','finite','positive'}, 'getValueWorld', 'Width');
                    validateattributes(varargin{3}, {'numeric'}, ...
                        {'real', 'scalar','nonnan','finite','positive'}, 'getValueWorld', 'Height');
                    
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.LocalOriginInWorld - obj.GridOriginInLocal;
                    [minGrid, ~, rows, cols] = computeBlockCorners(obj.Layers{1}, bottomLeftVec, varargin{2}, varargin{3});
                    
                    val = getBlocksInternal(obj,minGrid,rows,cols);
                end
            else
                val = cell(1,0);
            end
        end
        
        function val = getValueGrid(obj,varargin)
            %getValueGrid Read from the map layer using grid coordinates
            %
            %One of the following syntaxes can be used.
            %   VAL = getValueGrid(MAP) reads all data from the MAP grid as
            %   cell array of matrices with length equal to number of
            %   layers.
            %
            %   VAL = getValueGrid(MAP, IJ) reads grid values from the
            %   given [Nx2] grid coordinates(IJ) from all the layers and
            %   return the values as cell array filled with [Nx1] vectors.
            %
            %   VAL = getValueGrid(MAP, TOPLEFTIJ, ROWS, COLS) reads
            %   grid values from the rectangular region defined by its
            %   top left corner grid coordinate, TOPLEFTIJ, and the number
            %   of ROWS and COLS. The value is returned as a  cell array of
            %   matrices.
            %
            %  The values corresponding to coordinates which lie outside of
            %  grid boundaries will be equal to default values

            narginchk(1,4);
            numLayer = numel(obj.Layers);
            if numLayer > 0
                if nargin==1
                % VAL = getValueGrid(MAP)
                    val = cell(1,numLayer);
                    if all(obj.Index.Head==[1,1])
                        for k = 1:numLayer
                            val{k} = reshape(obj.Layers{k}.Buffer.Buffer,obj.Layers{k}.DataSize);
                        end
                    else
                        [region,~] =computeGetBoundaries(obj.Index,[1,1],obj.GridSize);
                        for k = 1:numLayer
                            v = getBaseMatrix(obj.Layers{k},region,obj.GridSize);
                            val{k} = reshape(v,obj.Layers{k}.DataSize);
                            obj.Layers{k}.Buffer.Buffer = v;
                        end
                        obj.Index.Head = [1 1];
                    end
                elseif nargin==2
                % VAL = getValueGrid(MAP, IJ)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2,'nonnan','finite'}, 'getValueGrid', 'IJ');
                    val = getValueAtIndicesInternal(obj,varargin{1});
                elseif nargin==3
                    coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','getValueGrid');
                elseif nargin==4
                % VAL = getValueGrid(MAP, TOPLEFTIJ, ROWS, COLS)
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'ncols', 2, 'nrows', 1,'nonnan','finite'}, 'getValueGrid', 'TopLeftIJ');
                    validateattributes(varargin{2}, {'numeric'}, ...
                        {'real', 'scalar','nonnan','finite','positive'}, 'getValueGrid', 'rows');
                    validateattributes(varargin{3}, {'numeric'}, ...
                        {'real', 'scalar','nonnan','finite','positive'}, 'getValueGrid', 'cols');
                    minGrid = varargin{1};
                    val = getBlocksInternal(obj,minGrid,varargin{2},varargin{3});
                end
            else
                val = cell(1,0);
            end
        end

        function setValueLocal(obj,varargin)
            %setValueLocal Write into the map layer using local coordinates
            %
            %One of the following syntaxes can be used:
            %   setValueLocal(MAP, CELLARRAYSCALAR) initialize all cells in the MAP
            %   to scalar value contained in the CELLARRAYSCALAR   
            %
            %   setValueLocal(MAP, MATRIX) writes MATRIX into the map. The
            %   MATRIX is [MX1] cell array of 2D matrices of the same size
            %   as the map grid size.
            %
            %   setValueLocal(MAP, LowerLeftXY, MATRIX) writes a [Mx1] cell
            %   array MATRIX into the rectangular map region identified
            %   with its lower left local coordinate (LowerLeftXY). The size
            %   of the region is determined by the MAP size and resolution
            %   and the MATRIX size. MATRIX data that goes out of MAP
            %   boundary is ignored.
            %
            %   setValueLocal(MAP, LowerLeftXY, CELLARRAYSCALAR, Width,Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left local coordinate (LowerLeftXY) and its
            %   size as Width (in meters) X Height (in meters). For each
            %   layer of the map, the region is overwritten with scalar
            %   from CELLARRAYSCALAR.
            %
            %   setValueLocal(MAP, XYCoordinates, VAL) writes a [Mx1] scalar
            %   or [Nx1] vector of values VAL into cells identified by
            %   [Nx2] map local coordinates (XYCoordinates).
            %
            %   setValueLocal(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. The OTHERMAP
            %   must be MultiLayerMap with all the layers present in the
            %   map in it. If multiple cells in OTHERMAP corresponds to the
            %   same cell in MAP, the value is computed using method
            %   defined in "DownSamplePolicy". User can choose
            %   "Max" to keep the maximum values, 
            %   "Mean" to keep the mean values, 
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.
            
            narginchk(2,5);
            numLayers = numel(obj.Layers);
            if nargin==2
            % setValueLocal(MAP, CELLARRAYSCALAR/MATRIX)
                validateattributes(varargin{1}, {'cell'}, ...
                    {'real', 'nonempty'}, 'setValueLocal', 'CellArrayScalar or Matrix');
                setValueGrid(obj,varargin{1});
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan','finite'}, 'setValueLocal', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'cell'}, ...
                    {}, 'setValueLocal', 'Matrix or Val');
                refSize = size(varargin{2}{1});
                if (size(varargin{1},1) == 1)
                % setValueLocal(MAP, LowerLeftXY, MATRIX)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','Matrix');
                    end
                    for k = 1:numLayers
                        if any(size(varargin{2}{k}) ~= refSize)
                            coder.internal.error(...
                                'shared_autonomous:multilayermap:InvalidMatrixInput','Matrix');
                        end
                    end
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.GridOriginInLocal;

                    if numLayers > 0
                        minGrid = computeBlockTopfLeft(obj.Layers{1}, bottomLeftVec, size(varargin{2}{1},1));
                        setBlockInternal(obj,minGrid,varargin{2});
                    end
                else
                % setValueLocal(MAP, XYCoordinates, VAL)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','VAL');
                    end
                    for k = 1:numLayers
                        validateattributes(varargin{2}{k}, {'numeric'}, ...
                            {'real', 'nrows', size(varargin{1},1)}, ...
                            'setValueLocal', 'VAL');
                    end
                    gridInd = obj.Layers{1}.local2gridImpl(varargin{1});
                    setValueAtIndicesInternal(obj,gridInd,varargin{2});
                end
            elseif nargin==4
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','setValueLocal');
            elseif nargin==5
            % setValueLocal(MAP, LowerLeftXY, CELLARRAYSCALAR, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan','finite'}, 'setValueLocal', 'LowerLeftXY');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan','finite','positive'}, 'setValueLocal', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan','finite','positive'}, 'setValueLocal', 'Height');
                if (length(varargin{2}) ~= numLayers)
                    coder.internal.error(...
                        'shared_autonomous:multilayermap:InvalidLength','CellArrayScalar');
                end
                for k = 1:numLayers
                    coder.internal.assert((isscalar(varargin{2}{k})&&(islogical(varargin{2}{k})||isnumeric(varargin{2}{k}))),...
                        'shared_autonomous:multilayermap:ExpectedCellArrayScalar','CellArrayScalar');
                end

                if numLayers > 0
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.GridOriginInLocal;

                    [minGrid, ~, rows, cols] = computeBlockCorners(obj.Layers{1}, bottomLeftVec, varargin{3}, varargin{4});
                    setBlockWithScalarInternal(obj,minGrid,rows,cols,varargin{2});
                end
            end
        end
        
        function setValueWorld(obj,varargin)
            %setValueWorld Write into the map layer using world coordinates
            %
            %One of the following syntaxes can be used:
            %   setValueWorld(MAP, CELLARRAYSCALAR) initialize all cells in
            %   the MAP to scalar value contained in the CELLARRAYSCALAR
            %
            %   setValueWorld(MAP, MATRIX) writes MATRIX into the map. The
            %   MATRIX is [MX1] cell array of 2D matrices of the same size
            %   as the map grid size.
            %
            %   setValueWorld(MAP, LowerLeftXY, MATRIX) writes a [Mx1] cell
            %   array MATRIX into the rectangular map region identified
            %   with its lower left world coordinate (LowerLeftXY). The size
            %   of the region is determined by the MAP size and resolution
            %   and the MATRIX size. MATRIX data that goes out of MAP
            %   boundary is ignored.
            %
            %   setValueWorld(MAP, LowerLeftXY, CELLARRAYSCALAR, Width,Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left world coordinate (LowerLeftXY) and its
            %   size as Width (in meters) X Height (in meters). For each
            %   layer of the map, the region is overwritten with scalar
            %   from CELLARRAYSCALAR.
            %
            %   setValueWorld(MAP, XYCoordinates, VAL) writes a [Mx1] scalar
            %   or [Nx1] vector of values VAL into cells identified by
            %   [Nx2] map world coordinates (XYCoordinates).
            %
            %   setValueWorld(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. The OTHERMAP
            %   must be MultiLayerMap with all the layers present in the
            %   map in it. If multiple cells in OTHERMAP corresponds to the
            %   same cell in MAP, the value is computed using method
            %   defined in "DownSamplePolicy". User can choose
            %   "Max" to keep the maximum values, 
            %   "Mean" to keep the mean values, 
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.
            narginchk(2,5);
            numLayers = numel(obj.Layers);
            if nargin==2
            % setValueWorld(MAP, CELLARRAYSCALAR/MATRIX)
                validateattributes(varargin{1}, {'cell'}, ...
                    {'real', 'nonempty'}, 'setValueWorld', 'CellArrayScalar or Matrix');
                setValueGrid(obj,varargin{1});
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan','finite'}, 'setValueWorld', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'cell'}, ...
                    {}, 'setValueWorld', 'Matrix or Val');
                refSize = size(varargin{2}{1});
                if (size(varargin{1},1) == 1)
                % setValueWorld(MAP, LowerLeftXY, MATRIX)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','Matrix');
                    end
                    for k = 1:numLayers
                        if any(size(varargin{2}{k}) ~= refSize)
                            coder.internal.error(...
                                'shared_autonomous:multilayermap:InvalidMatrixInput','Matrix');
                        end
                    end
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.LocalOriginInWorld - obj.GridOriginInLocal;

                    if numLayers > 0
                        minGrid = computeBlockTopfLeft(obj.Layers{1}, bottomLeftVec, size(varargin{2}{1},1));
                        setBlockInternal(obj,minGrid,varargin{2});
                    end
                else
                % setValueWorld(MAP, XYCoordinates, VAL)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','VAL');
                    end
                    for k = 1:numLayers
                        validateattributes(varargin{2}{k}, {'numeric'}, ...
                            {'real', 'nrows', size(varargin{1},1)}, ...
                            'setValueWorld', 'VAL');
                    end
                    gridInd = obj.Layers{1}.world2gridImpl(varargin{1});
                    setValueAtIndicesInternal(obj,gridInd,varargin{2});
                end
            elseif nargin==4
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','setValueWorld');
            elseif nargin==5
            % setValueWorld(MAP, LowerLeftXY, CELLARRAYSCALAR, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan','finite'}, 'setValueWorld', 'LowerLeftXY');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar','nonnan','finite','positive'}, 'setValueWorld', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan','finite','positive'}, 'setValueWorld', 'Height');
                if (length(varargin{2}) ~= numLayers)
                    coder.internal.error(...
                        'shared_autonomous:multilayermap:InvalidLength','CellArrayScalar');
                end
                for k = 1:numLayers
                    coder.internal.assert((isscalar(varargin{2}{k})&&(islogical(varargin{2}{k})||isnumeric(varargin{2}{k}))),...
                        'shared_autonomous:multilayermap:ExpectedCellArrayScalar','CellArrayScalar');
                end

                if numLayers > 0
                    % Find cell corresponding to bottom left corner
                    bottomLeftVec = varargin{1} - obj.LocalOriginInWorld - obj.GridOriginInLocal;

                    [minGrid, ~, rows, cols] = computeBlockCorners(obj.Layers{1}, bottomLeftVec, varargin{3}, varargin{4});
                    setBlockWithScalarInternal(obj,minGrid,rows, cols,varargin{2});
                end
            end
        end
        
        function setValueGrid(obj,varargin)
            %setValueGrid Write into the map layer using grid coordinates
            %
            %One of the following syntaxes can be used:
            %   setValueGrid(MAP, CELLARRAYSCALAR) initialize all cells in
            %   the MAP to scalar value contained in the CELLARRAYSCALAR
            %
            %   setValueGrid(MAP, MATRIX) writes MATRIX into the map. The
            %   MATRIX is [MX1] cell array of 2D matrices of the same size
            %   as the map grid size.
            %
            %   setValueGrid(MAP, LowerLeftXY, MATRIX) writes a [Mx1] cell
            %   array MATRIX into the rectangular map region identified
            %   with its lower left grid coordinate (LowerLeftXY). The size
            %   of the region is determined by the MAP size and resolution
            %   and the MATRIX size. MATRIX data that goes out of MAP
            %   boundary is ignored.
            %
            %   setValueGrid(MAP, LowerLeftXY, CELLARRAYSCALAR, Width,Height)
            %   writes a SCALAR into the rectangular map region identified
            %   with its lower left grid coordinate (LowerLeftXY) and its
            %   size as Width (number of columns) X Height (number of
            %   rows). For each layer of the map, the region is overwritten
            %   with scalar from CELLARRAYSCALAR.
            %
            %   setValueGrid(MAP, XYCoordinates, VAL) writes a [Mx1] scalar
            %   or [Nx1] vector of values VAL into cells identified by
            %   [Nx2] map grid coordinates (XYCoordinates).
            %
            %   setValueGrid(MAP, OTHERMAP, "DownSamplePolicy", "Max")
            %   overwrites cells in MAP with cells in OTHERMAP that
            %   corresponds to the same world coordinates. The OTHERMAP
            %   must be MultiLayerMap with all the layers present in the
            %   map in it. If multiple cells in OTHERMAP corresponds to the
            %   same cell in MAP, the value is computed using method
            %   defined in "DownSamplePolicy". User can choose
            %   "Max" to keep the maximum values, 
            %   "Mean" to keep the mean values, 
            %   "AbsMax" to keep values with absolute maximum.
            %   Default: "Max"
            %
            %   note: write operation cast the VAL into the map's value
            %   data type if VAL is of a different data type.
            
            narginchk(2,5);
            numLayers = numel(obj.Layers);
            if nargin==2
            % setValueGrid(MAP, CELLARRAYSCALAR/MATRIX)
                validateattributes(varargin{1}, {'cell'}, ...
                    {'real', 'nonempty'}, 'setValueGrid', 'CellArrayScalar or Matrix');
                if (length(varargin{1}) ~= numLayers)
                    coder.internal.error(...
                        'shared_autonomous:multilayermap:InvalidLength','CellArrayScalar or Matrix');
                end
                if isscalar(varargin{1}{1})
                    reg = obj.Index.toBaseMatrixIndex([1,1], obj.GridSize);
                    for k = 1:numLayers
                        coder.internal.assert((isscalar(varargin{1}{k})&&(islogical(varargin{1}{k})||isnumeric(varargin{1}{k}))),...
                            'shared_autonomous:multilayermap:ExpectedCellArrayScalar','CellArrayScalar');
                        setBaseMatrixBlockWithScalar(obj.Layers{k},reg,varargin{1}{k});
                    end
                else
                    for k = 1:numLayers
                        if any(size(varargin{1}{k}) ~= obj.Layers{k}.DataSize)
                            coder.internal.error(...
                                'shared_autonomous:multilayermap:InvalidMatrixInput','Matrix');
                        end
                        setValueGrid(obj.Layers{k},[1,1],varargin{1}{k});
                    end
                end
            elseif nargin==3
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan','finite'}, 'setValueGrid', 'LowerLeftXY or XYCoordinates');
                validateattributes(varargin{2}, {'cell'}, ...
                    {}, 'setValueGrid', 'Matrix or Val');
                refSize = size(varargin{2}{1});
                if size(varargin{1},1) == 1
                % setValueGrid(MAP, LowerLeftXY, MATRIX)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','Matrix');
                    end
                    for k = 1:numLayers
                        if any(size(varargin{2}{k}) ~= refSize)
                            coder.internal.error(...
                                'shared_autonomous:multilayermap:InvalidMatrixInput','Matrix');
                        end
                    end
                    setBlockInternal(obj,varargin{1},varargin{2});
                else
                % setValueGrid(MAP, XYCoordinates, VAL)
                    if (length(varargin{2}) ~= numLayers)
                        coder.internal.error(...
                            'shared_autonomous:multilayermap:InvalidLength','VAL');
                    end
                    for k = 1:numLayers
                        validateattributes(varargin{2}{k}, {'numeric'}, ...
                            {'real', 'nrows', size(varargin{1},1)}, ...
                            'setValueGrid', 'VAL');
                    end
                    setValueAtIndicesInternal(obj,varargin{1},varargin{2});
                end
            elseif nargin==4
                coder.internal.error('shared_autonomous:maplayer:InvalidSyntax','setValueGrid');
            elseif nargin==5
            % setValueGrid(MAP, LowerLeftXY, CELLARRAYSCALAR, Width, Height)
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'nrows', 1,'nonnan','finite'}, 'setValueGrid', 'LowerLeftXY');
                if (size(varargin{2},2) ~= numLayers)||(~iscell(varargin{2}))
                    coder.internal.error(...
                        'shared_autonomous:multilayermap:InvalidLength','CellArrayScalar');
                end
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'scalar', 'finite','positive'}, 'setValueGrid', 'Width');
                validateattributes(varargin{4}, {'numeric'}, ...
                    {'real', 'scalar','nonnan','finite','positive'}, 'setValueGrid', 'Height');
                lowerGrid = varargin{1};
                if (length(varargin{2}) ~= numLayers)
                    coder.internal.error(...
                        'shared_autonomous:multilayermap:InvalidLength','CellArrayScalar');
                end
                for k = 1:numLayers
                    coder.internal.assert((isscalar(varargin{2}{k})&&(islogical(varargin{2}{k})||isnumeric(varargin{2}{k}))),...
                        'shared_autonomous:multilayermap:ExpectedCellArrayScalar','CellArrayScalar');
                end
                setBlockWithScalarInternal(obj,lowerGrid,varargin{4},varargin{3},varargin{2});
            end
            
        end
    end
    
    
    methods
        function set.DefaultValue(obj, val)
            validateattributes(val, {'cell'}, {}, 'DefaultValue');
            numLayers = numel(obj.Layers);
            coder.internal.assert((numel(val) == numLayers),...
                'shared_autonomous:multilayermap:ExpectedCellArrayScalar','''DefaultValue''');
            for k = 1:numLayers
                obj.Layers{k}.DefaultValue = val{k};
                obj.Layers{k}.Buffer.ConstVal = obj.Layers{k}.DefaultValueInternal;
            end
        end
        
        function layerNames = get.LayerNames(obj)
            n = numel(obj.Layers);
            layerNames = cell(1,n);
            for i = 1:n
                layerNames{i} = obj.Layers{i}.LayerName;
            end
        end

        function val = get.DefaultValue(obj)
            numLayers = numel(obj.Layers);
            val = cell(1,numLayers);
            for k = 1:numLayers
                val{k} = obj.Layers{k}.DefaultValue;
            end
        end
        
        function dataType = get.DataType(obj)
            numLayers = numel(obj.Layers);
            dataT= cell(1,numLayers);
            for k = 1:numLayers
                dataT{k} = class(obj.Layers{k}.DefaultValue);
            end
            dataType = convertCharsToStrings(dataT);
        end
        
        function n = get.NumLayers(obj)
            n = numel(obj.Layers);
        end
    end
    
    methods (Access = ?matlabshared.autonomous.map.internal.InternalAccess)
        function internalValue = setDefaultValueConversion(obj, value)
            numLayers = numel(obj.Layers);
            coder.internal.assert((numel(value) == numLayers),...
                'shared_autonomous:multilayermap:ExpectedCellArrayScalar','''DefaultValue''');
            internalValue = cell(1,numLayers);
            for i = 1:numLayers
                internalValue{i} = obj.Layers{i}.setDefaultValueConversion(value{i});
            end
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
            ?matlab.unittest.TestCase})
        function [similar,k] = checkSimilarityOfLayer(obj,layer)
            %checkSimilarityOfLayer returns true if layer has same resolution,
            %GridOriginInLocal, LocalOriginInWorld and GridSize as obj
            
            similar = true;
            % Properties to check
            props = {'Resolution', 'GridSize', 'GridOriginInLocal', 'LocalOriginInWorld'};
            % status 6 represents invalid layer input to checkSimilarity
            % function. This status will never be output of add layer
            % function because invalid map layers will not be passed from
            % addlayer. 0-5 are valid status ids of add layer function.
            % So using 6 to represent this case. This status is useful for
            % methods other than addlayer.
            k = 6;
            if obj.isaLayer(layer)
                for k = 1:length(props)
                    if ~isequal(obj.SharedProperties.(props{k}),layer.SharedProperties.(props{k}))
                        similar = false;
                        break;
                    end
                end
            else
                similar = false;
            end
        end
        
        function [layerExists,layerId] = checkLayerExists(obj, varargin)
            %checkLayerExists returns true if a layer with specific layer
            % exists in MultiLayerMap and its corresponding linear index.
            % It can be used using syntax checkLayerExists(map, layers).
            % layers can be string array, cell array of character vectors,
            % cell array of map layers.
            
            len = length(varargin{1});
            layerExists = false(1,len);
            layerId = zeros(1,len);
            if obj.isaLayer(varargin{1}{1})
                lNames = cell(1,len);
                for k = 1:len
                    lNames{k} = char(varargin{1}{k}.LayerName);
                end
            else
                if iscellstr(varargin{1})
                    lNames = varargin{1};
                else
                    validateattributes(varargin{1},{'char','string'},{},'MultiLayerMap','LayerNames');
                    if isstring(varargin{1})
                        lNames = cell(1,len);
                        for k = 1:length(varargin{1})
                            lNames{k} = char(varargin{1}(k));
                        end
                    else
                        lNames = cell(1,1);
                        lNames{1} = varargin{1};
                    end
                end
            end
            numLayers = numel(obj.Layers);
            for k1 = 1:len
                for k2 = 1:numLayers
                    if strcmp(lNames{k1}, obj.LayerNamesInternal{k2})
                        layerExists(k1) = true;
                        layerId(k2) = k2;
                        break;
                    end
                end
            end
        end
        
        function setIndex(obj,idx)
            numLayers = numel(obj.Layers);
            for k = 1:numLayers
                obj.Layers{k}.Index = idx;
            end
            obj.Index = idx;
        end
        
        function val = getBlocksInternal(obj,topLeftIJ,rows,cols)
            %getBlockInternal returns blocks from multiple layers filled
            %with grid values at regions within grid boundaries and with
            %default value at all other regions
            
            botRightIJ = topLeftIJ+[rows cols]-1;
            uLeft = max(topLeftIJ,[1 1]);
            bRight = min(botRightIJ,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            numLayers = numel(obj.Layers);
            val = cell(1,numLayers);
            if all(sz>0)
                [region,blockSize] = computeGetBoundaries(obj.Index,uLeft,bRight);
                for k = 1:numLayers
                    % Allocate block with default values
                    val{k} = obj.Layers{k}.allocateExternalBlock(obj.Layers{k}.DefaultValueInternal,rows,cols);

                    % Update region lying inside map bounds
                    val{k}((uLeft(1)-topLeftIJ(1)+1):(uLeft(1)-topLeftIJ(1)+sz(1)),...
                        (uLeft(2)-topLeftIJ(2)+1):(uLeft(2)-topLeftIJ(2)+sz(2)),:) = ...
                        reshape(getBaseMatrix(obj.Layers{k},region,blockSize),blockSize(1),blockSize(2),[]);
                end
            else
                for k = 1:numLayers
                    bSz = obj.Layers{k}.DataSize;
                    bSz(1:2) = [rows cols];
                    val{k} = repmat(obj.Layers{k}.DefaultValueInternal,bSz);
                end
            end
        end
        
        function val = getValueAtIndicesInternal(obj,ind)
            %getValueAtIndices returns values at grid indices specified by
            %ind if they lie within grid boundaries, otherwise default
            %value will be returned
            
            gSize = obj.SharedProperties.GridSize;
            
            % Computing indices within grid limits
            validInd = all(((ind > 0) & [ind(:,1)<=gSize(1),ind(:,2)<=gSize(2)]),2);
            someValid = any(validInd);
            numLayers = numel(obj.Layers);
            if someValid
                gridInd =  obj.Index.toBaseMatrixIndex(ind(validInd,:));
            else
                gridInd = [];
            end
            val = cell(1,numLayers);
            for k = 1:numLayers
                % Initializing val with default values
                val{k} = obj.Layers{k}.allocateExternalBlock(obj.Layers{k}.DefaultValueInternal,size(ind,1),1);
                % Replacing the val at valid indices with its true value
                if someValid
                    val{k}(validInd,:,:) = obj.Layers{k}.getBaseMatrixValuesAtIndices(gridInd);
                end
            end
        end
        
        function setBlockInternal(obj,topLeftIJ,val)
            %setBlockInternal fill the region specified by bottomLeft,
            %topRight and within grid boundaries with specified values in
            %val
            
            botRightIJ = topLeftIJ + size(val{1},[1 2])-1;
            uLeft = max(topLeftIJ,[1,1]);
            bRight = min(botRightIJ,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            numLayers = numel(obj.Layers);
            if all(sz>0)
                region = toBaseMatrixIndex(obj.Index, uLeft, sz);
                for k = 1:numLayers
                    block = val{k}((uLeft(1)-topLeftIJ(1)+1):(uLeft(1)-topLeftIJ(1)+sz(1)),...
                        (uLeft(2)-topLeftIJ(2)+1):(uLeft(2)-topLeftIJ(2)+sz(2)),:);
                    obj.Layers{k}.Buffer.setBaseMatrix(region,block);
                end
            end
        end
        
        function setBlockWithScalarInternal(obj,topLeftIJ,rows,cols,scalarVal)
            %setBlockWithScalarInternal fill the region specified by bottomLeft,
            %topRight and within grid boundaries with specified values in
            %val
            
            uLeft = max(topLeftIJ,[1,1]);
            bRight = min(topLeftIJ+[rows cols]-1,obj.SharedProperties.GridSize);
            
            sz = (bRight-uLeft)+1;
            numLayers = numel(obj.Layers);
            if all(sz>0)
                region = toBaseMatrixIndex(obj.Index, uLeft, sz);
                for k = 1:numLayers
                    obj.Layers{k}.Buffer.setBaseMatrixBlockWithScalar(region,scalarVal{k});
                end
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
            
            % Replacing the val at valid indices with its true value
            len = length(find(validInd));
            gridInd =  obj.Index.toBaseMatrixIndex(ind(validInd,:));
            numLayers = numel(obj.Layers);
            if  len > 0
                for k = 1:numLayers
                    obj.Layers{k}.setBaseMatrixValueAtIndices(gridInd,val{k}(validInd,:,:));
                end
            end
        end
        
        function synced = sync(obj,sourceMap,samplePolicy,fillValue)
            %sync fills new data into the regions effected by move
            %operation.
            % The new values are extracted from the layer. Grid cells
            % overlapping the new regions are extracted and sampled
            % (down/up) to match the resolution of the current map layer.
            % Returns true if some overlapping region exists.
            numLayers = numel(obj.Layers);
            if numLayers > 0
                gSize     = obj.SharedProperties.GridSize;
                res       = obj.SharedProperties.Resolution;
                gOrig     = obj.SharedProperties.GridOriginInLocal;
                locWorld  = obj.SharedProperties.LocalOriginInWorld;
                locWorld_ = obj.SharedProperties.LocalOriginInWorldInternal;
                
                mapWidth  = obj.counterFPECeil(obj.Width*obj.Resolution)/res;
                mapHeight = obj.counterFPECeil(obj.Height*res)/res;
                xLimits = [0 mapWidth]  + gOrig(1);
                yLimits = [0 mapHeight] + gOrig(2);
                
                if obj.Index.DropEntireMap
                    botLeftXY = [locWorld_(1)+xLimits(1)+(obj.Index.NewRegions(4)/res),...
                        locWorld_(2)+yLimits(1)-(obj.Index.NewRegions(3)/res)];
                    obj.Index.Head = [1 1];
                    topLeftIJ = [1,1];
                    setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,mapWidth,mapHeight,fillValue,gSize,samplePolicy);
                    synced = true;
                else
                    synced = false;
                    w = mapWidth;
                    h = abs(obj.Index.NewRegions(3))/res;
                    if all([w,h] > 0)
                        if obj.Index.NewRegions(3) < 0
                            % Extraction, sampling new values and replacing of block
                            % effected by -Y movement
                            botLeftXY = [locWorld_(1)+xLimits(1)+(obj.Index.NewRegions(4)/res),...
                                locWorld_(2)+yLimits(2)];
                            topLeftIJ = [1,1];
                            blockSize = [abs(obj.Index.NewRegions(3)),gSize(2)];
                            blockSize = obj.applyUpperBounds(blockSize, obj.SharedProperties.GridSize);
                            setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,w,h,fillValue,blockSize,samplePolicy);
                        else
                            % Extraction, sampling new values and replacing of block
                            % effected by +Y movement
                            botLeftXY = [locWorld_(1)+xLimits(1)+(obj.Index.NewRegions(4)/res),...
                                locWorld_(2)+yLimits(1)-(abs(obj.Index.NewRegions(3))/res)];
                            topLeftIJ = [gSize(1)-abs(obj.Index.NewRegions(3))+1,1];
                            blockSize = [abs(obj.Index.NewRegions(3)),gSize(2)];
                            blockSize = obj.applyUpperBounds(blockSize, obj.SharedProperties.GridSize);
                            setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,w,h,fillValue,blockSize,samplePolicy);
                        end
                        synced = true;
                    end
                    
                    w = abs(obj.Index.NewRegions(4))/res;
                    h = mapHeight;
                    if all([w,h]>0)
                        if obj.Index.NewRegions(4) < 0
                            % Extraction, sampling new values and replacing of block
                            % effected by -X movement
                            botLeftXY = [locWorld(1)+xLimits(1)+(obj.Index.NewRegions(4)/res),...
                                locWorld(2)+yLimits(1)-(obj.Index.NewRegions(3)/res)];
                            topLeftIJ = [1,1];
                            blockSize = [gSize(1),abs(obj.Index.NewRegions(4))];
                            blockSize = obj.applyUpperBounds(blockSize, obj.SharedProperties.GridSize);
                            setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,w,h,fillValue,blockSize,samplePolicy);
                        else
                            % Extraction, sampling new values and replacing of block
                            % effected by +X movement
                            botLeftXY = [locWorld(1)+xLimits(2),...
                                locWorld(2)+yLimits(1)-(obj.Index.NewRegions(3)/res)];
                            topLeftIJ = [1,gSize(2)-abs(obj.Index.NewRegions(4))+1];
                            blockSize = [gSize(1),abs(obj.Index.NewRegions(4))];
                            blockSize = obj.applyUpperBounds(blockSize, obj.SharedProperties.GridSize);
                            setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,w,h,fillValue,blockSize,samplePolicy);
                        end
                        synced = true;
                    end
                end
            end
        end
        
        function setOverlappingBlockInternal(obj,sourceMap,topLeftIJ,botLeftXY,width,height,fillValue,blockSize,samplePolicy)
        %setOverlappingBlockInternal sets the overlapping area for map
        %layers in OBJ that are also found in LAYERS.
        %
        %   OBJ and LAYERS are MultiLayerMap objects that share an overlapping
        %   region in space defined by the bottom-left corner location in world coords,
        %   BLOCKLOWERLEFT, WIDTH, and HEIGHT. For layers in OBJ that don't
        %   exist in LAYERS, the region is filled with FILLVALUE.
        %   BLOCKSIZE defines the size of the matrix in OBJ covered by the
        %   overlap region and SAMPLEPOLICY determines how a cell is
        %   calculated when resolutions do not match between maps or if
        %   the grids of each map do not align.
            
            % Convert bottomLeft corner to topLeft/bottomRight grid coords.
            gridVecToBotLeft = botLeftXY - sourceMap.SharedProperties.LocalOriginInWorldInternal - sourceMap.SharedProperties.GridOriginInLocal;
            [minGrid, maxGrid, rows, cols] = computeBlockCorners(sourceMap.Layers{1}, gridVecToBotLeft, width, height);
            
            uLeft = max(minGrid,[1,1]);
            bRight = min(maxGrid,sourceMap.SharedProperties.GridSize);
            
            sz = bRight-uLeft+1;
            obj.applyUpperBounds(sz,sourceMap.Layers{1}.SharedProperties.GridSize);
            rsz = [rows cols];

            % Convert to circular buffer coordinates
            setRegions = toBaseMatrixIndex(obj.Index, topLeftIJ, blockSize);
            
            numLayers = numel(obj.Layers);
            if all(sz>0)
                % Loop through all layers of OBJ. If a map with the same name
                % exists in LAYERS, calculate the update matrix using the
                % matching layer, otherwise fill with the provided fillValue.
                [getRegions,bkSize] = computeGetBoundaries(sourceMap.Index,uLeft,bRight);

                % Calculate max footprint of overlap area in source map
                maxSz = obj.SharedProperties.GridSize*(sourceMap.SharedProperties.Resolution/obj.SharedProperties.Resolution);
                rsz = obj.applyUpperBounds(rsz,maxSz);

                gridOffset = computeGridOffset(obj.Layers{1},sourceMap.Layers{1},botLeftXY);

                i0 = (uLeft(1)-minGrid(1)+1);
                i1 = (uLeft(1)-minGrid(1)+sz(1));
                j0 = (uLeft(2)-minGrid(2)+1);
                j1 = (uLeft(2)-minGrid(2)+sz(2));

                for k = 1:numLayers
                    obj.writeFromOther(obj.Layers{k},sourceMap,fillValue{k},rsz,i0,i1,j0,j1,blockSize,setRegions,getRegions,bkSize,samplePolicy,gridOffset)
                end
            else
                % No overlap region found, all layers populated with their
                % corresponding fillValue.
                for k = 1:numLayers
                    block = repmat(fillValue{k},blockSize(1),blockSize(2),size(obj.Layers{k}.Buffer.Buffer,3));
                    obj.Layers{k}.Buffer.setBaseMatrix(setRegions,block);
                end
            end
        end

        function writeFromOther(obj,curLayer,otherMap,fillVal,rsz,i0,i1,j0,j1,blockSize,setRegions,getRegions,bkSize,samplePolicy,gridOffset)
            % Retrieve shared properties that are used frequently.
            res = obj.SharedProperties.Resolution;
            otherRes = otherMap.SharedProperties.Resolution;
            
            idx = find(strcmp(otherMap.LayerNames,curLayer.LayerName), 1);
            if ~isempty(idx)
                nPage = size(curLayer.Buffer.Buffer,3);
                otherLayer = otherMap.Layers{idx};
                if nPage == 1
                    % 2D case handled explicitly to prevent
                    % regressions in existing maps.
                    thisBlock = repmat(fillVal, rsz(1), rsz(2));
                    thisBlock(i0:i1,j0:j1) = getBaseMatrix(otherLayer,getRegions,bkSize);
                    sampledBlock = cast(sample(otherLayer,thisBlock,blockSize,samplePolicy,gridOffset,otherRes,res),'like',curLayer.DefaultValue);
                else
                    thisBlock = repmat(fillVal, rsz(1), rsz(2), nPage);
                    thisBlock(i0:i1,j0:j1,:) = ...
                        reshape(getBaseMatrix(otherLayer,getRegions,bkSize),bkSize(1),bkSize(2),[]);
                    sampledBlock = zeros(blockSize(1), blockSize(2), nPage, 'like', curLayer.DefaultValue);
                    for i = 1:nPage
                        sampledBlock(:,:,i) = sample(otherLayer,thisBlock(:,:,i),blockSize,samplePolicy,gridOffset,otherRes,res);
                    end
                end
                curLayer.Buffer.setBaseMatrix(setRegions,sampledBlock);
            else
                curLayer.Buffer.setBaseMatrixBlockWithScalar(setRegions,fillVal);
            end
        end
    end
    
    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'LayerNamesInternal'};
        end
        
        function defConstructorFcn = getDefaultMapConstructor()
        %getDefaultMapConstructor Creates the default constructor for internal MultiLayerMap
            defConstructorFcn = @matlabshared.autonomous.internal.MapLayer;
        end
        
        function defaultValue = getDefaultDefaultValue()
        %getDefaultDefaultValue Returns the Compile-time constant DefaultValue for multiLayerMap layers
            defaultValue = nan;
        end
    end
end
