function [isCollisionFree, collisionGridPt, endPtsVec, midPtsVec]  = raycastInternal(p1, p2, varargin)
%This function is for internal use only. It may be removed in the future.

%RAYCASTINTERNAL Test a set of lines for collisions or return all cells along a set of rays
%
%   [ISCOLLISIONFREE, COLLISIONPT, ENDPTS, MIDDLEPTS] = RAYCASTINTERNAL(P1, P2,  ROWS, COLS, RES, LOC)
%   returns cells along the laser beams that connect the XY point P1 to each
%   XY pair in P2. The ENDPTS represent indices of cells touching all end points in P2
%   and the MIDDLEPTS represent all cells between P1 and P2, excluding ENDPTS. 
%   This function call does not check for collisions. ISCOLLISIONFREE is
%   always an N-element true vector and COLLISIONPT is N-by-2 zero-vector,
%   where N is the number of XY pairs in P2.
%
%   [ISCOLLISIONFREE, COLLISIONPT, ENDPTS, MIDDLEPTS] = RAYCASTINTERNAL(P1, P2,  ROWS, COLS, RES, LOC, RANGEISMAX)
%   returns cells along the laser beams that connect P1 to each xy point in P2. 
%   If RANGEISMAX(i) is true, the last point in the ray is considered to be
%   a 'miss', and is not included in ENDPTS.
%   This function call does not check for collisions. ISCOLLISIONFREE is
%   always an N-element true vector and COLLISIONPT is N-by-2 zero-vector
%   where N is the number of XY pairs in P2.
%
%   [ISCOLLISIONFREE, COLLISIONPT, ENDPT, MIDDLEPTS] = RAYCASTINTERNAL(P1, P2, MAP, RES, LOC)
%   checks for collisions with occupied cells (true cells) for line
%   segment(s) P1=[X1,Y1] to P2(i)=[X2,Y2]. Elements of ISCOLLISIONFREE are 
%   true if there is no collision with obstacles, and false otherwise. 
%   COLLISIONPT contains the first grid cell location [X,Y], where each ray
%   intersects an occupied map cell. The ENDPTS and MIDDLEPTS are not 
%   computed and are returned as zeros.
%
%   Endpoints are in world coordinate system and
%   can be floating point values. ROWS and COLS are map size in terms of
%   rows and columns, MAP is an N-by-M matrix of logicals, RES
%   is the resolution of the grid cells in cells per meter and LOC is the
%   location of the lower left corner of the grid in the world frame.
%   RANGEISMAX is an N-element Boolean vector.
%   Input P1 (1x2) and P2 (Nx2) are vectors representing points on the grid.
%   X is Column index and Y is row index. 
%   When multiple end-points are provided, results for each ray are vertically
%   combined to form the outputs isCollisionFree, collisionGridPt,
%   endPtsVec, and midPtsVec.
%   This algorithm is known as Digital Differential Analyzer (or DDA).

%   Copyright 2014-2021 The MathWorks, Inc.
%
%   Reference:
%   [1] "ARTS: Accelerated Ray-Tracing System,", Fujimoto, A.; Tanaka, T.;
%       Iwata, K., Computer Graphics and Applications, IEEE , vol.6, no.4,
%       pp.16,26, April 1986

