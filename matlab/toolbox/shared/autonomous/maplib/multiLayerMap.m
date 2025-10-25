classdef multiLayerMap < MultiLayerMapCPL & ...
                          matlabshared.autonomous.core.internal.CustomDisplay
 %MULTILAYERMAP Manage multiple map layers
 %
 %   The multiLayerMap object groups and stores multiple map layers as
 %   mapLayer, binaryOccupancyMap, or occupancyMap objects.
 %
 %   Once added, map layers can be modified either by using the multiLayerMap 
 %   object functions or by performing actions on individual map layers. Any
 %   modification to common properties will be reflected across both the 
 %   multiLayerMap object and all associated layers.
 %
 %   MULTIMAP = multiLayerMap creates an empty multiLayerMap object
 %   occupying a 10-by-10 meter space with resolution of 1 cell per meter.
 %
 %   MULTIMAP = multiLayerMap(MAPS) creates a multiLayerMap from a P-element
 %   cell-array of map-based objects. Objects combined into a multiLayerMap
 %   must be defined with the same resolution and cover the same region in
 %   space, but can be used to represent different categories of information 
 %   over the shared region.
 %   
 %   MULTIMAP = multiLayerMap(NAMES,MATRICES) takes in two P-element cell arrays, 
 %   NAMES, and MATRICES, and creates a multiLayerMap object comprised of P 
 %   mapLayer objects. NAMES is a cell array of unique layer names, 
 %   specified as string scalars or character vectors. MATRICES is a cell 
 %   array of matrices that each have the same first and second dimensions 
 %   (grid size). The default grid resolution is 1 cell per meter.
 %
 %   MULTIMAP = multiLayerMap(NAMES,W,H) creates a P-layer multiLayerMap  
 %   covering the specified width and height. The default  
 %   grid resolution is 1 cell per meter.
 %
 %   MULTIMAP = multiLayerMap(NAMES,W,H,CELLDIMS) creates a P-layer   
 %   multiLayerMap and specifies the dimensions of the data stored in each
 %   cell of the corresponding mapLayer. CELLDIMS can either be an 
 %   integer-valued array for each map or a P-element cell array 
 %   of integer-arrays.
 %
 %   MULTIMAP = multiLayerMap(NAMES,M,N,'grid') creates a P-layer multiLayerMap
 %   and specifies a grid size of M rows and N columns.
 %
 %   MULTIMAP = multiLayerMap(NAMES,M,N,CELLDIMS,'grid') creates a P-layer 
 %   multiLayerMap by specifying the size of the grid and data stored in
 %   corresponding mapLayers.
 %
 %   MULTIMAP = multiLayerMap(SOURCEMAP) creates a new multiLayerMap object 
 %   using layers copied from another multiLayerMap object.
 %
 %   MULTIMAP = multiLayerMap(___,Name,Value,...) specifies additional 
 %   properties based on the input property names and the specified values.
 %   For example, multiLayerMap(__,'LocalOriginInWorld',[15 20]) sets the
 %   local origin to a specific world location.
 %
 %   multiLayerMap properties, Common:
 %       GridLocationInWorld     - Location of the grid in world coordinates
 %       GridOriginInLocal       - Location of the grid in local coordinates
 %       GridSize                - Size of the grid in [rows, cols] (number of cells)
 %       LocalOriginInWorld      - Location of the local frame in world coordinates
 %       NumLayers               - Number of map layers stored internally
 %       Resolution              - Grid resolution in cells per meter
 %       XLocalLimits            - Min and max values of X in local frame
 %       YLocalLimits            - Min and max values of Y in local frame
 %       XWorldLimits            - Min and max values of X in world frame
 %       YWorldLimits            - Min and max values of Y in world frame
 %
 %   multiLayerMap properties, Layer-Specific:
 %       DataType                - Data type of the values stored in each map layer
 %       DefaultValue            - Default values for uninitialized cells in each map layer
 %       DataSize                - Size of data matrix in each map layer
 %       LayerNames              - Name of each layer
 %
 %   multiLayerMap methods:
 %       copy            - Create a copy of the object
 %       getMapData      - Retrieve data from map layers
 %       getLayer        - Returns handle to layer with matching name
 %       setMapData      - Assign data to map layers
 %       grid2world      - Convert grid indices to world coordinates
 %       grid2local      - Convert grid indices to local coordinates
 %       local2grid      - Convert local coordinates to grid indices
 %       local2world     - Convert local coordinates to world coordinates
 %       move            - Move all map layers in world frame
 %       syncWith        - Sync map with overlapping map
 %       world2grid      - Convert world coordinates to grid indices
 %       world2local     - Convert world coordinates to local coordinates
 %
 %   Examples:
 %
 %     % Create local multiLayerMap with three layers.
 %     localMultiMap = multiLayerMap({mapLayer('LayerName','Layer1'); ...
 %                           mapLayer(zeros(10,10,2,3),'LayerName','Layer2'); ...
 %                           mapLayer(ones(10,10),'LayerName','Layer3')});
 % 
 %     % Create a source multiLayerMap that covers a larger area.
 %     worldLayer1 = mapLayer(rand(100,100),'Resolution',2,'LayerName','Layer1');
 %     worldLayer2 = mapLayer(repmat(reshape(1:10000,100,100),1,1,2,3).* ...
 %                               reshape([1 2 3 4 5 6],1,1,2,3), ...
 %                               'Resolution',2,'LayerName','Layer2');
 %     worldMultiMap = multiLayerMap({worldLayer1; worldLayer2});            
 % 
 %     % Sync first multiLayerMap with layers that are found in the second. 
 %     % This overwrites data in localMultiMap where the two maps overlap, 
 %     % and re-initializes regions that do not overlap.
 %     syncWith(localMultiMap, worldMultiMap);
 % 
 %     % Verify that the local map has been updated.
 %     values = getMapData(localMultiMap);
 %     values{1}
 %     values{2}
 %     values{3}
 %     
 %     % Move the first map so it only partially overlaps with the sourceMap 
 %     % while synchronizing with the sourceMap.
 %     move(localMultiMap,-[5 5],'SyncWith',worldMultiMap);
 % 
 %     % Update the local map with new data.
 %     setMapData(localMultiMap,'Layer1',eye(10));
 %     setMapData(localMultiMap,'Layer2',[5 5],rand(5,5,2,3),'local');
 %   
 %     % Update the global map using the local map.
 %     syncWith(worldMultiMap,localMultiMap);
 %
 %   See also mapLayer
 
 %   Copyright 2020-2022 The MathWorks, Inc.
 
     %#codegen
     
     properties (Dependent)
         %DataSize Sizes of each layer
         DataSize
     end
     
     properties (Hidden, Dependent)
         DefaultValueInternal
     end
     
     methods
         function obj = multiLayerMap(varargin)
         %multiLayerMap Construct a map which contains multiple layers of data
             % Construct MultiLayerMapCPL
             obj = obj@MultiLayerMapCPL(varargin{:});
         end
         
         function size = get.DataSize(obj)
             size = cell(1,obj.NumLayers);
             for i = 1:obj.NumLayers
                 size{i} = obj.Layers{i}.DataSize;
             end
         end
         
         function val = get.DefaultValueInternal(obj)
             numLayers = numel(obj.Layers);
             val = cell(1,numLayers);
             for i = 1:numLayers
                 val{i} = obj.Layers{i}.DefaultValueInternal;
             end
         end
         
         function layer = getLayer(obj, layerName)
         %getLayer Returns handle to layer with matching name
         %
         %   LAYER = getLayer(OBJ, LAYERNAME) returns the handle to a map 
         %   based on the input layer name specified as a string scalar or 
         %   character vector.

         narginchk(2,2);
             
             % Verify input
             numLayer = numel(obj.Layers);
             for layerIdx = 1:numLayer
                 if strcmpi(layerName,obj.LayerNames{layerIdx})
                     % Return layer
                     layer = obj.Layers{layerIdx};
                     return;
                 end
             end
             
             coder.internal.error('shared_autonomous:multilayermap:LayerNotFound', layerName);
         end
         
         function [data, isValid] = getMapData(obj, layerName, varargin)
         %getMapData Retrieves data from map layers
         %
         %   DATA = getMapData(OBJ) returns an P-element cell array, DATA, 
         %   where each cell contains an MxNxD matrix. M and N are the 
         %   number of rows and columns shared by all layers of the 
         %   multiLayerMap object. D is specific to each layer based on
         %   their specific data size.
         %
         %   DATA = getMapData(OBJ,LAYERNAME) returns the map data for the 
         %   specified layer name as an MxNxD matrix.
         %
         %   DATA = getMapData(OBJ,LAYERNAME,LAYERINPUTS) takes additional 
         %   input arguments and passes them to the getMapData object function 
         %   defined in the corresponding layer. These inputs enable you to 
         %   access grid, local, or world coordinates or retrieve blocks 
         %   of data for the specified layer name. See the syntax of
         %   mapLayer/getMapData for description of LAYERINPUTS and ways to
         %   access individual cells or blocks of matrix data in grid, 
         %   local, or world coordinates.
         %
         %   Examples:
         %       % Construct a multiLayerMap
         %       multiMap = multiLayerMap({mapLayer('LayerName','Layer1'); ...
         %                       mapLayer(zeros(10,10,2,3),'LayerName','Layer2'); ...
         %                       mapLayer(ones(10,10),'LayerName','Layer3')});
         %
         %       % Retrieve cell array containing all map data as matrices.
         %       allData = getMapData(multiMap);
         %
         %       % Retrieve entire matrix for specific layer.
         %       layer2Data = getMapData(multiMap,'Layer2');
         %
         %       % Retrieve a smaller block of data as a matrix.
         %       layer3Data = getMapData(multiMap,'Layer3',[0 0],[5 5]);
         %
         %   See also mapLayer.getMapData
             
             if nargin == 1
                 numLayer = numel(obj.Layers);
                 layerIndices = 1:numLayer;
                 numIdx = numel(layerIndices);
                 data = cell(numel(layerIndices),1);
                 for i = 1:numIdx
                     if layerIndices(i) ~= 0
                         if nargout == 2
                             [data{i}, isValid] = obj.Layers{layerIndices(i)}.getMapData(varargin{:});
                         else
                             data{i} = obj.Layers{layerIndices(i)}.getMapData(varargin{:});
                         end
                     end
                 end
             else
                 validateattributes(layerName,{'char','string'},{},'getMapData','layerName',1);
                 numLayer = numel(obj.Layers);
                 for layerIdx = 1:numLayer
                     if strcmp(layerName,obj.LayerNames{layerIdx})
                         if nargout == 2
                             [data, isValid] = obj.Layers{layerIdx}.getMapData(varargin{:});
                         else
                             data = obj.Layers{layerIdx}.getMapData(varargin{:});
                         end
                         return;
                     end
                 end
                 
                 %Return empty if no matching layer was found
                 coder.internal.error('shared_autonomous:multilayermap:LayerNotFound',layerName);
             end
         end
         
         function isValid = setMapData(obj, layerName, varargin)
         %setMapData Modifies data in individual layers
         %
         %   setMapData(OBJ,LAYERNAME,LAYERINPUTS) takes addition input 
         %   arguments and passes them to the setMapData object function 
         %   defined in the corresponding layer. These inputs enable you to 
         %   access grid, local, or world coordinates or retrieve blocks 
         %   of data for the specified layer name. See the syntax of
         %   mapLayer/getMapData for description of LAYERINPUTS and ways to
         %   assign values to individual cells or blocks of matrix data 
         %   in grid, local, or world coordinates.
         %
         %   ISVALID = setMapData(OBJ,LAYERNAME,LAYERINPUTS) returns a
         %   logicals indicating whether input locations are inside map 
         %   boundaries. See the syntax of mapLayer/getMapData for 
         %   details of the LAYERINPUTS input arguments.
         %
         %   Examples:
         %       % Construct a multiLayerMap
         %       multiMap = multiLayerMap({mapLayer('LayerName','Layer1'); ...
         %                       mapLayer(zeros(10,10,2,3),'LayerName','Layer2'); ...
         %                       mapLayer(ones(10,10),'LayerName','Layer3')});
         %
         %       % Set the entire matrix of a specific layer.
         %       setMapData(multiMap, 'Layer1', rand(10));
         %
         %       % Set a submatrix of the second layer.
         %       setMapData(multiMap, 'Layer2', [0 0], rand(5,5,2,3));
         %
         %   See also mapLayer.setMapData
         
             narginchk(3,7);
             
             validateattributes(layerName,{'char','string'},{},'getMapData','layerName',1);
             numLayer = numel(obj.Layers);
             for layerIdx = 1:numLayer
                 if strcmpi(layerName,obj.LayerNames{layerIdx})
                     if nargout == 1
                         isValid = obj.Layers{layerIdx}.setMapData(varargin{:});
                     else
                         obj.Layers{layerIdx}.setMapData(varargin{:});
                     end
                     return;
                 end
             end
             
             coder.internal.error('shared_autonomous:multilayermap:LayerNotFound',layerName);
         end
         
         function syncWith(obj, sourceMap)
         %SYNCWITH Sync map with overlapping map
         %
         %   syncWith(MAP,SOURCEMAP) updates the data in MAP for all 
         %   LAYERS whose names appear in both MAP and SOURCEMAP. For each 
         %   matching layer, locations in MAP that are also found in SOURCEMAP 
         %   are updated. All other cells retain their current values. 
         %   Layers in MAP that are not found in SOURCEMAP are not updated. 
         %   SOURCEMAP can either be an individual map object or another 
         %   multiLayerMap object.
         %
         %   Example:
         %
         %     % Create local multiLayerMap with three layers.
         %     localMultiMap = multiLayerMap({mapLayer('LayerName','Layer1'); ...
         %                           mapLayer(zeros(10,10,2,3),'LayerName','Layer2'); ...
         %                           mapLayer(ones(10,10),'LayerName','Layer3')});
         % 
         %     % Create a source multiLayerMap that covers a larger area.
         %     worldLayer1 = mapLayer(rand(100,100),'Resolution',2,'LayerName','Layer1');
         %     worldLayer2 = mapLayer(repmat(reshape(1:10000,100,100),1,1,2,3).* ...
         %                               reshape([1 2 3 4 5 6],1,1,2,3), ...
         %                               'Resolution',2,'LayerName','Layer2');
         %     worldMultiMap = multiLayerMap({worldLayer1; worldLayer2});            
         % 
         %     % Sync first multiLayerMap with layers that are found in the 
         %     % second. This overwrites data in localMultiMap where the two
         %     % maps overlap, and re-initializes regions that do not overlap.
         %     syncWith(localMultiMap, worldMultiMap);
         % 
         %     % Verify that the local map has been updated.
         %     values = getMapData(localMultiMap);
         %     values{1}
         %     values{2}
         %     values{3}
         % 
         %     % Update the local map with new data.
         %     setMapData(localMultiMap,'Layer1',eye(10));
         %     setMapData(localMultiMap,'Layer2',[5 5],rand(5,5,2,3),'local');
         %   
         %     % Update the global map using the local map.
         %     syncWith(worldMultiMap,localMultiMap);
         %
         %   See also move
 
         % Validate source-map type
             obj.validateInterface(sourceMap,'syncWith','sourceMap');
               
             if obj.isaLayer(sourceMap)
                 matchedIdx = find(strcmpi(sourceMap.LayerName,obj.LayerNames));
                 if ~isempty(matchedIdx)
                     obj.Layers{matchedIdx}.writeFromOtherMap(sourceMap);
                 end
             else
                 numLayer = numel(obj.Layers);
                 numOther = numel(sourceMap.Layers);
                 for i = 1:numLayer
                     thisName = obj.LayerNames{i};
                     for j = 1:numOther
                         if strcmp(thisName, sourceMap.LayerNames{j})
                             obj.Layers{i}.writeFromOtherMap(sourceMap.Layers{j});
                             break;
                         end
                     end
                 end
             end
         end
         
         function move(obj, moveValue, varargin)
         %MOVE Move map in world frame
         %   MOVE(MAP,MOVEVALUE) moves the local origin of MAP to a location, 
         %   MOVEVALUE, given as an [x y] vector and updates the map limits.
         %   The MOVEVALUE is truncated based on the resolution of the map. 
         %   Values at locations within the previous limits and map limits.
         %
         %   MOVE(___,Name,Value) provides additional options specified
         %   by one or more Name,Value pair arguments. Name must appear
         %   inside single quotes (''). You can specify several name-value
         %   pair arguments in any order as Name1,Value1,...,NameN,ValueN:
         %
         %       'MoveType'      - A string that modifies the meaning of
         %                         the MOVEVALUE input:
         %
         %                          'Absolute' (default) - MAP moves its
         %                             local origin to the discretized [x y] world 
         %                             frame position.
         %
         %                          'Relative' - MAP translates by a
         %                             discrete [x y] distance, relative to
         %                             its original location in world frame.
         %
         %       'FillValue'     - A cell-array of scalar values, FILLVALUE, 
         %                         for filling unset locations. New locations 
         %                         that fall outside the original map frame 
         %                         are initialized with FILLVALUE.
         %
         %       'SyncWith'      - A map or multiLayerMap object, SOURCEMAP,
         %                         for syncing unset locations. For any LAYER
         %                         in MAP whose name is also found in SOURCEMAP,
         %                         new locations outside the original map 
         %                         frame that exist in SOURCEMAP are 
         %                         initialized with values in SOURCEMAP. 
         %                         New locations outside of SOURCEMAP, or for
         %                         LAYERS in MAP that are not found in SOURCEMAP
         %                         are set with the DefaultValue property or 
         %                         specified FILLVALUE.
         %
         %   Example:
         %
         %     % Create local multiLayerMap with three layers.
         %     localMultiMap = multiLayerMap({mapLayer('LayerName','Layer1'); ...
         %                           mapLayer(zeros(10,10,2,3),'LayerName','Layer2'); ...
         %                           mapLayer(ones(10,10),'LayerName','Layer3')});
         % 
         %     % Create a source multiLayerMap that covers a larger area.
         %     worldLayer1 = mapLayer(rand(100,100),'Resolution',2,'LayerName','Layer1');
         %     worldLayer2 = mapLayer(repmat(reshape(1:10000,100,100),1,1,2,3).* ...
         %                               reshape([1 2 3 4 5 6],1,1,2,3), ...
         %                               'Resolution',2,'LayerName','Layer2');
         %     worldMultiMap = multiLayerMap({worldLayer1; worldLayer2});            
         % 
         %     % Move the map to world position [1 1] and fill new regions
         %     % with default values.
         %     move(localMultiMap,[1 1]);
         %
         %     % Move the map to world position [2 2] and fill new regions
         %     % with desired values.
         %     desiredValues = {.5, 1.6, 2};
         %     move(localMultiMap,[2 2],'FillValue',desiredValues);
         %     
         %     % Translate the map by [-3 -3] and fill new regions with 
         %     % values from the world map.
         %     move(localMultiMap,[-3 -3],'MoveType','Relative',...
         %             'FillValue',desiredValues,'SyncWith',worldMultiMap);
 
         % Parse inputs
             [moveValue, sourceMap, fillVal] =  moveParser(obj, moveValue, varargin{:});
 
             % Call internal move command
             move@MultiLayerMapCPL(obj, moveValue, 'DownSamplePolicy','Max', 'FillWith', fillVal,'SyncWith',sourceMap);
         end
         
         function cObj = copy(obj)
         %copy Creates a deep copy of the current multiLayerMap object
             if isempty(obj)
                 cObj = multiLayerMap.empty();
             else
                 cObj = multiLayerMap(obj);
             end
         end
     end
     
     methods (Hidden)
         function layerIdx = validateLayerName(obj, layerName, fcnName, argName)
         %validateLayerName Checks whether the layer name is valid
             validateattributes(layerName,{'char','string'},{},fcnName,argName);
             numLayer = numel(obj.Layers);
             for layerIdx = 1:numLayer
                 if strcmpi(layerName,obj.LayerNames{layerIdx})
                     return;
                 end
             end
             
             % Returns 0 if layer was not found.
             layerIdx = 0;
         end
     end
     
     methods (Hidden, Access = protected)
         function groups = getPropertyGroups(obj)
             groups = repmat(matlab.mixin.util.PropertyGroup,2,1);
             groups(1).Title = 'Map Properties';
             groups(2).Title = 'Layer Properties';
             
             groups(1).PropertyList = struct(...
                 'NumLayers',            obj.NumLayers, ...
                 'GridSize',             obj.GridSize, ...
                 'Resolution',           obj.Resolution, ...
                 'GridLocationInWorld',  obj.GridLocationInWorld, ...
                 'GridOriginInLocal',    obj.GridOriginInLocal, ...
                 'LocalOriginInWorld',   obj.LocalOriginInWorld, ...
                 'XLocalLimits',         obj.XLocalLimits, ...
                 'YLocalLimits',         obj.YLocalLimits, ...
                 'XWorldLimits',         obj.XWorldLimits, ...
                 'YWorldLimits',         obj.YWorldLimits ...
                 );
             
             groups(2).PropertyList = struct(...            
                 'LayerNames',           {obj.LayerNames}, ...
                 'DataSize',             {obj.DataSize}, ...
                 'DataType',             {obj.DataType}, ...
                 'DefaultValue',         {obj.DefaultValue} ...
                 );
         end
     end
     
     methods (Hidden, Static)
         function defConstructorFcn = getDefaultMapConstructor()
         %defConstructorFcn Creates the default constructor for internal MultiLayerMapCPL
             defConstructorFcn = @mapLayer;
         end
         
         function defaultValue = getDefaultDefaultValue()
         %getDefaultDefaultValue Returns the Compile-time constant DefaultValue for multiLayerMap layers
             defaultValue = 0;
         end
     end
end