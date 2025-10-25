function pg = resolveNesting(pg)
%MATLAB Code Generation Library Function
% Resolve the boundary types of the polyshape boundaries

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

if (pg.nestingResolved)
    return
end

pg.nestingResolved = true;
nb = pg.numBoundaries;
if (nb == 0)
    return
end

absArea = coder.nullcopy(zeros(1,nb,'double'));
boundary_idx = coder.nullcopy(zeros(1,nb,'int32'));
boundary_type = repmat(uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto),1,nb);

for ib = 1:nb
    absArea(ib) = abs(pg.boundaries.getArea(ib));
    boundary_idx(ib) = ib;
    boundary_type(ib) = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto);
end

[~,I] = coder.internal.sort(absArea);

boundary_idx = boundary_idx(I);


for ib = nb:-1:1

    this_bd = boundary_idx(ib);
    if (ib == nb)
        % largest is solid
        boundary_type(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
        pg.boundaries.bType(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
        continue;
    end

    % find the immediate containment
    [this_bd_st, this_bd_en] = pg.boundaries.getBoundary(this_bd);

    numPts = this_bd_en - this_bd_st + 1;

    for ic = ib + 1:nb

        next_bd = boundary_idx(ic);

        allInside = true;
        kp = 1;
        % Check all points to determine proper nesting.
        while (allInside && kp <= numPts)
            [qX, qY] = pg.boundaries.getCoordAtIdx(this_bd,kp);
            allInside = isInside(pg.boundaries, next_bd, qX, qY);
            kp = kp + 1;
        end

        if (~allInside)
            continue;
        end
        if (pg.boundaries.isHoleIdx(next_bd))
            boundary_type(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
            pg.boundaries.bType(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
        else
            boundary_type(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoHole;
            pg.boundaries.bType(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoHole;
        end

        break;
    end

    % not found, set to solid
    if (boundary_type(this_bd) == coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto)
        boundary_type(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
        pg.boundaries.bType(this_bd) = coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid;
    end
end