%#codegen

    narginchk(5,7);
    
    % Get number of incoming rays
    numRays = size(p2,1);
    
    % Get the grid size. The algorithm operates in X, Y. Map inputs are Row-
    % Columns.
    if nargin == 5
        [map, gridSize, resolution, gridLocation] = parseMapInputs(numRays,varargin{:});
    else
        [gridSize, resolution, gridLocation, rangeIsMax] = parseSizeInputs(numRays,varargin{:});
    end
    
    % Find xy distance for longest ray
    dMax = max(abs([p2(:,1)-p1(1); p2(:,2)-p1(2)]));
    
    % Find absolute longest ray possible
    if coder.internal.isConstTrue(dMax < max(gridSize/resolution))
        % Allocate vector capable of storing N max length rays. For an 
        % individual ray, the maximum number of visited cells occurs
        % when the ray begins and ends on the corner of a cell and moves
        % diagonally. In this scenario, each time the ray intersects with the 
        % grid the intersection occurs at the boundary of 4 cells, but all 
        % points except the first have 1 cell overlap. 
        maxCells = 4+3*ceil(resolution*dMax);
    else
        % Since this algorithm only returns indices that fall within
        % grid boundaries, a worst-case bound on ray size occurs when a ray
        % fully spans the diagonal of a square map.
        maxCells = 4+3*max(gridSize);
    end

    midPtsVec = zeros(maxCells*numRays,2);
    endPtsVec = zeros(numRays*4,2);
    curEndIdx = 0;
    curMidIdx = 0;
    
    % Allocate output vector for returning collision information for each ray
    collisionGridPt = nan(numRays,2);
    isCollisionFree = true(numRays,1);
    
    % Shift and adjust the coordinates using grid location and resolution.
    % [x0 y0] is the location of the start point in cell-units, relative to
    % the bottom left corner of the grid, gridLocation.
    x0 = (p1(1,1) - gridLocation(1,1))*resolution;
    y0 = (p1(1,2) - gridLocation(1,2))*resolution;
    
    % Calculate start position
    xStart = floor(x0) + 1;
    yStart = floor(y0) + 1;
    assert(xStart >= 1 & xStart <= gridSize(1)+1 & yStart >= 1 & yStart <= gridSize(2)+1)

    for r = 1:numRays
        
        x = xStart;
        y = yStart;

        % [x1 y1] is the location of the rth end point in cell-units, relative to
        % the bottom left corner of the grid, gridLocation.
        x1 = (p2(r,1) - gridLocation(1,1))*resolution;
        y1 = (p2(r,2) - gridLocation(1,2))*resolution;
        
        % Get the number of increments and intersection points for ray
        [endClipped, n, xInc, yInc, dtx, dty, txNext, tyNext] = getTruncatedIncrements(gridSize, x0, x1, y0, y1);

        if n ~= 0
            %% Reset vector with nans
            xp = nan(maxCells,1);
            yp = nan(maxCells,1);

            xp(1) = x;
            yp(1) = y;
            
            % The DDA algorithm works by coverting the slope of the ray to
            % the number of cells traveled along each axis, normalized using
            % the minor axis. For example, if the ray is formulated as y = 2x, 
            % with resolution 1, x is the minor axis, and moves 1 cell per step,
            % whereas y moves 2 cells for every step along the x axis.
            % In each iteration, the algorithm compares the distance to
            % the next gridline (in cells) along each axis, and
            % increments/updates the axis with larger distance until the
            % maximum number of iterations has been reached.
            % NOTE: One extension implemented in this algorithm is the handling
            % of cases where visited points along the ray [x,y] fall within
            % a certain tolerance of a cell boundary. In such cases, 
            % adjacent/overlapping cells are also included in the list of
            % midPoints and/or endPoints. This helps to prevent rays from
            % punching through obstacles if they pass through corners or along
            % cell boundaries.
            i = 1;
            iter = 1;
            while iter <= n
                if abs(tyNext - txNext) < 1e-15
                    % If corner point, then increment both
                    x = x + xInc;
                    txNext = txNext + dtx;

                    y = y +  yInc;
                    tyNext = tyNext + dty;

                    xp(i+1,1) = x;
                    yp(i+1,1) = y - yInc;

                    xp(i+2,1) = x - xInc;
                    yp(i+2,1) = y;

                    xp(i+3,1) = x;
                    yp(i+3,1) = y;
                    i = i + 3;
                    iter = iter + 2;
                    continue;
                end

                % Increment in X or Y direction
                if (tyNext < txNext)
                    % Increment y
                    y = y +  yInc;
                    tyNext = tyNext + dty;
                    xp(i+1,1) = x;
                    yp(i+1,1) = y;
                    i = i + 1;
                    if txNext > 1e10 && abs(round(x0) - x0) <= eps(x0)
                        % Point lies on vertical grid-line, include left and
                        % right cells
                        xp(i+1,1) = x + xInc;
                        yp(i+1,1) = y;
                        i = i + 1;
                    end
                elseif (tyNext > txNext)
                    % Increment x
                    x = x + xInc;
                    txNext = txNext + dtx;
                    xp(i+1,1) = x;
                    yp(i+1,1) = y;
                    i = i + 1;
                    if tyNext > 1e10 && abs(round(y0) - y0) <= eps(y0)
                        % Point lies on horizontal grid-line, include top and 
                        % bottom cells
                        xp(i+1,1) = x;
                        yp(i+1,1) = y + yInc;
                        i = i + 1;
                    end
                end

                iter = iter + 1;
            end
        else
            i = 1;
            xp = x;
            yp = y;
        end
        
        if endClipped
            endPtX = zeros(0,1);
            endPtY = zeros(0,1);
        else
            % Take last point as the endPt, check for case where end-point lies
            % near cell boundary
            [endPtX, endPtY] = handleEdgeConditions(x1, y1);
            if isempty(endPtX)
                endPtX = xp(i);
                endPtY = yp(i);
            end
        end

        if nargin == 5
            % Update collision info
            for p = 1:i
                % Check bounds
                inBounds = xp(p) >= 1 & xp(p) <= gridSize(1) & yp(p) >= 1 & yp(p) <= gridSize(2);
                if inBounds
                    xpNew = xp(p);
                    ypNew = gridSize(2) + 1 - yp(p);
                    idx = ypNew + (xpNew-1)*size(map,1);
                    cellIsOccupied = map(idx);
                    if cellIsOccupied
                        isCollisionFree(r) = false;
                        collisionGridPt(r,1) = ypNew;
                        collisionGridPt(r,2) = xpNew;
                        break;
                    end
                end
            end
            if isCollisionFree(r)
                % Check endpoints
                for p = 1:size(endPtX,1)
                    % Check bounds
                    inBounds = endPtX(p) >= 1 & endPtX(p) <= gridSize(1) & endPtY(p) >= 1 & endPtY(p) <= gridSize(2);
                    if inBounds
                        xpNew = endPtX(p);
                        ypNew = gridSize(2) + 1 - endPtY(p);
                        idx = ypNew + (xpNew-1)*size(map,1);
                        cellIsOccupied = map(idx);
                        if cellIsOccupied
                            isCollisionFree(r) = false;
                            collisionGridPt(r,1) = ypNew;
                            collisionGridPt(r,2) = xpNew;
                            break;
                        end
                    end
                end
            end
            if isCollisionFree(r)
                [startPtX, startPtY] = handleEdgeConditions(x0, y0);
                % Check startPoints
                for p = 1:size(startPtX,1)
                    % Check bounds
                    inBounds = startPtX(p) >= 1 & startPtX(p) <= gridSize(1) & startPtY(p) >= 1 & startPtY(p) <= gridSize(2);
                    if inBounds
                        xpNew = startPtX(p);
                        ypNew = gridSize(2) + 1 - startPtY(p);
                        idx = ypNew + (xpNew-1)*size(map,1);
                        cellIsOccupied = map(idx);
                        if cellIsOccupied
                            isCollisionFree(r) = false;
                            collisionGridPt(r,1) = ypNew;
                            collisionGridPt(r,2) = xpNew;
                            break;
                        end
                    end
                end
            end
        else
            numPotEndPt = size(endPtX,1);
            e0 = max(1,i-numPotEndPt);
            for p = 1:e0-1
                % Check bounds
                inBounds = xp(p) >= 1 & xp(p) <= gridSize(1) & yp(p) >= 1 & yp(p) <= gridSize(2);
                if inBounds
                    curMidIdx = curMidIdx+1;
                    xpNew = xp(p);
                    ypNew = gridSize(2) + 1 - yp(p);
                    midPtsVec(curMidIdx,1) = ypNew;
                    midPtsVec(curMidIdx,2) = xpNew;
                end
            end
            for p = e0:i
                inBounds = xp(p) >= 1 & xp(p) <= gridSize(1) & yp(p) >= 1 & yp(p) <= gridSize(2);
                if inBounds
                    xpNew = xp(p);
                    ypNew = gridSize(2) + 1 - yp(p);
                    isend = any(xp(p) == endPtX & yp(p) == endPtY);
                    if ~rangeIsMax(r) && isend
                        curEndIdx = curEndIdx+1;
                        endPtsVec(curEndIdx,1) = ypNew;
                        endPtsVec(curEndIdx,2) = xpNew;
                    else
                        if ~isend
                            curMidIdx = curMidIdx+1;
                            midPtsVec(curMidIdx,1) = ypNew;
                            midPtsVec(curMidIdx,2) = xpNew;
                        end
                    end
                end
            end
            % Include potential edge-case end points
            for p = 1:numPotEndPt
                if ~any(xp(e0:i) == endPtX(p) & yp(e0:i) == endPtY(p))
                % Unique edgecase found
                    xpNew = endPtX(p);
                    ypNew = gridSize(2) + 1 - endPtY(p);
                    inBounds = endPtX(p) >= 1 & endPtX(p) <= gridSize(1) & endPtY(p) >= 1 & endPtY(p) <= gridSize(2);
                    if ~rangeIsMax(r) && inBounds
                        curEndIdx = curEndIdx+1;
                        endPtsVec(curEndIdx,1) = ypNew;
                        endPtsVec(curEndIdx,2) = xpNew;
                    end
                end
            end
            [startPtX, startPtY] = handleEdgeConditions(x0, y0);
            % Check startPoints
            for p = 1:size(startPtX,1)
                % Check bounds
                inBounds = startPtX(p) >= 1 & startPtX(p) <= gridSize(1) & startPtY(p) >= 1 & startPtY(p) <= gridSize(2);
                if inBounds
                    sIdx = 1:min(i,4);
                    notStart = ~any(startPtX(p) == xp(sIdx) & startPtY(p) == yp(sIdx));
                    notEnd   = ~any(startPtX(p) == endPtX & startPtY(p) == endPtY);
                    if notStart && notEnd
                        xpNew = startPtX(p);
                        ypNew = gridSize(2) + 1 - startPtY(p);
                        curMidIdx = curMidIdx+1;
                        midPtsVec(curMidIdx,1) = ypNew;
                        midPtsVec(curMidIdx,2) = xpNew;
                    end
                end
            end
        end
    end
    midPtsVec = midPtsVec(1:curMidIdx,:);
    endPtsVec = endPtsVec(1:curEndIdx,:);
