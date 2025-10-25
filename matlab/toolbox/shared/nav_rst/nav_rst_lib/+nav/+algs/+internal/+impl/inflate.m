function inflatedMap = inflate(map, se)
%This function is for internal use only. It may be removed in the future.

%INFLATE Inflate binary occupancy grid
%   IM = inflate(MAP, SE) returns an N-by-M logical array of inflated map
%   from the N-by-M array of logical input map and a P-by-Q array of
%   logical structuring element SE.

%   Copyright 2014-2019 The MathWorks, Inc.

%#codegen

% Currently we only support two datatypes
    assert(isa(map, 'logical') || isa(map, 'int16'));

    inflatedMap = map;

    [numRows, numCols] = size(map);

    % Find the index of the center of the structuring element
    seCenter = [ceil(size(se,1)/2), ceil(size(se,2)/2)];

    % Get indices for structuring element
    [rowIdx, colIdx] = ind2sub(size(se), 1:length(se(:)));

    % Convert to logical(for Binary Occupancy Grid) or int16 (for Occupancy Grid)
    se = cast(se(:), 'like', map);

    for i = 1:numRows
        for j = 1:numCols
            % Skip if the cell is not occupied
            if ~map(i,j)
                continue;
            end

            % Translated indices of the structuring element
            shiftedRowIdx = i-seCenter(1)+ rowIdx;
            shiftedColIdx = j-seCenter(2)+ colIdx;

            % Generate logicals for indices that are within grid limits
            idx  = (shiftedRowIdx(:) > 0) & ...
                   (shiftedColIdx(:) > 0) & ...
                   (shiftedRowIdx(:) <= numRows) & ...
                   (shiftedColIdx(:) <= numCols);

            index = sub2ind([numRows, numCols], ...
                            shiftedRowIdx(idx) , shiftedColIdx(idx));

            switch class(map)
                % Only 'logical' and 'int16' are supported at the moment (see
                % assertion at beginning of function)
              case 'logical'
                % This is a binary occupancy grid

                subse = se(idx);
                inflatedMap(index) = inflatedMap(index) | subse';
              case 'int16'
                % This is a probabilistic occupancy grid

                % Replace 0 by intmin and 1 with the value of cell
                subse = se(idx)*map(i,j);
                subse(subse == 0) = intmin(class(map));
                inflatedMap(index) = max(inflatedMap(index), subse');
            end
        end
    end
end
