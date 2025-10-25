classdef mapLayer < MapLayerCPL & ...
                     matlabshared.autonomous.core.internal.CustomDisplay
 %MAPLAYER Create map layer for N-dimensional data
 %   The MAPLAYER object creates an N-D grid map, where the first two dimensions
 %   determine the footprint of the map, and all subsequent dimensions 
 %   dictate the size and layout of the data stored by each cell.
 %   
 %   A map layer stores data for a grid of cells that represent discretized
 %   region of space. Use the getMapData and setMapData object functions to 
 %   query or update data using world, local, or grid coordinates. 
 %   
 %   Layer behavior can also be customized by providing function handles 
 %   during construction using the GetTransformFcn and SetTransformFcn 
 %   properties.
 %   
 %   MAP = mapLayer creates an empty mapLayer object occupying a 10-by-10 
 %   meter space with a resolution of 1 cell per meter.
 %   
 %   MAP = mapLayer(P) creates a map from the values in the matrix or 
 %   matrix array, P. The size of the grid corresponds to the first two 
 %   dimensions of P. For 3-D matrix arrays, each cell in the map is filled 
 %   with the vector of values whose size is determined by the third 
 %   dimension of the array. For N-D matrix arrays, each cell contains a 
 %   matrix (N = 4) or matrix array (N > 4) of data for that specified cell.
 %
 %   MAP = mapLayer(W,H) creates a map covering the specified width and 
 %   height. The default grid resolution is 1 cell per meter.
 %
 %   MAP = mapLayer(M,N,'grid') specifies a map with grid size of M rows and N columns.
 %
 %   MAP = mapLayer(W,H,CELLDIMS) creates a map where the size of the data 
 %   stored in each cell is defined by the integer-valued array, CELLDIMS.
 %
 %   MAP = mapLayer(M,N,CELLDIMS,'grid') creates a map with grid size of M 
 %   rows and N columns. The data stored in each cell is defined 
 %   by the integer-valued array, CELLDIMS.
 %
 %   MAP = mapLayer(SOURCEMAP) creates a new mapLayer object using values 
 %   from another mapLayer object.
 %
 %   MAP = mapLayer(___,Name, Value,...)  specifies additional 
 %   properties based on the input property names and the specified values.
 %   For example, mapLayer(__,'LocalOriginInWorld',[15 20]) sets the 
 %   local origin to a specific world location.
 %   
 %   mapLayer properties:
 %       GetTransformFcn         - Applies transformation to values retrieved by getMapData
 %       SetTransformFcn         - Applies transformation to values provided to setMapData
 %       DataType                - Data type of the values stored in the map
 %       GridSize                - Size of the grid in [rows, cols] (number of cells)
 %       LayerName               - The name of this mapLayer instance
 %       DataSize                - Size of the data matrix [rows, cols, DATADIMS]
 %       Resolution              - Grid resolution in cells per meter
 %       XLocalLimits            - Min and max values of X in local frame
 %       YLocalLimits            - Min and max values of Y in local frame
 %       XWorldLimits            - Min and max values of X in world frame
 %       YWorldLimits            - Min and max values of Y in world frame
 %       GridLocationInWorld     - Location of the grid in world coordinates
 %       LocalOriginInWorld      - Location of the local frame in world coordinates
 %       GridOriginInLocal       - Location of the grid in local coordinates
 %       DefaultValue            - Default value for uninitialized map cells
 %
 %   mapLayer methods:
 %       copy            - Create a copy of the object
 %       getMapData      - Retrieve data from map layer
 %       setMapData      - Assign data to map layer
 %       grid2world      - Convert grid indices to world coordinates
 %       grid2local      - Convert grid indices to local coordinates
 %       local2grid      - Convert local coordinates to grid indices
 %       local2world     - Convert local coordinates to world coordinates
 %       move            - Move map in world frame
 %       syncWith        - Sync map with overlapping map
 %       world2grid      - Convert world coordinates to grid indices
 %       world2local     - Convert world coordinates to local coordinates
 %
 %   Example:
 %
 %       % Create a default 10x10 map with resolution 1.
 %       map = mapLayer;
 %
 %       % Create a 10x20x2x3 map with resolution 10.
 %       map = mapLayer(zeros(10,20,2,3),'Resolution',10);
 %
 %       % Set all values in the lower-left quadrant to ones.
 %       setMapData(map,[0 0],ones(5,10,2,3));
 %       origData = getMapData(map);
 %
 %       % Create a map layer which stores 3-D unit vectors.
 %       setFcn = @(obj,values,varargin)values./vecnorm(values,2,3);
 %       newMap = mapLayer(ones(10,20,3),'Resolution',10,'SetTransformFcn',setFcn);
 %       
 %       % Set the bottom-left quadrant with random vector data.
 %       setMapData(newMap,[0 0],rand(newMap.DataSize./[2 2 1]));
 %
 %       % Confirm that the random data has been converted to unit vectors.
 %       unitData = getMapData(newMap);
 %       assert(all(abs(vecnorm(unitData,2,3) - 1) < sqrt(eps),[1 2]));
 %
 %   See also multiLayerMap
 
 %   Copyright 2020-2021 The MathWorks, Inc.
 
     %#codegen
     
     methods
         function move(obj, moveValue, varargin)
         %MOVE Move map in world frame
         %   MOVE(MAP,MOVEVALUE) moves the local origin of MAP to a location, 
         %   MOVEVALUE, given as an [x y] vector, and updates the map limits.
         %   The MOVEVALUE is truncated based on the resolution of the map. 
         %   Values at locations within the previous limits and map limits.
         %
         %   MOVE(__,Name,Value) provides additional options specified
         %   by one or more Name,Value pair arguments. Name must appear
         %   inside single quotes (''). You can specify several name-value
         %   pair arguments in any order as Name1,Value1,...,NameN,ValueN:
         %
         %       'MoveType'      - A string that modifies the meaning of
         %                         the MOVEVALUE input:
         %
         %                             'Absolute' (default) - MAP moves its
         %                             local origin to discretized [x y] world 
         %                             frame position.
         %
         %                             'Relative' - MAP translates by a
         %                             discrete [x y] distance, relative to
         %                             its original location in world frame.
         %
         %       'FillValue'     - A scalar value, FILLVALUE, for filling
         %                         unset locations. New locations that fall
         %                         outside the original map frame are
         %                         initialized with FILLVALUE.
         %
         %       'SyncWith'      - A map object, SOURCEMAP, for syncing 
         %                         unset locations. New locations outside 
         %                         the original map frame that exist in 
         %                         SOURCEMAP are initialized with values in
         %                         SOURCEMAP. New locations outside of SOURCEMAP, 
         %                         are set with the DefaultValue property or 
         %                         specified FILLVALUE.
         %
         %   Example:
         %       % Create a mapLayer.
         %       map = mapLayer(repmat(eye(20,20),1,1,2),'Resolution',2);
         %
         %       % Try to move the map to [1.25 3.75]. Because the 
         %       % resolution is 2 cells/meter, the map moves to discrete
         %       % world location [1 3.5].
         %       move(map,[1.25 3.75])
         %
         %       % Translate the map by XY-distance [5 5] relative to world 
         %       % frame.
         %       move(map, [5 5], 'MoveType', 'Relative')
         %
         %       % Translate the map by [0 3] and fill new locations with a
         %       % value of 1.
         %       move(map, [0 3], 'MoveType', 'Relative', 'FillValue', 1)
         %
         %       % Move the map back to [0 0] and fill new locations with
         %       % data from another map where the frames overlap.
         %       worldMap = mapLayer(reshape([-1 1],1,1,2)+rand(100,200,2))
         %       move(map, [0 0], 'SyncWith', worldMap)
         %
         %       % Move the map to [-1 -1], and fill new locations with
         %       % data from another map. Fill all other new locations that
         %       % do not overlap with a value of 1.
         %       move(map, [-1 -1], 'SyncWith', worldMap, 'FillValue', 1)
 
         % Parse inputs
             [moveValue, sourceMap, fillVal] =  obj.moveParser(moveValue, varargin{:});
 
             % Call internal move command
             move@MapLayerCPL(obj, moveValue, 'DownSamplePolicy','Max', 'FillWith', fillVal,'SyncWith',sourceMap);
         end
         
         function syncWith(obj, sourceMap)
         %SYNCWITH Sync map with overlapping map
         %
         %   syncWith(MAP,SOURCEMAP) updates MAP with data from another
         %   mapLayer, SOURCEMAP. Locations in MAP that are also
         %   found in SOURCEMAP are updated, all other cells retain their
         %   current values. 
         %
         %   Example:
         %       % Set a localMap's initial position and sync its data with
         %       % a world map.
         %
         %       % Create a 100x100 world map.
         %       worldMap = mapLayer(eye(100));
         %
         %       % Create a 10x10 local map.
         %       localMap = mapLayer(10,10);
         %
         %       % Set the localMap's local-frame to [45 45].
         %       localMap.LocalOriginInWorld = [45 45];
         %
         %       % Sync localMap's data with worldMap.
         %       syncWith(localMap, worldMap)
         %
         %       % Set a localMap's initial position partially outside the
         %       % worldMap limits and sync.
         %       localMap.LocalOriginInWorld = [-5 -5];
         %       syncWith(localMap, worldMap);
         %
         %   See also move
 
         % Validate source-map type
             validateattributes(sourceMap,{'mapLayer'},{'scalar'},'syncWith','sourceMap');
 
             % Write data from overlapping region of sourceMap into map
             obj.writeFromOtherMap(sourceMap);
         end
         
         function cObj = copy(obj)
         %copy Creates a deep copy of the object
             if isempty(obj)
                 cObj = mapLayer.empty();
             else
                 cObj = mapLayer(obj);
             end
         end
     end
     
     methods (Access = ?matlabshared.autonomous.map.internal.InternalAccess)
         function val = getDefaultValueConversion(obj)
         %getDefaultValueConversion Conversion function for get.DefaultValue
         %    Allows occupancyMap to override the MapLayer's DefaultValue
         %    getter
             if ~isempty(obj.GetTransformFcn)
                 val = obj.GetTransformFcn(obj, obj.DefaultValueInternal);
             else
                 val = obj.DefaultValueInternal;
             end
         end
         
         function convertedValue = setDefaultValueConversion(obj, value)
         %setDefaultValueConversion Conversion function for set.DefaultValue
         %    Allows occupancyMap to override the MapLayer's DefaultValue
         %    setter
             validateattributes(value, {'numeric','logical'}, {'nonempty','scalar'},'mapLayer','DefaultValue');
             if ~isempty(obj.SetTransformFcn)
                 val = cast(obj.SetTransformFcn(obj, value),'like',obj.DefaultValueInternal);
             else
                 val = value;
             end
             convertedValue = cast(val,'like',obj.DefaultValueInternal);
         end
     end
     
     methods (Hidden, Access = protected)
         function group = getPropertyGroups(obj)
             group = matlab.mixin.util.PropertyGroup;
             group.Title = 'mapLayer Properties';
             
             group.PropertyList = struct(...
                 'DataSize',             obj.DataSize, ...
                 'DataType',             obj.DataType, ...
                 'DefaultValue',         obj.DefaultValue, ...
                 'GridSize',             obj.GridSize, ...
                 'LayerName',            obj.LayerName, ...
                 'GridLocationInWorld',  obj.GridLocationInWorld, ...
                 'GridOriginInLocal',    obj.GridOriginInLocal, ...
                 'LocalOriginInWorld',   obj.LocalOriginInWorld, ...
                 'Resolution',           obj.Resolution, ...
                 'XLocalLimits',         obj.XLocalLimits, ...
                 'YLocalLimits',         obj.YLocalLimits, ...
                 'XWorldLimits',         obj.XWorldLimits, ...
                 'YWorldLimits',         obj.YWorldLimits, ...
                 'GetTransformFcn',      obj.GetTransformFcn, ...
                 'SetTransformFcn',      obj.SetTransformFcn ...
                 );
         end
     end
     
     methods (Static, Hidden)
         function name = getDefaultLayerName()
         %getDefaultLayerName Returns the Compile-time constant default name for mapLayer objects
             name = 'mapLayer';
         end
         
         function name = getDefaultDefaultValue()
         %getDefaultDefaultValue Returns the Compile-time constant default value for mapLayer objects
             name = 0;
         end
     end
 end