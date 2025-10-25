function iCell = inCell(info, point, points, pds, holes)
%This function is for internal use only. It may be removed in the future.

%inCell - The cell index of the cell the given point is located in
%   iCell = inCell(point, cells, points, pds, holes) is the index of the
%   cell the given point is located in, determined by looking at the y
%   limits of the cell at the points x value.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    [openCells,openIdx] = info.openCells();
    iCell = 1;
    for i = 1:numel(openCells)
        curCell = openCells(i);
        [ceilLim, floorLim] = nav.decomp.internal.PolyCell.limits(curCell,point(1), points, pds, holes);
        % check the boundaries at the current x position
        if point(2) >= floorLim && point(2) <= ceilLim
            % found it!
            iCell = openIdx(i);
            return;
        end
    end

    % not in any cell? point must be at a bound and we have numerical issues...
    % check again, but assign to the closest diff
    d = Inf;
    for i = 1:numel(openCells)
        curCell = openCells(i);
        [ceilLim, floorLim] = nav.decomp.internal.PolyCell.limits(curCell,point(1), points, pds, holes);
        % check the boundaries at the current x position
        df = abs(point(2)-floorLim);
        dc = abs(point(2)-ceilLim);
        di = min([df dc]);
        if di < d
            d = di;
            iCell = openIdx(i);
        end
    end
end
