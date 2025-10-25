function pg = polyUpdateArea(pg)
%MATLAB Code Generation Library Function
% Update the geometric properties of the polygon

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

pg = pg.resolveNesting();

pg.polyArea = 0.;
pg.polyPerimeter = 0.;
pg.polyCentroid.X = 0.;
pg.polyCentroid.Y = 0.;
pg.polyBbox = struct('loX',realmax,'loY',realmax,'hiX',-1*realmax,'hiY',-1*realmax);

for it = 1:pg.numBoundaries

    a = pg.getBoundaryArea(it);
    c = pg.boundaries.getCentroid(it);

    if(isnan(c(1)))
        assert(isnan(c(2)));
    else
        pg.polyArea = pg.polyArea + a;
        pg.polyCentroid.X =  pg.polyCentroid.X + a * c(1);
        pg.polyCentroid.Y =  pg.polyCentroid.Y + a * c(2);
    end

    pg.polyPerimeter = pg.polyPerimeter + pg.boundaries.getPerimeter(it);

    bndBbox = getBbox(pg.boundaries, it);

    pg.polyBbox = coder.internal.polyshapeHelper.mergeBbox(pg.polyBbox, bndBbox);
end

if (abs(pg.polyArea) > 1.0e-300 * 100)
    a1 = 1.0 / pg.polyArea;
    pg.polyCentroid.X = pg.polyCentroid.X * a1;
    pg.polyCentroid.Y = pg.polyCentroid.Y * a1;
else
    pg.polyArea = 0.;
    pg.polyCentroid.X = nan;
    pg.polyCentroid.Y = nan;
end

pg.polyClean = true;
