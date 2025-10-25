function boundaries = updateArea(boundaries, this_bd)
%

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

[this_bd_st, this_bd_en] = boundaries.getBoundary(this_bd);
%     note: points in a boundary form a closed loop
size1 = this_bd_en - this_bd_st;

bndBbox = struct('loX',realmax, ...
                 'loY',realmax, ...
                 'hiX',-1*realmax, ...
                 'hiY',-1*realmax);


for i = 1:size1
    [qX, qY] = boundaries.getCoordAtIdx(this_bd, i);
    bndBbox = coder.internal.polyshapeHelper.bboxExpand(bndBbox, qX, qY);
end
boundaries.bbox.loX(this_bd) = bndBbox.loX;
boundaries.bbox.loY(this_bd) = bndBbox.loY;
boundaries.bbox.hiX(this_bd) = bndBbox.hiX;
boundaries.bbox.hiY(this_bd) = bndBbox.hiY;

boundaries.area(this_bd) = 0;
boundaries.perimeter(this_bd) = 0;

% shift the boundary toward the centroid to improve computational accuracy
shift = coder.internal.polyshapeHelper.Point2D(-(bndBbox.loX + bndBbox.hiX) * 0.5,  ...
                                               -(bndBbox.loY + bndBbox.hiY) * 0.5);

shiftVtX = coder.nullcopy(zeros(1,size1+1,'double'));
shiftVtY = coder.nullcopy(zeros(1,size1+1,'double'));
for j = 1:size1+1
    [qX, qY] = boundaries.getCoordAtIdx(this_bd, j);
    shiftVtX(j) = qX + shift.X;
    shiftVtY(j) = qY + shift.Y;
end

areas = coder.nullcopy(zeros(1,size1,'double'));

pi = coder.internal.polyshapeHelper.Point2D(0., 0.);
pj = coder.internal.polyshapeHelper.Point2D(0., 0.);

for i = 1:size1

    pi.X = shiftVtX(i);
    pi.Y = shiftVtY(i);
    pj.X = shiftVtX(i+1);
    pj.Y = shiftVtY(i+1);

    a = pi.X * pj.Y - pi.Y * pj.X;

    if ~isfinite(a)
        return;
    end
    boundaries.area(this_bd) = boundaries.area(this_bd) + a;
    areas(i) = a;

    boundaries.perimeter(this_bd) = boundaries.perimeter(this_bd) + pi.Distance(pj);

end

valid_centroid = true;
if (abs(boundaries.area(this_bd)) <= 1.0e-300 * 100)
    valid_centroid = false;
else
    a = 1.0 / boundaries.area(this_bd);
    ct1 = coder.internal.polyshapeHelper.Point2D(0., 0.);
    ct2 = coder.internal.polyshapeHelper.Point2D(0., 0.);
    for i = 1:size1

        pi.X = shiftVtX(i);
        pi.Y = shiftVtY(i);
        pj.X = shiftVtX(i+1);
        pj.Y = shiftVtY(i+1);

        % compute area ratio, more robust when area is tiny
        af = areas(i) * a;
        if (abs(af) > 1000. && abs(boundaries.area(this_bd)) < 1.0e-8)
            ct1.X = ct1.X + (pi.X + pj.X) * areas(i);
            ct1.Y = ct1.X + (pi.Y + pj.Y) * areas(i);
        else
            ct2.X = ct2.X + (pi.X + pj.X) * af;
            ct2.Y = ct2.Y + (pi.Y + pj.Y) * af;
        end
    end

    ct = coder.internal.polyshapeHelper.Point2D(0., 0.);
    ct.X = ct2.X + ct1.X * a;
    ct.Y = ct2.Y + ct1.Y * a;
    one_third = 1.0 / 3.0;
    boundaries.centroid.X(this_bd) = ct.X * one_third - shift.X;
    boundaries.centroid.Y(this_bd) = ct.Y * one_third - shift.Y;

    max_x = max(abs(boundaries.bbox.loX(this_bd)), abs(boundaries.bbox.hiX(this_bd)));
    max_y = max(abs(boundaries.bbox.loY(this_bd)), abs(boundaries.bbox.hiY(this_bd)));
    if (abs(boundaries.centroid.X(this_bd)) > max_x || ...
        abs(boundaries.centroid.Y(this_bd)) > max_y)
        valid_centroid = false;
    end
end

if (~valid_centroid)
    % caused by tiny area (sliver, bowtie etc)
    boundaries.centroid.X(this_bd) = nan;
    boundaries.centroid.Y(this_bd) = nan;
end

boundaries.area(this_bd) = boundaries.area(this_bd) * (-0.5);
boundaries.clean(this_bd) = true;