end

function [endClipped, n, xInc, yInc, dtx, dty, txNext, tyNext] = getTruncatedIncrements(gridSize, x0, x1, y0, y1)
%getTruncatedIncrements Calculates slope and number of iterations for rays
%that are restricted to inside of map bounds.
    m = 0;
    % Calculate unrestricted x-iterations and floored/clipped values
    [dtx, xInc, txNext, nx, x0Floor, x1Floor, x0Trunc, x1Trunc] = getIncrement(gridSize(1), x0, x1, m);
    % Calculate unrestricted y-iterations and floored/clipped values
    [dty, yInc, tyNext, ny, y0Floor, y1Floor, y0Trunc, y1Trunc] = getIncrement(gridSize(2), y0, y1, m);
    
    xClipped = x0Floor ~= x0Trunc || x1Floor ~= x1Trunc;
    yClipped = y0Floor ~= y0Trunc || y1Floor ~= y1Trunc;
    endClipped = x1Floor ~= x1Trunc || y1Floor ~= y1Trunc;
    % If the ray falls outside the bounds of the map, calculate the
    % iterations that lie inside.
    if ~xClipped && ~yClipped
        % Do nothing
    else
        if xClipped && yClipped
        % Both dimensions clipped
            dnx = abs(x0Floor-x0Trunc)+abs(x1Floor-x1Trunc);
            dny = abs(y0Floor-y0Trunc)+abs(y1Floor-y1Trunc);
            rx = abs(dnx/nx);
            ry = abs(dny/ny);
            if  rx >= ry
                [nx,ny] = scaleDim(x0Floor,x0Trunc,x1Floor,x1Trunc,xInc,nx,ny);
            else
                [ny,nx] = scaleDim(y0Floor,y0Trunc,y1Floor,y1Trunc,yInc,ny,nx);
            end
        elseif xClipped && ~yClipped
        % X clipped, update x dimensions and scale y-iterations
            [nx,ny] = scaleDim(x0Floor,x0Trunc,x1Floor,x1Trunc,xInc,nx,ny);
        else
        % Y clipped, update x dimensions and scale y-iterations
            [ny,nx] = scaleDim(y0Floor,y0Trunc,y1Floor,y1Trunc,yInc,ny,nx);
        end
    end
    n = nx+ny;

    function [na, nb] = scaleDim(a0Floor,a0Trunc,a1Floor,a1Trunc,aInc,na,nb)
        % Calculate diff between old num iteration and new num iteration
        dna = abs(a0Floor-a0Trunc)+abs(a1Floor-a1Trunc);

        % Calculate scaling ratio
        r = 1-dna/na;

        % Update non-clipped dimension
        nb = ceil(nb*r);

        % Update clipped dimension
        na = na-dna;
    end
