function PG = simplify(pshape, varargin)
% SIMPLIFY Fix degeneracies and intersections in a polyshape
%
% PG = SIMPLIFY(pshape) simplifies the input polyshape by resolving all
% boundary intersections and improper nesting, removing duplicate vertices
% and degeneracies.
%
% PG = SIMPLIFY(..., 'KeepCollinearPoints', tf) specifies how to treat 
% consecutive vertices lying along a straight line. tf can be one of the 
% following:
%   true  - Keep all collinear points as vertices of PG.
%   false - Remove collinear points so that PG contains the fewest number
%           of necessary vertices.
% If this name-value pair is not specified, then SIMPLIFY uses the value of
% 'KeepCollinearPoints' that was used when creating the input polyshape.
%
% See also polyshape, issimplified, intersect, addboundary

% Copyright 2016-2018 The MathWorks, Inc.

narginchk(1, inf);
polyshape.checkArray(pshape);
collinear = polyshape.parseCollinear(varargin{:});
if collinear == "default" || collinear == "false"
    keepCollinear = false;
else
    keepCollinear = true;
end

PG = pshape;
np = numel(pshape);
for i=1:np
    skipSimplify = false;
    if pshape(i).SimplifyState == 1
        if pshape(i).KeepCollinearPoints
            if keepCollinear
                %no change to collinear
                skipSimplify = true;
            end
        else
            %pshape was simplified with collinear=false
            %cannot get collinear points back
            skipSimplify = true;
        end
    end
    %skip simplify if pshape was simplifed with the same collinear flag
    %skipSimplify = (pshape(i).SimplifyState == 1 && ...
    %                pshape(i).KeepCollinearPoints == keepCollinear);
    if skipSimplify 
        PG(i) = pshape(i);
        PG(i).KeepCollinearPoints = keepCollinear;
    else
        if pshape(i).isEmptyShape
            PG(i) = polyshape();
        else
            if collinear == "default"
                keepc = pshape(i).KeepCollinearPoints;
            else
                keepc = keepCollinear;
            end
            PG(i).Underlying = simplify(pshape(i).Underlying, keepc);
            PG(i).SimplifyState = 1;
            PG(i).KeepCollinearPoints = keepc;
        end
    end
end
