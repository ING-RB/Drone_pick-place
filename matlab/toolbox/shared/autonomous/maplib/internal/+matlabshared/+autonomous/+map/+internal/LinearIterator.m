classdef LinearIterator < matlabshared.autonomous.map.internal.IteratorBase
    %This class is for internal use only. It may be removed in the future.
    
    %LINEARITERATOR is class for linear iterator. The following syntaxes can be
    % used for creating LineIterator object:
    % ITER = matlabshared.autonomous.map.internal.LinearIterator(MAP,STARTPTS, ENDPTS) 
    % or
    % ITER = matlabshared.autonomous.map.internal.LinearIterator(MAP,STARTPTS, ENDPTS, 'world')
    % creates an iterator that iterates through cells in MAP that are
    % crossed by lines with their start points in rows of STARTPTS and
    % their end points in rows of ENDPTS, all defined in world coordinates
    %
    % ITER = matlabshared.autonomous.map.internal.LinearIterator(MAP, STARTPTS, ENDPTS, 'local') 
    % creates the iterator based on lines defined by local coordinates
    %
    % ITER = matlabshared.autonomous.map.internal.LinearIterator(MAP, STARTPTS, ENDPTS, 'grid')
    % creates the iterator based on lines defined by grid coordinates
    %
    % ITER = matlabshared.autonomous.map.internal.LinearIterator(ITER, IDX) 
    % creates an iterator that travels through the IDX-th line traveled by
    % ITER, which must also be a LineIterator
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        %EndPoint end points of specified line segments
        EndPoint
        
        %CurrentLineId id of the current line segment
        CurrentLineID
        %CurrentPointID id of the currentX and currentY in the current line
        CurrentPointID
        % Current grid cell X coordinate
        CurrentX
        % Current grid cell Y coordinate
        CurrentY
        %Count number of grids traversed till now on the current line
        %segment
        Count
        
        %NumLuines numger of specified line segments
        NumLines
        
        DeltaX
        DeltaY
        %NumPoints Vector specifying total number of X and Y
        %intersections with the grid lines for each line segment
        NumPoints
        %IncrementX number of grid cells to increment along X direction
        %in each nextoperation
        IncrementX
        %IncrementY number of grid cells to increment along Y direction
        %in each nextoperation
        IncrementY
        %TranslateX distance to translate CurrentX in each next operation
        TranslateX
        %TranslateY distance to translate CurrentY in each next operation
        TranslateY
        
        %ComputedPointsCurrentIntersect stores grid indices computed at the current
        %intersection point
        ComputedPointsCurrentIntersect
        %ComputedPoints points lying on the line segments computed till
        ComputedPoints
    end
    
    methods
        function obj = LinearIterator(varargin)
            %LineIterator Construct an instance of this class
            
            narginchk(2,4);
            if isa(varargin{1},'matlabshared.autonomous.map.internal.LinearIterator')
                validateattributes(varargin{2},{'numeric'},{'nonempty','nonnan','real','finite','scalar','>',0,'<=',varargin{1}.NumLines},'LinearIterator','IDX');
                lineIdx = varargin{2};
                obj.Map = varargin{1}.Map;
                obj.BasePoint = varargin{1}.BasePoint(lineIdx,:);
                obj.EndPoint = varargin{1}.EndPoint(lineIdx,:);
                obj.IsDone = varargin{1}.IsDone;
                obj.NumLines = 1;
                
                obj.CurrentLineID = 1;
                obj.CurrentPointID = 0;
                obj.CurrentX = floor(varargin{1}.BasePoint(lineIdx,1)) + 1;
                obj.CurrentY = floor(varargin{1}.BasePoint(lineIdx,2)) + 1;
                
                % Get the number of increments and intersection points for ray
                obj.DeltaX = varargin{1}.DeltaX(lineIdx);
                obj.DeltaY =  varargin{1}.DeltaY(lineIdx);
                obj.NumPoints =  varargin{1}.NumPoints(lineIdx);
                obj.IncrementX =  varargin{1}.IncrementX(lineIdx);
                obj.IncrementY =  varargin{1}.IncrementY(lineIdx);
                obj.TranslateX =  varargin{1}.TranslateX(lineIdx);
                obj.TranslateY =  varargin{1}.TranslateY(lineIdx);
                obj.Count = 1;
                obj.ComputedPoints = zeros(max(1,varargin{1}.NumPoints(lineIdx)*8),2);
                obj.IsMapLayer = varargin{1}.IsMapLayer;
                coder.varsize('pointsComputed', [inf, 2], [1, 0]);
                pointsComputed = zeros(0,2);
                obj.ComputedPointsCurrentIntersect = pointsComputed;
                obj.CurrentPoint = nan(1,2);
                return;
            else
                validateattributes(varargin{1}, {'matlabshared.autonomous.internal.MapLayer',...
                    'matlabshared.autonomous.internal.MultiLayerMap'}, {},'LinearIterator','Map');
                obj.Map = varargin{1};
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite','nonempty'}, 'LinearIterator', 'StartPts');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'ncols', 2,'nonnan', 'finite','nonempty'}, 'LinearIterator', 'EndPts');
                if nargin > 3
                    pointType = validatestring(varargin{4},{'grid','local','world'},'LinearIterator','pointType');
                else
                    pointType = 'world';
                end
                
                if isa(varargin{1},'matlabshared.autonomous.internal.MapLayer')
                    obj.IsMapLayer = true;
                else
                    obj.IsMapLayer = false;
                end
                
                % Shift and adjust the coordinates using grid location and resolution
                switch pointType
                    case 'grid'
                        if obj.IsMapLayer
                            startPt = obj.Map.grid2localImpl(varargin{2});
                            endPt = obj.Map.grid2localImpl(varargin{3});
                        else
                            if obj.Map.NumLayers > 0
                                startPt = obj.Map.Layers{1}.grid2localImpl(varargin{2});
                                endPt = obj.Map.Layers{1}.grid2localImpl(varargin{3});
                            else
                                startPt = varargin{2};
                                endPt = varargin{3};
                            end
                        end
                    case 'local'
                        startPt = varargin{2};
                        endPt = varargin{3};
                    otherwise
                        if obj.IsMapLayer
                            startPt = obj.Map.world2localImpl(varargin{2});
                            endPt = obj.Map.world2localImpl(varargin{3});
                        else
                            if obj.Map.NumLayers > 0
                                startPt = obj.Map.Layers{1}.world2localImpl(varargin{2});
                                endPt = obj.Map.Layers{1}.world2localImpl(varargin{3});
                            else
                                startPt = varargin{2};
                                endPt = varargin{3};
                            end
                        end
                end
                numLines = max(size(startPt,1),size(endPt,1));
                obj.NumLines = numLines;
                x0 = (startPt(:,1) + obj.Map.GridOriginInLocal(1,1))*obj.Map.Resolution;
                y0 = (startPt(:,2) + obj.Map.GridOriginInLocal(1,2))*obj.Map.Resolution;
                x1 = (endPt(:,1) + obj.Map.GridOriginInLocal(1,1))*obj.Map.Resolution;
                y1 = (endPt(:,2) + obj.Map.GridOriginInLocal(1,2))*obj.Map.Resolution;
                if length(x0)==1
                    obj.BasePoint = repmat([x0,y0],numLines,1);
                else
                    obj.BasePoint = [x0,y0];
                end
                
                if length(x1)==1
                    obj.EndPoint = repmat([x1,y1],numLines,1);
                else
                    obj.EndPoint = [x1,y1];
                end
                
                obj.CurrentLineID = 1;
                obj.CurrentPointID = 0;
                obj.CurrentX = floor(obj.BasePoint(1,1)) + 1;
                obj.CurrentY = floor(obj.BasePoint(1,2)) + 1;
                
                
                % Get the number of increments and intersection points for ray
                obj.DeltaX = zeros(obj.NumLines,1);
                obj.DeltaY = zeros(obj.NumLines,1);
                obj.NumPoints = zeros(obj.NumLines,1);
                obj.IncrementX = zeros(obj.NumLines,1);
                obj.IncrementY = zeros(obj.NumLines,1);
                obj.TranslateX = zeros(obj.NumLines,1);
                obj.TranslateY = zeros(obj.NumLines,1);
                for k = 1:obj.NumLines
                    m = 0;
                    [obj.DeltaX(k), obj.IncrementX(k), obj.TranslateX(k), l] = getIncrement(obj,...
                        obj.BasePoint(k,1), obj.EndPoint(k,1), m);
                    [obj.DeltaY(k), obj.IncrementY(k), obj.TranslateY(k), obj.NumPoints(k)] = getIncrement(obj,...
                        obj.BasePoint(k,2), obj.EndPoint(k,2), l);
                end
                obj.Count = 1;
                obj.ComputedPoints = zeros(max(1,sum(obj.NumPoints)*8),2);
                obj.IsDone = false;
                
                % Initialize for codegen
                coder.varsize('pointsComputed', [inf, 2], [1, 0]);
                pointsComputed = zeros(0,2);
                obj.ComputedPointsCurrentIntersect = pointsComputed;
                obj.CurrentPoint = nan(1,2);
            end
        end
        
        function pt = next(obj)
            %next Move iterator to next cell
            
            narginchk(1,1);
            coder.varsize('nextGridInd', [inf, 2], [1, 0]);
            pt = nan(1,2);
            if isempty(obj.ComputedPointsCurrentIntersect)
                if ~obj.IsDone
                    nextGridInd = zeros(0,2);
                    
                    while (isempty(nextGridInd)&&(~obj.IsDone))
                        [xp,yp] = computeGridIndicesFromCurrentIntersection(obj);
                        % Remove points outside of grid dimension.
                        idx = xp(:) >= 1 & xp(:) <= obj.Map.GridSize(1,2) & yp(:) >= 1 & yp(:) <= obj.Map.GridSize(1,1);
                        nextGridInd = [obj.Map.GridSize(1,1) + 1 - yp(idx),xp(idx)];
                    end
                    if ~isempty(nextGridInd)
                        pt(1,1:2) = nextGridInd(1,:);
                        obj.ComputedPointsCurrentIntersect = nextGridInd(2:end,:);
                    end
                    obj.CurrentPoint = pt;
                end
            else
                pt(1,1:2) = obj.ComputedPointsCurrentIntersect(1,:);
                obj.CurrentPoint = pt;
                obj.ComputedPointsCurrentIntersect = obj.ComputedPointsCurrentIntersect(2:end,:);
            end
        end
        
        function done = isdone(obj)
            %isdone checks whether the iterator is at the end
            
            narginchk(1,1);
            done = (obj.IsDone&&isempty(obj.ComputedPointsCurrentIntersect));
        end
        
        function newObj = copy(obj)
            %copy creates a deep copy of the object
            
            newObj = matlabshared.autonomous.map.internal.LinearIterator(copy(obj.Map),[1,1],[1,1]);
            newObj.BasePoint = obj.BasePoint;
            newObj.CurrentPoint = obj.CurrentPoint;
            newObj.IsDone = obj.IsDone;
            newObj.EndPoint = obj.EndPoint;
            newObj.CurrentLineID = obj.CurrentLineID;
            newObj.CurrentPointID = obj.CurrentPointID;
            newObj.CurrentX = obj.CurrentX;
            newObj.CurrentY = obj.CurrentY;
            newObj.Count = obj.Count;
            newObj.NumLines = obj.NumLines;
            newObj.DeltaX = obj.DeltaX;
            newObj.DeltaY = obj.DeltaY;
            newObj.NumPoints = obj.NumPoints;
            newObj.IncrementX = obj.IncrementX;
            newObj.IncrementY = obj.IncrementY;
            newObj.TranslateX = obj.TranslateX;
            newObj.TranslateY = obj.TranslateY;
            newObj.ComputedPointsCurrentIntersect = obj.ComputedPointsCurrentIntersect;
            newObj.ComputedPoints = obj.ComputedPoints;
            newObj.IsMapLayer = obj.IsMapLayer;
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        
        function gridPoses = poses(obj)
            %poses returns all grid indices lying on the specified line
            %segments
            
            if ~obj.IsDone
                while ~obj.IsDone
                    computeGridIndicesFromCurrentIntersection(obj);
                end
            end
            gridInd = obj.ComputedPoints(1:(obj.Count-1),:);
            idx = gridInd(:,1) >= 1 & gridInd(:,1) <= obj.Map.GridSize(1,2) & gridInd(:,2) >= 1 & gridInd(:,2) <= obj.Map.GridSize(1,1);
            gridPoses = unique([obj.Map.GridSize(1,1) + 1 - gridInd(idx,2),gridInd(idx,1)],'rows');
        end
        
        function [xp,yp] = computeGridIndicesFromCurrentIntersection(obj)
            %computeGridIndicesFromCurrentIntersection computes grid
            % indices intersecting with the current intersection point
            
            if obj.CurrentPointID ==0
                [xp, yp] = handleEdgeConditions(obj,floor(obj.BasePoint(obj.CurrentLineID,1))+1, ...
                    floor(obj.BasePoint(obj.CurrentLineID,2))+1, obj.BasePoint(obj.CurrentLineID,1),...
                    obj.BasePoint(obj.CurrentLineID,2));
            else
                i=1;
                % Pre-allocate
                % 4*n is required.
                % Using twice (8*n) to ensure we never exceed allocated size.
                xp = nan(8, 1);
                yp = nan(8, 1);
                
                % Iterate over increments and find the grid points
                if abs(obj.TranslateY(obj.CurrentLineID) - obj.TranslateX(obj.CurrentLineID)) < 1e-15
                    % If corner point, then increment both
                    obj.CurrentX = obj.CurrentX + obj.IncrementX(obj.CurrentLineID);
                    obj.TranslateX(obj.CurrentLineID) = obj.TranslateX(obj.CurrentLineID) + obj.DeltaX(obj.CurrentLineID);
                    
                    obj.CurrentY = obj.CurrentY +  obj.IncrementY(obj.CurrentLineID);
                    obj.TranslateY(obj.CurrentLineID) = obj.TranslateY(obj.CurrentLineID) + obj.DeltaY(obj.CurrentLineID);
                    
                    xp(i,1) = obj.CurrentX;
                    yp(i,1) = obj.CurrentY -  obj.IncrementY(obj.CurrentLineID);
                    
                    xp(i+1,1) = obj.CurrentX - obj.IncrementX(obj.CurrentLineID);
                    yp(i+1,1) = obj.CurrentY;
                    
                    xp(i+2,1) = obj.CurrentX;
                    yp(i+2,1) = obj.CurrentY;
                    i = i + 2;
                    obj.CurrentPointID = obj.CurrentPointID + 1;
                elseif (obj.TranslateY(obj.CurrentLineID) < obj.TranslateX(obj.CurrentLineID))
                    obj.CurrentY = obj.CurrentY +  obj.IncrementY(obj.CurrentLineID);
                    obj.TranslateY(obj.CurrentLineID) = obj.TranslateY(obj.CurrentLineID) + obj.DeltaY(obj.CurrentLineID);
                    xp(i,1) = obj.CurrentX;
                    yp(i,1) = obj.CurrentY;
                    if obj.TranslateX(obj.CurrentLineID) > 1e10 && abs(round(obj.BasePoint(obj.CurrentLineID,1)) - ...
                            obj.BasePoint(obj.CurrentLineID,1)) <= eps(obj.BasePoint(obj.CurrentLineID,1))
                        xp(i+1,1) = obj.CurrentX + obj.IncrementX(obj.CurrentLineID);
                        yp(i+1,1) = obj.CurrentY;
                        i = i + 1;
                    end
                elseif (obj.TranslateY(obj.CurrentLineID) > obj.TranslateX(obj.CurrentLineID))
                    obj.CurrentX = obj.CurrentX + obj.IncrementX(obj.CurrentLineID);
                    obj.TranslateX(obj.CurrentLineID) = obj.TranslateX(obj.CurrentLineID) + obj.DeltaX(obj.CurrentLineID);
                    xp(i,1) = obj.CurrentX;
                    yp(i,1) = obj.CurrentY;
                    if obj.TranslateY(obj.CurrentLineID) > 1e10 && abs(round(obj.BasePoint(obj.CurrentLineID,2)) - ...
                            obj.BasePoint(obj.CurrentLineID,2)) <= eps(obj.BasePoint(obj.CurrentLineID,2))
                        xp(i+1,1) = obj.CurrentX;
                        yp(i+1,1) = obj.CurrentY + obj.IncrementY(obj.CurrentLineID);
                        i = i + 1;
                    end
                end
                % Remove NaN from the pre-allocated matrix
                xp = xp(1:i,:);
                yp = yp(1:i,:);
            end
            
            
            obj.CurrentPointID = obj.CurrentPointID + 1;
            if obj.CurrentPointID > obj.NumPoints(obj.CurrentLineID)
                [xp, yp] = handleEdgeConditions(obj,xp, yp, ...
                    obj.EndPoint(obj.CurrentLineID,1), obj.EndPoint(obj.CurrentLineID,2));
                obj.CurrentLineID = obj.CurrentLineID + 1;
                if obj.CurrentLineID <= obj.NumLines
                    obj.CurrentX = floor(obj.BasePoint(obj.CurrentLineID,1)) + 1;
                    obj.CurrentY = floor(obj.BasePoint(obj.CurrentLineID,2)) + 1;
                end
                obj.CurrentPointID = 0;
            end
            obj.ComputedPoints(obj.Count:(obj.Count + size(xp,1)-1),:) = [xp,yp];
            obj.Count = obj.Count + size(xp,1);
            if obj.CurrentLineID > obj.NumLines
                obj.IsDone = true;
            end
            
        end
        
        function [xp, yp] = handleEdgeConditions(~,xp, yp, x, y)
            %handleEdgeConditions Handle start and end point edge conditions
            %   The edge condition is that the start and end points can be on a corner
            %   of the cell or on the edge of the cell. Based on this fact, consider
            %   nearby cells in the collision check.
            if abs(x - floor(x)) <= 2*eps(x)
                % If start/end point is on an edge
                xp = [xp;  floor(x)];
                yp = [yp;  floor(y)+1];
                
                % If start/end point is on a corner
                if abs(y - floor(y)) <= 2*eps(y)
                    xp = [xp;  floor(x)+1];
                    yp = [yp;  floor(y)];
                    
                    xp = [xp;  floor(x)];
                    yp = [yp;  floor(y)];
                    
                    xp = [xp;  floor(x)+1];
                    yp = [yp;  floor(y)+1];
                elseif abs(y - ceil(y)) <= 2*eps(y)
                    xp = [xp;  floor(x)];
                    yp = [yp;  ceil(y)+1];
                    
                    xp = [xp;  floor(x)+1];
                    yp = [yp;  ceil(y)];
                    
                    xp = [xp;  floor(x)];
                    yp = [yp;  ceil(y)];
                    
                    xp = [xp;  floor(x)+1];
                    yp = [yp;  ceil(y)+1];
                end
            elseif abs(x - ceil(x)) <= 2*eps(x)
                % If start/end point is on an edge
                xp = [xp;  ceil(x)];
                yp = [yp;  floor(y)+1];
                
                % If start/end point is on a corner
                if abs(y - floor(y)) <= eps(y)
                    xp = [xp;  ceil(x)+1];
                    yp = [yp;  floor(y)];
                    
                    xp = [xp;  ceil(x)];
                    yp = [yp;  floor(y)];
                    
                    xp = [xp;  ceil(x)+1];
                    yp = [yp;  floor(y)+1];
                elseif abs(y - ceil(y)) <= 2*eps(y)
                    xp = [xp;  ceil(x)];
                    yp = [yp;  ceil(y)+1];
                    
                    xp = [xp;  ceil(x)+1];
                    yp = [yp;  ceil(y)];
                    
                    xp = [xp;  ceil(x)];
                    yp = [yp;  ceil(y)];
                    
                    xp = [xp;  ceil(x)+1];
                    yp = [yp;  ceil(y)+1];
                end
            elseif abs(y - floor(y)) <= 2*eps(y)
                % If start/end point is on an edge
                xp = [xp;  floor(x)+1];
                yp = [yp;  floor(y)];
            elseif abs(y - ceil(y)) <= 2*eps(y)
                % If start/end point is on an edge
                xp = [xp;  floor(x)+1];
                yp = [yp;  ceil(y)+1];
            end
        end
        
        function [dtx, xInc, txNext, n] = getIncrement(~,x0, x1, n)
            %getIncrement Get the X-Y increments and intersection points
            %   Compute various algorithm parameters based on the difference between
            %   the coordinates of the start and end point.
            
            % Sign of dx represents the direction of the line
            dx = (x1 - x0);
            
            % For horizontal or vertical lines, if the point is eps away from the edge,
            % then make sure that xInc is not zero. The sign of xInc is decided based
            % on which side of edge the point lies.
            xIncSign = -1;
            if round(x0) - floor(x0) > 0
                xIncSign = 1;
            end
            
            % Intersection of the line with the circle of unit radius used to compute
            % intersecting points with lines (algorithm parameter)
            dtx = 1.0/abs(dx);
            
            % Compute how to increment the X and Y grid coordinates
            if abs(dx) <= 2*eps(x1)
                xInc = xIncSign;
                txNext = dtx;
            elseif dx > 0
                xInc = 1;
                n = n + floor(x1) - floor(x0);
                txNext = (floor(x0)+ 1 - x0) * dtx;
            else
                xInc = -1;
                n = n + floor(x0) - floor(x1);
                txNext = (x0 - floor(x0)) * dtx;
            end
        end
    end
end

