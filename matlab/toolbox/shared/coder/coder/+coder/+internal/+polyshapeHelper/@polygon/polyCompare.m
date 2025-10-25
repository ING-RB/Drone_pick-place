function ret_array = polyCompare(pgonObj, pgonOther)
%

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

update_p = true;
p1 = pgonObj.getPerimeter();
p2 = pgonOther.getPerimeter();

bnd1 = pgonObj.boundaries;
bnd2 = pgonOther.boundaries;

numFields = 8;
ret_array = coder.nullcopy(zeros(1, numFields));

tiny = 1.0e-150;
if (p1 < tiny || p2 < tiny)
    ret_array(1) = inf;
    for i = 2:numFields
        ret_array(i) = 0;
    end
    return
end

% scale and adjust orientation

% scale both to a reasonable size so that the turning algorithm is more robust
prescale1 = 1000.0 / p1;
ccw_c1 = bnd1.bndScale(prescale1, prescale1, 0, 0, 1); % Only 1 boundary is present in polyshape
prescale2 = 1000.0 / p2;
ccw_c2 = bnd2.bndScale(prescale2, prescale2, 0, 0, 1);

% change both to ccw
a1 = ccw_c1.getArea(1);
a2 = ccw_c2.getArea(1);
if (a1 > 0.0)
    ccw_c1 = ccw_c1.reverseBndAtIdx(1);
end
if (a2 > 0.0)
    ccw_c2 = ccw_c2.reverseBndAtIdx(1);
end
dir_diff = 0.;
if (a1 * a2 < 0.0)
    dir_diff = 1.0;
end

[shape_diff, angle_diff, c1_v, c2_v, size_diff, ...
 ht0_err, slope_err] = coder.internal.polyshapeHelper.boundary2D.bndCompare(ccw_c1, ccw_c2, update_p);


if ((abs(a1) < 1.0e-6 || abs(a2) < 1.0e-6) && shape_diff >= 1.0)
    % degenerate polygon, reverse one boundary and compare again
    ccw_c2.reverseBndAtIdx(1);
    [shape_diff2, angle_diff2, c1_v2, c2_v2, size_diff2, ...
     ht0_err2, slope_err2] = coder.internal.polyshapeHelper.boundary2D.bndCompare(ccw_c1, ccw_c2, update_p);

    if (shape_diff2 < shape_diff)
        shape_diff = shape_diff2;
        angle_diff = angle_diff2;
        size_diff = size_diff2;
        c1_v = c1_v2;
        c2_v = c2_v2;
        ht0_err = ht0_err2;
        slope_err = slope_err2;
        dir_diff = -dir_diff;
    end
end

ret_array(1) = shape_diff;
ret_array(2) = size_diff * prescale2 / prescale1;
ret_array(3) = dir_diff;
ret_array(4) = angle_diff;
ret_array(5) = double(c1_v);
ret_array(6) = double(c2_v);
ret_array(7) = ht0_err;
ret_array(8) = slope_err;
