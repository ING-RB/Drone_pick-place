function acObj = sortBoundaries(acObj, bndObj, dir, criterion, refPoint)
%MATLAB Code Generation Private Method

% Copyright 2023 The MathWorks, Inc.
%#codegen

ONE = coder.internal.indexInt(1);
acObj.refPt = refPoint;
acObj.issorted = true;
switch (criterion)
    case 'a' % area
        acObj.cri = 'a';
        x = bndObj.getBoundaryAreas();
        x = abs(x); % Sort by abs area, holes have negative area.
    case 'p' % perimeter
        acObj.cri = 'p';
        x = bndObj.getBoundaryPerimeters();
    case 'c' % centroid
        acObj.cri = 'c';
        x = bndObj.getBoundaryCentroidDists(refPoint, acObj.nb);
    otherwise % numsides
        acObj.cri = 'n';
        assert(criterion == 'n'); % added for safety, error should occur at compile time while parsing
        x = bndObj.getBoundarySizes(acObj.nb);
end 
if dir == 'a'
    acObj.dir = 'a';
    fh = @(i,j) sortBdryLess(i,j,x);
    acObj.accessOrder = coder.internal.introsort(acObj.accessOrder,ONE,acObj.nb,fh);
else
    acObj.dir = 'd';
    fh = @(i,j) sortBdryGreater(i,j,x);
    acObj.accessOrder = coder.internal.introsort(acObj.accessOrder,ONE,acObj.nb,fh);
end
%--------------------------------------------------------------------------
function b = sortBdryLess(i, j, x)
coder.inline('always');
a1 = x(i);
a2 = x(j);
if (a1 == a2)
    b = (i<j);
    return;
end
b = (a1<a2);
%--------------------------------------------------------------------------
function b = sortBdryGreater(i, j, x)
coder.inline('always');
a1 = x(i);
a2 = x(j);
if (a1 == a2)
    b = (i<j);
    return;
end
b = (a1>a2);