end

function [dtx, xInc, txNext, n, x0f, x1f, x0Trunc, x1Trunc] = getIncrement(xMax, x0, x1, n)
%getIncrement Get the X-Y increments and intersection points
%   Compute various algorithm parameters based on the difference between
%   the coordinates of the start and end point.

    coder.inline('always')
    % Sign of dx represents the direction of the line
    dx = (x1 - x0);

    % For horizontal or vertical lines, if the point is eps away from the edge,
    % then make sure that xInc is not zero. The sign of xInc is decided based
    % on which side of edge the point lies.
    xIncSign = -1;
    x0f = floor(x0);
    x1f = floor(x1);
    if round(x0) - x0f > 0
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
        txNext = (x0f + 1 - x0) * dtx;
        n = n + x1f - x0f;
    else
        xInc = -1;
        txNext = (x0 - x0f) * dtx;
        n = n + x0f - x1f;
    end

    % Calculate truncated values
    x0Trunc = min(max(0,x0f),xMax);
    x1Trunc = min(max(0,x1f),xMax);
end

function [xp, yp] = handleEdgeConditions(x, y)
%handleEdgeConditions Handle start and end point edge conditions
%   The edge condition is that the start and end points can be on a corner
%   of the cell or on the edge of the cell. Based on this fact, consider
%   nearby cells in the collision check. Inputs x and y are real-values 
%   scalars, where [x,y] defines either the start or end point of the ray,
%   converted to cells, relative to the bottom-left corner of the grid. The
%   outputs, xp and yp, are N-by-1 vectors of integers corresponding to the
%   locations of cells touched by [x,y], relative to the bottom-left corner
%   of the grid.
    coder.inline('always')
    if abs(x - floor(x)) <= 2*eps(x)
        % If start/end point is on a corner
        if abs(y - floor(y)) <= 2*eps(y)
            xp = floor(x) + [0; 1; 0; 1];
            yp = floor(y) + [1; 0; 0; 1];
        elseif abs(y - ceil(y)) <= 2*eps(y)
            xp = floor(x) + [0; 1; 0; 1];
            yp = ceil(y) + [1; 0; 0; 1];
        else
            xp = floor(x);
            yp = floor(y)+1;
        end
    elseif abs(x - ceil(x)) <= 2*eps(x)
        % If start/end point is on a corner
        if abs(y - floor(y)) <= eps(y)
            xp = ceil(x)  + [0; 1; 0; 1];
            yp = floor(y) + [1; 0; 0; 1];
        elseif abs(y - ceil(y)) <= 2*eps(y)
            xp = ceil(x) + [0; 1; 0; 1];
            yp = ceil(y) + [1; 0; 0; 1];
        else
            xp = ceil(x);
            yp = floor(y)+1;
        end
    elseif abs(y - floor(y)) <= 2*eps(y)
        % If start/end point is on an edge
        xp = floor(x)+1;
        yp = floor(y);
    elseif abs(y - ceil(y)) <= 2*eps(y)
        % If start/end point is on an edge
        xp = floor(x)+1;
        yp = ceil(y)+1;
    else
        xp = [];
        yp = [];
    end
end

function [map, gridSize, resolution, gridLocation] = parseMapInputs(numRays,varargin)
    map = varargin{1};
    matSize = size(map);
    coder.internal.prefer_const(matSize);
    gridSize = [matSize(2), matSize(1)];
    resolution = varargin{2};
    coder.internal.prefer_const(resolution);
    gridLocation = varargin{3};
end

function [gridSize, resolution, gridLocation, rangeIsMax] = parseSizeInputs(numRays,varargin)
%rows = varargin{1}, columns = varargin{2}
    gridSize = [varargin{2}, varargin{1}];
    coder.internal.prefer_const(gridSize);
    resolution = varargin{3};
    coder.internal.prefer_const(resolution);
    gridLocation = varargin{4};
    
    if nargin == 6
        rangeIsMax = varargin{5};
    else
        rangeIsMax = false(numRays,1);
    end
end
