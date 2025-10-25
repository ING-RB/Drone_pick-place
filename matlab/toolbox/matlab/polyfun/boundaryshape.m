function [pshape, vmap] = boundaryshape(T)
%BOUNDARYSHAPE Create a polyshape from the boundaries in a 2d triangulation
%
% [pshape, vmap] = BOUNDARYSHAPE(T) constructs a 2d polyshape pshape from 
% the boundaries in a 2d triangulation T. vmap is a Nx1 vector for the 
% vertex mapping between pshape and T. The values in vmap indicate the row
% numbers in T.Points.

% Copyright 2017-2023 The MathWorks, Inc.

%check input, must be triangulation or delaunayTriangulation
if ~isa(T, 'triangulation')
    error(message('MATLAB:polyfun:NotTriangulation'));
else
    suppressWarning = 'MATLAB:triangulation:EmptyTri2DWarnId';
    OnOff = warning('QUERY', suppressWarning);
    restoreWarnState = onCleanup(@()warning(OnOff));
    warning('off', suppressWarning);
    if size(T.Points, 2) > 2 || size(T.ConnectivityList, 2) > 3
        %3d will be supported in the future
        warning(OnOff.state, suppressWarning);
        error(message('MATLAB:polyfun:Not2dTriangulation'));
    end
end

if numel(T.Points) == 0 || numel(T.ConnectivityList) == 0
    %delaunayTriangulation object
    pshape = polyshape();
    vmap = zeros(0, 1);
    warning(OnOff.state, suppressWarning);
    return;
end

warning(OnOff.state, suppressWarning);

%check and fix misdirected normals
fn = T.faceNormal;
if all(fn(:,3) <= 0) && any(fn(:,3) < 0)
    T = triangulation(T.ConnectivityList(:,[1,3,2]),T.Points);
end

FB = freeBoundary(T);
nrows = size(FB, 1);
if nrows == 0
    %e.g. 2 overlapping triangles
    pshape = polyshape();
    vmap = zeros(0, 1);
    return;
end

foundProblem = false;
pts = [];
vmap = [];
icurr = 0;
for i = 1:nrows
    if icurr == 0
        %start of new boundary
        istart = FB(i, 1);
        vmap = [vmap; istart];
        pts = [pts; T.Points(istart, :)];
    end
    icurr = FB(i, 2);
    
    bdry_closed = false;
    if icurr == istart
        %perfect
        bdry_closed = true;
    elseif  i == nrows || icurr ~= FB(i+1, 1)
        %non-manifold
        bdry_closed = true;
        vmap = [vmap; icurr];
        pts = [pts; T.Points(icurr, :)];
        foundProblem = true;
    end
    
    if bdry_closed
        %boundary closed
        if i < nrows
            pts = [pts; NaN NaN];
            vmap = [vmap; NaN];
        end
        icurr = 0;
    else
        vmap = [vmap; icurr];
        pts = [pts; T.Points(icurr, :)];
    end
end

if foundProblem
    warning(message('MATLAB:polyfun:ProblemInBoundary'));
end

pshape = polyshape(pts, 'Simplify', false, 'SolidBoundaryOrientation', 'ccw');
