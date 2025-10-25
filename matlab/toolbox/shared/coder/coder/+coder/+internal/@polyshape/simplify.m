function PG = simplify(pshape, varargin)
%MATLAB Code Generation Library Function

% Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(1, inf);
coder.internal.polyshape.checkArray(pshape);
collinear = coder.internal.polyshape.parseCollinear(varargin{:});
if collinear == 'd' || collinear == 'f'
    keepCollinear = false;
else
    keepCollinear = true;
end

skipSimplify = false;
if pshape.SimplifyState == 1
    if pshape.KeepCollinearPoints
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

% skip simplify if pshape was simplifed with the same collinear flag
if skipSimplify 
    PG = pshape;
    PG.KeepCollinearPoints = keepCollinear;
else
    if pshape.isEmptyShape
        PG = coder.internal.polyshape();
    else
        if collinear == 'd'
            keepc = pshape.KeepCollinearPoints;
        else
            keepc = keepCollinear;
        end
        PG = extractPropsAndCallSimplifyAPI(pshape, keepc);
        PG.SimplifyState = 1;
        PG.KeepCollinearPoints = keepc;
    end
end
