classdef signedDistanceMap < mapLayer & matlabshared.autonomous.core.internal.CustomDisplay
%signedDistanceMap Store discrete signed distance over 2D region
%
%   Use the signedDistanceMap object to represent distances to surfaces
%   or contours in space. Query points return positive values if they lie
%   outside an occupied region of space and negative if they lie inside a
%   space. This map object also provides gradient information and the
%   location to nearest occupied cell in the scene.
%
%   MAP = signedDistanceMap creates a 2D signed distance map object
%   occupying a world space of width(W) = 10, height(H) = 10 in meters and
%   with Resolution = 1 cell per meter. The DefaultValue for new or
%   uninitialized cells is "false".
%
%   MAP = signedDistanceMap(W,H) creates a 2D signed distance map object
%   representing a world space of width(W) and height(H) in meters.
%   The default grid resolution is 1 cell per meter.
%
%   MAP = signedDistanceMap(W,H,RES) creates a signedDistanceMap
%   object with resolution(RES) specified in cells per meter.
%
%   MAP = signedDistanceMap(W,H,RES,"world") creates a
%   signedDistanceMap object and  specifies the map size (W and H)
%   in the world coordinates. This is also the default value.
%
%   MAP = signedDistanceMap(M,N,RES,"grid") returns a signedDistanceMap
%   object and specifies a grid size of M rows and N columns. RES specifies
%   the cells per meter resolution.
%
%   MAP = signedDistanceMap(P) creates a signedDistanceMap object
%   from the values in the matrix, P. The size of the grid matches
%   the matrix with each cell value interpreted from that matrix location.
%   Matrix, P, may contain any numeric type with zeros(0) and ones(1).
%
%   MAP = signedDistanceMap(P,RES) creates a signedDistanceMap
%   object from matrix, P, with RES specified in cells per meter.
%
%   MAP = signedDistanceMap(SOURCEMAP) creates a signedDistanceMap using
%   values from another signedDistanceMap object.
%
%   MAP = signedDistanceMap(SOURCEMAP,RES) creates a signedDistanceMap
%   using values from another signedDistanceMap object, but resamples the
%   matrix to have the specified resolution = RES.
%
%   MAP = signedDistanceMap(___,Name=Value) specifies options using one or
%   more name-value arguments.
%
%   signedDistanceMap properties:
%       DataType            - Data type of the values stored in the map
%       DefaultValue        - Default value for uninitialized map cells
%       InterpolationMethod - Method used to interpolate distance matrix
%       GridLocationInWorld - Location of the grid in world coordinates
%       GridOriginInLocal   - Location of the grid in local coordinates
%       GridSize            - Size of the grid in [rows, cols] (number of cells)
%       LayerName           - The name of this signedDistanceMap instance
%       LocalOriginInWorld  - Location of the local frame in world coordinates
%       Resolution          - Grid resolution in cells per meter
%       XLocalLimits        - Min and max values of X in local frame
%       YLocalLimits        - Min and max values of Y in local frame
%       XWorldLimits        - Min and max values of X in world frame
%       YWorldLimits        - Min and max values of Y in world frame
%
%   signedDistanceMap methods:
%       copy            - Create a copy of the object
%       closestBoundary - Retrieves nearest boundary to queried location(s)
%       distance        - Return distance to nearest obstacle
%       getMapData      - Get occupancy value of one or more location(s)
%       gradient        - Retrieve gradient at queried location(s)
%       grid2world      - Convert grid indices to world coordinates
%       grid2local      - Convert grid indices to local coordinates
%       local2grid      - Convert local coordinates to grid indices
%       local2world     - Convert local coordinates to world coordinates
%       move            - Move map in world frame
%       setMapData      - Set occupancy value of one or more location(s)
%       show            - Display the map in a figure
%       syncWith        - Sync map with overlapping map
%       world2grid      - Convert world coordinates to grid indices
%       world2local     - Convert world coordinates to local coordinates
%
%   Example:
%
%       % Create a 10x10 empty map
%       map = signedDistanceMap;
%
%       % Update map occupancy
%       setMapData(map,eye(10));
%
%       % Set top left quadrant as occupied
%       setMapData(map,[0 5],true(5));
%
%       % Visualize signed distance field
%       show(map,BoundaryColor=[0 0 0],Colorbar="on");
%
%   See also mapLayer, binaryOccupancyMap.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (SetAccess = ?matlabshared.autonomous.map.internal.InternalAccess)
        %InterpolationMethod Method used to interpolate distance matrix
        %
        %   "none"   : Distance is constant within cells, gradient is (NaN)
        %
        %   "linear" : Distance is bilinearly interpolated, gradient is
        %              piecewise continuous between cell-centers
        %
        %        Default: "linear"
        InterpolationMethod
    end

    properties (Access = ?nav.algs.internal.InternalAccess)
        %IsDirty Flag indicating whether distance must be recalculated
        IsDirty = true;
    end

    properties (Hidden)
        %SDF Interpolation layer for distance/gradient
        SDF
    end

    properties (Hidden,Transient)
        %ImageTag Tag used to identify handles displayed by this object
        ImageTag = 'SDF'

        %ColorbarLinks Stores property links for display of 2nd colorbar
        ColorbarLinks

        %ColormapListener Listener to update image when colormap is modified
        ColormapListener

        %ThemeListener Listener to update image when Theme is modified
        ThemeListener
    end

    methods
        function obj = signedDistanceMap(varargin)
        %signedDistanceMap Store discrete signed distance over 2D region

        % Construct base-class
            obj = obj@mapLayer(varargin{:},'SetTransformFcn',@signedDistanceMap.setDirtyFlag,'LayerName','distanceLayer');

            % Create internal SDF helper
            mat = obj.getMapData();
            props = obj.SharedProperties;
            switch obj.InterpolationMethod
              case "none"
                obj.SDF = nav.algs.internal.zeroOrderSDF(mat,props);
              case "linear"
                obj.SDF = nav.algs.internal.firstOrderSDF(mat,props);
            end
        end

        function [dist, isValid] = distance(obj,varargin)
        %distance Retrieve distance at queried location(s)
        %
        %   MAT = distance(MAP) returns an MxN matrix of signed distance
        %   values, MAT, where positive values lie outside occupied regions
        %   and negative values lie inside.
        %
        %   VALS = distance(MAP,XY) returns an Mx1 array of signed
        %   distances, VALS, for Mx2 array of world coordinates, XY.
        %   Locations found outside the bounds of the map return NaN.
        %
        %   VALS = distance(MAP,LOCATIONS,FRAME) returns Mx1 array of
        %   distances for Mx2 array LOCATIONS in the coordinates of the
        %   specified FRAME. Valid frames are 'world' (default), "local",
        %   and "grid".
        %
        %   [___,ISVALID] = distance(MAP,LOCATIONS,___) optionally returns
        %   an Mx1 array of logicals, ISVALID, indicating whether LOCATIONS
        %   lie inside (true) or outside (false) the map bounds.
        %
        %   MAT = distance(MAP,BOTTOMLEFT,MATSIZE) returns an MxN matrix of
        %   distances in the subregion defined by BOTTOMLEFT and MATSIZE.
        %   Coordinates default to 'world', with BOTTOMLEFT as the
        %   bottom-left [X Y] corner in the world frame and MATSIZE as the
        %   size of the region given as [width height].
        %
        %   MAT = distance(MAP,CORNERLOC,MATSIZE,FRAME) returns an
        %   MxN matrix of distances. When FRAME is 'world' or "local"
        %   CORNERLOC corresponds to the bottom-left [X Y] point in the
        %   Cartesian frame, and MATSIZE corresponds to the XY
        %   [width height]. When FRAME is "grid", CORNERLOC is the
        %   top-left corner, and MATSIZE is [rows cols].
        %
        %       NOTE: When called with CORNERLOC and MATSIZE, distances are
        %             computed between cell centers within the rectangular
        %             query region.
        %
        %   Example:
        %
        %       % Create a 10x10 empty map
        %       map = signedDistanceMap;
        %
        %       % Update map occupancy
        %       setMapData(map,eye(10));
        %
        %       % Set top left quadrant as occupied
        %       setMapData(map,[0 5],true(5));
        %
        %       % Find distance to nearest boundary in each corner of map
        %       queryIJ = [1 1; 1 10; 10 1; 10 10];
        %       distCornerIJ = distance(map,queryIJ,"grid");
        %
        %       % Find distance to nearest boundary in top-left XY quadrant
        %       distQuadrant = distance(map,[0 5],[5 5]);
        %
        %   See also InterpolationMethod, closestBoundary, gradient

            if obj.IsDirty
                obj.SDF.updateSDF(obj.getMapData());
                obj.IsDirty = false;
            end

            if nargout < 2
                dist = obj.SDF.distanceImpl(varargin{:});
            else
                [dist, isValid] = obj.SDF.distanceImpl(varargin{:});
            end
        end

        function [boundLocation, isValid] = closestBoundary(obj,varargin)
        %closestBoundary Retrieves nearest boundary to queried location(s)
        %
        %   MAT = closestBoundary(MAP) returns an MxNx2 matrix of
        %   world coordinates, MAT, where the first and second pages
        %   contain the nearest X,Y boundary point, respectively, for each
        %   map cell center.
        %
        %   VALS = closestBoundary(MAP,XY) returns an Mx1x2 matrix of the
        %   world-XY closest boundary-coordinates, VALS, for Mx2 array,
        %   XY. Locations found outside the bounds of the map return NaN.
        %
        %   VALS = closestBoundary(MAP,LOCATIONS,FRAME) returns Mx1x2 array
        %   of coordinates, VALS, for Mx2 array LOCATIONS in the
        %   coordinates of the specified FRAME. Valid frames are "world"
        %   (default), "local", and "grid".
        %
        %   [___,ISVALID] = closestBoundary(MAP,LOCATIONS,___) optionally
        %   returns an Mx1 array of logicals, ISVALID, indicating whether
        %   LOCATIONS lie inside (true) or outside (false) the map bounds.
        %
        %   MAT = closestBoundary(MAP,BOTTOMLEFT,MATSIZE) returns an M-by-N
        %   matrix of values in a subregion defined by BOTTOMLEFT and
        %   MATSIZE. Coordinates default to "world", with BOTTOMLEFT as the
        %   bottom-left [X Y] corner in the world frame and MATSIZE as the
        %   size of the region given as [width height].
        %
        %   MAT = closestBoundary(MAP,CORNERLOC,MATSIZE,FRAME) returns an
        %   MxNx2 matrix of coordinates to nearest boundary. When FRAME is
        %   "world" or "local" CORNERLOC corresponds to the bottom-left
        %   [X Y] point in the Cartesian frame, and MATSIZE corresponds to
        %   the XY [width height]. When FRAME is "grid", CORNERLOC is the
        %   top-left corner, and MATSIZE is [rows cols].
        %
        %       NOTE: When called with CORNERLOC and MATSIZE, boundary
        %             locations are computed between cell centers within
        %             the rectangular query region.
        %
        %   Example:
        %
        %       % Create a 10x10 empty map
        %       map = signedDistanceMap;
        %
        %       % Update map occupancy
        %       setMapData(map,eye(10));
        %
        %       % Set top left quadrant as occupied
        %       setMapData(map,[0 5],true(5));
        %
        %       % Find nearest boundary for each corner cell of map
        %       queryIJ = [1 1; 1 10; 10 1; 10 10];
        %       nearestCornerIJ = closestBoundary(map,queryIJ,"grid");
        %
        %       % Find nearest XY boundary cell for cells in top-left
        %       % quadrant
        %       nearestQuadrantXY = closestBoundary(map,[0 5],[5 5]);
        %
        %   See also InterpolationMethod, distance, gradient

            if obj.IsDirty
                obj.SDF.updateSDF(obj.getMapData);
                obj.IsDirty = false;
            end

            if nargout > 1
                [boundLocation, isValid] = obj.SDF.closestBoundaryImpl(varargin{:});
            else
                boundLocation = obj.SDF.closestBoundaryImpl(varargin{:});
            end
        end

        function [DXDY, isValid] = gradient(obj,varargin)
        %gradient Retrieve gradient at queried location(s)
        %
        %   Calculates the gradient of the distance surface at given
        %   locations, returning the X-gradient DX and Y-gradient DY as a
        %   2-page matrix, DXDY.
        %
        %   DXDY = gradient(MAP) returns an MxNx2 matrix containing the
        %   X-gradient DX, and the Y-gradient DY in the first and second
        %   pages, respectively.
        %
        %   VALS = gradient(MAP,XY) returns an Mx1x2 matrix of DX,DY
        %   gradients for Mx2 array of world coordinates, XY. Locations
        %   found outside the bounds of the map return NaN.
        %
        %   VALS = gradient(MAP,LOCATIONS,FRAME) returns Mx1x2 matrix of
        %   values for Mx2 array LOCATIONS in the coordinates of the
        %   specified FRAME. Valid frames are "world" (default), "local",
        %   and "grid".
        %
        %   [___,ISVALID] = gradient(MAP,LOCATIONS,___) optionally
        %   returns an Mx1 array of logicals, ISVALID, indicating whether
        %   LOCATIONS lie inside (true) or outside (false) the map bounds.
        %
        %   MAT = gradient(MAP,BOTTOMLEFT,MATSIZE) returns an MxNx2 matrix
        %   of DX,DY gradients in a subregion defined by BOTTOMLEFT and
        %   MATSIZE. Coordinates default to "world", with BOTTOMLEFT as the
        %   bottom-left [X Y] corner in the world frame and MATSIZE as the
        %   size of the region given as [width height].
        %
        %   MAT = gradient(MAP,CORNERLOC,MATSIZE,FRAME) returns an MxNx2
        %   matrix of DX,DY gradients in a subregion defined by BOTTOMLEFT
        %   and MATSIZE. When FRAME is "world" or "local" CORNERLOC
        %   corresponds to the bottom-left [X Y] point in the Cartesian
        %   frame, and MATSIZE corresponds to the XY [width height]. When
        %   FRAME is "grid", CORNERLOC is the top-left corner, and MATSIZE
        %   is [rows cols].
        %
        %       NOTE: When called with CORNERLOC and MATSIZE, gradients are
        %             are computed at cell centers within the rectangular
        %             query region.
        %
        %   Example:
        %
        %       % Create a linearly interpolated map
        %       map = signedDistanceMap(InterpolationMethod="linear");
        %
        %       % Update map occupancy
        %       setMapData(map,eye(10));
        %
        %       % Set top left quadrant as occupied
        %       setMapData(map,[0 5],true(5));
        %
        %       % Calculate gradient in each corner cell of map
        %       queryIJ = [1 1; 1 10; 10 1; 10 10];
        %       gradientAtCornerCell = gradient(map,queryIJ,"grid");
        %
        %       % Calculate gradient for cells in top-left quadrant
        %       gradientInQuadrant = gradient(map,[0 5],[5 5]);
        %
        %       % Display gradient vectors over the map
        %       show(map,BoundaryColor=[0 0 0],VectorField="Gradient");
        %
        %   See also InterpolationMethod, distance, closestBoundary

            if obj.IsDirty
                obj.SDF.updateSDF(obj.getMapData);
                obj.IsDirty = false;
            end

            if nargin > 1
                [DXDY,isValid] = obj.SDF.gradientImpl(varargin{:});
            else
                DXDY = obj.SDF.gradientImpl(varargin{:});
            end
        end

        function [hImg, cBar] = show(map,frame,nvPairs)
        %show Display the signed distance map in a figure
        %
        %   SHOW(MAP) displays the signedDistanceMap object, MAP, in the
        %   current axes with the axes labels representing the world
        %   coordinates.
        %
        %   SHOW(MAP,"local") displays the signedDistanceMap object, MAP,
        %   in the current axes with the axes of the figure representing
        %   the local coordinates of the MAP. The default input is "world",
        %   which shows the axes in world coordinates.
        %
        %   SHOW(MAP,"grid") displays the signedDistanceMap object, MAP,
        %   in the current axes with the axes of the figure representing
        %   the grid indices.
        %
        %   HIMAGE = SHOW(MAP,___) returns the handle to the image
        %   object HIMAGE, created by show.
        %
        %   [HIMAGE,CBAR] = SHOW(MAP,___) returns the handle to the
        %   colorbar CBAR, created by show.
        %
        %   [___] = SHOW(MAP,___,Name=Value) specifies options using one or
        %   more name-value arguments:
        %
        %       BoundaryColor   - A 3-element rgb row vector with values
        %                         between [0 1]. When provided, cells
        %                         representing the occupied boundary
        %                         (i.e. dist==0) are set to this color.
        %
        %       Colorbar        - A scalar logical. When true, a
        %                         colorbar is created which corresponds
        %                         to the Colormap input. This bar is
        %                         added to a hidden axis behind the
        %                         current axis.
        %
        %       Colormap        - An Nx3 matrix of colormap values used
        %                         for the pixel values in the image. If
        %                         not provided, the current colormap of
        %                         the axes is used.
        %
        %       Parent          - Axes to plot the map, specified as an
        %                         axes handle.
        %
        %                           Default: gca
        %
        %       VectorField     - A string scalar or character array:
        %
        %               "off" (default)   : No vector field is shown.
        %               "Gradient"        : The gradient field is shown
        %                                   atop the distance image.
        %               "ClosestBoundary" : Arrows point to the nearest
        %                                   occupied boundary cell.
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
        %
        %       % Create a 10x10 empty map
        %       map = signedDistanceMap;
        %
        %       % Update map occupancy
        %       setMapData(map,eye(10));
        %
        %       % Set top left quadrant as occupied
        %       setMapData(map,[0 5],true(5));
        %
        %       % Visualize signed distance field with a specific colormap,
        %       % display the colorbar and highlight the boundary in red.
        %       show(map,Colormap=winter,BoundaryColor=[0 0 0],...
        %           Colorbar="on");

            arguments
                map (1,1) signedDistanceMap
                frame (1,:) char {validatestring(frame,{'world','grid','local'})} = 'world'
                nvPairs.BoundaryColor (1,3) {mustBeNumeric} = nan(1,3)
                nvPairs.Colorbar (1,:) matlab.lang.OnOffSwitchState = 'off'
                nvPairs.Colormap (:,3) double = []
                nvPairs.Parent (1,1) matlab.graphics.axis.Axes = newplot
                nvPairs.VectorField (1,:) char {mustBeMember(nvPairs.VectorField, {'off','Gradient','ClosestBoundary'})} = 'off'
                nvPairs.FastUpdate (1,1) double {mustBeMember(nvPairs.FastUpdate,[0 1])} = 0;
            end

            isLocal = false;
            isGrid = false;
            switch validatestring(frame,{'world','grid','local'})
              case 'local'
                isLocal = true;
              case 'grid'
                isGrid = true;
            end

            ax = nvPairs.Parent;

            holdState = ishold(ax);
            hold(ax,"on");

            boundProvided = ~all(isnan(nvPairs.BoundaryColor));
            cmapProvided = ~isempty(nvPairs.Colormap);

            % Remove old listeners
            delete(map.ColormapListener);

            % Create new colormap for second axes
            cmapAx = findobj(ax.Parent,'Type','axes','Tag','SDF_ColorbarAxes');
            if ~cmapProvided
                nvPairs.Colormap = colormap(ax);
                delete(cmapAx);
                cmapAx = ax;
            else
                if isempty(cmapAx)
                    % To allow custom colormap/colorbar to update alongside
                    % changes to the primary axes, we enforce a link
                    % between the axes and store the reference.
                    cmapAx = axes(ax.Parent,'Tag','SDF_ColorbarAxes');
                    linkaxes([ax,cmapAx]);
                    map.ColorbarLinks = linkprop([ax, cmapAx], ...
                                                 {'Position','DataAspectRatioMode','DataAspectRatio', ...
                                                  'PlotBoxAspectRatio'});
                else
                    cmapAx = cmapAx(1);
                    delete(cmapAx(2:end));
                end
                cmapAx.Visible = 'off';
                colormap(cmapAx,nvPairs.Colormap);
            end

            % Initially display dist map
            [ax,hIm,~] = nav.algs.internal.MapUtils.showGrid(map, ax, isGrid, isLocal, nvPairs.FastUpdate);
            % Remove old listeners
            delete(map.ThemeListener);

            % Compute cmapped image and colorbar
            hBar = updateImageAndColorBar(map,cmapAx,hIm,nvPairs,boundProvided);
            fUpdate = @(src,prop,event)updateImageAndColorBar(map,cmapAx,hIm,nvPairs,boundProvided,hBar);

            % React to theme change after plotting
            f = ancestor(ax,'figure');
            map.ThemeListener = addlistener(f,'Theme','PostSet',@(src,prop,event)fUpdate(src,prop));
            if ~cmapProvided
                map.ColormapListener = addlistener([ax,f],'Colormap','PostSet',@(src,prop,event)fUpdate(src,prop));
            else
                map.ColormapListener = addlistener(cmapAx,'Colormap','PostSet',@(src,prop,event)fUpdate(src,prop));
            end

            % Move original axes to the top
            axes(ax);

            % Visualize vector field
            hQuiv = findobj(ax,'Type','quiver','Tag','sdf');
            if isequal(nvPairs.VectorField,'off')
                delete(hQuiv);
            else
                switch nvPairs.VectorField
                  case 'Gradient'
                    [x,y,vx,vy] = map.visualizeGradient();
                  case 'ClosestBoundary'
                    [x,y,vx,vy] = map.visualizeClosestBoundary();
                  otherwise
                end
                if isempty(hQuiv)
                    hQuiv = quiver(ax,x,y,vx,vy); %#ok<NASGU>
                else
                    set(hQuiv,'XData',x,'YData',y,'UData',vx,'VData',vy);
                end
            end

            if ~holdState
                hold(ax,'off');
            end
            if nargout > 0
                hImg = hIm;
                cBar = hBar;
            end
        end

        function cObj = copy(obj)
        %copy Creates a deep copy of the signedDistanceMap
            cObj = signedDistanceMap(obj);
        end

        function move(obj, varargin)
            obj.move@mapLayer(varargin{:});
            obj.IsDirty = true;
        end

        function syncWith(obj, sourceMap)
            validateattributes(sourceMap,{'binaryOccupancyMap','signedDistanceMap'},{'scalar'},'syncWith','sourceMap');

            % Write data from overlapping region of sourceMap into map
            obj.syncWith@mapLayer(sourceMap);
            obj.IsDirty = true;
        end
    end

    methods (Hidden)
        function [x,y,vx,vy] = visualizeGradient(obj)
        %visualizeGradient Display gradient field overtop map

        % Retrieve gradient
            grad = obj.gradient();
            vx = grad(:,:,1);
            vy = grad(:,:,2);
            [x,y] = obj.createInterpVectors('l');

            % Y-axis flipped for visualization
            y = flip(y);
        end

        function [x,y,vx,vy] = visualizeClosestBoundary(obj)
            [x,y] = obj.createInterpVectors('l');

            % Y-axis flipped for visualization
            y = flip(y);

            cb = obj.closestBoundary();
            vx = cb(:,:,1) - x(:)';
            vy = cb(:,:,2) - y(:);
        end

        function cBar = updateImageAndColorBar(map,cmapAx,hImg,nvPairs,boundProvided,cBar)
        % Get all distance values and display as an image
            D = map.distance();
            cmap = cmapAx.Colormap;

            % Calculate colormap indices for all points
            nBin = size(cmap,1);
            cmin = min(D,[],'all');
            cmax = max(D,[],'all');
            cIdx = discretize(rescale(D,0,1),nBin);

            if boundProvided && (cmin <= 0 || cmax >= 0)
                % Inject boundary into colormap
                zeroIdx = floor(nBin*-cmin/(cmax-cmin))+1;

                i0 = max(1,zeroIdx);
                i1 = min(zeroIdx+1,nBin);
                cmap(i0:i1,1) = nvPairs.BoundaryColor(1);
                cmap(i0:i1,2) = nvPairs.BoundaryColor(2);
                cmap(i0:i1,3) = nvPairs.BoundaryColor(3);
            end

            % Define CData
            cdata = ind2rgb(cIdx,cmap);

            % Find all points along the boundary
            m = find(abs(D) == 0);

            if boundProvided
                % Mark the boundary color
                pSize = cumprod(size(cdata));
                cdata(m) = nvPairs.BoundaryColor(1);
                cdata(m+pSize(2)) = nvPairs.BoundaryColor(2);
                cdata(m+pSize(2)*2) = nvPairs.BoundaryColor(3);
            end

            hImg.CData = cdata;

            % Recreate the colorbar
            ticks = linspace(0,1,10);
            tickLabels = linspace(cmin,cmax,10);

            if nargin == 5
                delete(findobj(cmapAx.Parent,'Type','colorbar','Tag',[map.ImageTag '_Colorbar']));
                cBar = colorbar(cmapAx,'Ticks',ticks,'TickLabels',tickLabels,'Tag',[map.ImageTag '_Colorbar'],'Colormap',cmap,'ColormapMode','manual');
                if isequal(nvPairs.Colorbar,'off')
                    cBar.Visible = "off";
                end
            else
                cBar.Colormap = cmap;
            end
        end
    end

    methods (Hidden, Access = protected)
        function group = getPropertyGroups(~)
            group = matlab.mixin.util.PropertyGroup;
            group.PropertyList = {...
                'DataType', ...
                'DefaultValue', ...
                'InterpolationMethod', ...
                'GridLocationInWorld', ...
                'GridOriginInLocal', ...
                'GridSize', ...
                'LayerName', ...
                'LocalOriginInWorld', ...
                'Resolution', ...
                'XLocalLimits', ...
                'YLocalLimits', ...
                'XWorldLimits', ...
                'YWorldLimits'};
        end
    end

    methods (Static, Hidden)
        function values = setDirtyFlag(obj, values, varargin)
        %setDirtyFlag Indicates that the SDF needs to be recalculated
            obj.IsDirty = true;
        end

        function name = getDefaultLayerName()
        %getDefaultLayerName Returns the Compile-time constant default name for signedDistanceMap objects
            name = 'signedDistanceMap';
        end

        function defaultValue = getDefaultDefaultValue()
        %getDefaultDefaultValue Returns the Compile-time constant DefaultValue for signedDistanceMap objects
            defaultValue = false(1);
        end

        function validationFcn = getValDefaultValueFcn(methodName)
        %getValDefaultValueFcn Validator for DefaultValue
            validationFcn = @(name,val)validateattributes(val,{'numeric','logical'},{'nonempty','scalar','binary'},methodName,name);
        end

        function validationFcn = getValInterpolationMethodFcn(methodName)
            validationFcn = @(name,val)validatestring(val,{'none','linear'},methodName);
        end

        function [nvPairs, useGridSizeInit, rows, cols, sz, depth] = parseGridVsMatrix(className, parseFcn, varargin)
        %parseGridVsMatrix Calculates size of matrix based on inputs and NV-pairs
            [nvPairs, useGridSizeInit, rows, cols, sz, depth] = nav.algs.internal.MapUtils.parseGridVsMatrix(className, parseFcn, varargin{:});
        end

        function validators = getValidators(methodName)
        %getValidators Returns validators for associated function calls

            invalidNV = signedDistanceMap.getInvalidNVPairFcn(methodName);
            validators = struct(...
                'Resolution',         {{1, signedDistanceMap.getValResolutionFcn(methodName)}},...
                'DefaultValue',       {{0, @(name,val)validateattributes(val,{'logical'},{'scalar'},methodName,'DefaultValue')}},...
                'GridOriginInLocal',  {{1, signedDistanceMap.getValRefFrameValueFcn(methodName)}},...
                'LocalOriginInWorld', {{1, signedDistanceMap.getValRefFrameValueFcn(methodName)}},...
                'LayerName',          {{1, signedDistanceMap.getValLayerNameFcn(methodName)}},...
                'InterpolationMethod',{{1, signedDistanceMap.getValInterpolationMethodFcn(methodName)}},...
                'GetTransformFcn',    {{0, invalidNV}},...
                'SetTransformFcn',    {{1, @(name,val)assert(isequal(val,@signedDistanceMap.setDirtyFlag))}}, ...
                'UseGPU',             {{0, invalidNV}});
        end

        function childNVPairDefaults = getChildNVPairDefaults()
        %getChildNVPairInfo Return cell-array of additional NV-pairs
        %accepted by child classes of MapLayer object
            childNVPairDefaults = {'InterpolationMethod',"linear"};
        end

        function result = matlabCodegenNontunableProperties(~)
        %matlabCodegenNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'InterpolationMethod'};
        end
    end

    methods (Access = protected)
        function postConstructSet(obj, varargin)
        %postConstructSet Set additional properties after internal construction
        %
        %   This function is called after construction to set the occupancy
        %   values.

            numCtorIn = numel(varargin);
            if numCtorIn >= 1 && (isnumeric(varargin{1}) || islogical(varargin{1}))
                if numCtorIn == 1
                    obj.setMapData(varargin{1});
                elseif numCtorIn > 2 && ~(isnumeric(varargin{2}) || islogical(varargin{2}))
                    obj.setMapData(varargin{1});
                elseif ~isscalar(varargin{1}) || ~coder.internal.isConst(size(varargin{1}))
                    obj.setMapData(varargin{1});
                end
            end
        end
    end

    methods (Hidden)
        function types  = allowedConversionTypes(~)
            types = {'binaryOccupancyMap','signedDistanceMap'};
        end

        function [S,cgType] = toStruct(obj,nv)
			%toStruct Convert signedDistanceMap to struct format
            arguments
                obj (1,1) signedDistanceMap
                nv.DynamicMemoryAllowed (1,1) double {mustBeMember(nv.DynamicMemoryAllowed,[0 1])} = 0
            end

            obj.distance();
            S = struct(...
                'MapProps', ...
                struct(...
                'Resolution',obj.Resolution, ...
                'GridOriginInLocal',obj.GridOriginInLocal, ...
                'LocalOriginInWorld',obj.LocalOriginInWorld), ...
                'MapData', ...
                struct(...
                'Bin',obj.getMapData, ...
                'Dist',obj.SDF.Dist.getMapData, ...
                'Grad',obj.SDF.Grad.getMapData, ...
                'Idx',obj.SDF.Idx.getMapData));

            if obj.InterpolationMethod == "linear"
                S.Linear = 1;
            end

            if nargout == 2
                % Generate the typeof object for codegen support
                cgProp = S.MapProps;                
                if nv.DynamicMemoryAllowed
                    cgData = struct();
                    % Make the matrices varsize
                    names = fieldnames(S.MapData);
                    for name = names(:)'
                        data = S.MapData.(name{:});
                        sz = size(data);
                        dataSize = [inf(1,2) sz(3:end)];
                        cgData.(name{:}) = coder.typeof(data(1,1),dataSize);
                    end
                else
                    cgData = coder.typeof(S.MapData);
                end
                if obj.InterpolationMethod == "linear"
                    cgType = struct('MapProps',cgProp,'MapData',cgData,'Linear',1);
                else
                    cgType = struct('MapProps',cgProp,'MapData',cgData);
                end
            end
        end
    end

    methods (Hidden, Static)
        function obj = fromStruct(S)
            %fromStruct Construct map with original binary data/resolution
            hasInterpolant = coder.internal.isConstTrue(isfield(S,"Linear"));
            if hasInterpolant
                obj = signedDistanceMap(S.MapData.Bin, ...
                    Resolution=S.MapProps.Resolution,InterpolationMethod="linear");
            else
                obj = signedDistanceMap(S.MapData.Bin, ...
                    Resolution=S.MapProps.Resolution,InterpolationMethod="none");
            end

            % Update location
            obj.GridOriginInLocal = S.MapProps.GridOriginInLocal;
            obj.LocalOriginInWorld = S.MapProps.LocalOriginInWorld;

            % Manually update cached data
            obj.SDF.Dist.setMapData(S.MapData.Dist);

            % Initialize interpolant
            if hasInterpolant
                obj.SDF.Interpolant.Values = flipud(double(S.MapData.Dist));
                obj.SDF.Grad.setMapData(S.MapData.Grad);
                obj.SDF.Idx.setMapData(S.MapData.Idx);
            end

            % Unset dirty flag, nothing to be done
            obj.IsDirty = false;
        end
    end
end
