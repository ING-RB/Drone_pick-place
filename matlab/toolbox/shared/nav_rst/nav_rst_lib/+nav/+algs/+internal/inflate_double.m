function inflatedMap = inflate_double(map, se)
%This function is for internal use only. It may be removed in the future.

%INFLATE_DOUBLE Inflate a grid map represented by a double matrix
%   INFLATEDMAP = inflate_double(MAP, SE) returns an inflated occupancy
%   matrix that is of the same size as the input map occupancy matrix.
%   SE is the structural element used for inflation, which is a square 
%   matrix. 
%
%   This function is only to be used internally by matchScansGrid.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    inflatedMap = map;

    [numRows, numCols] = size(map);

    seCenter = [ceil(size(se,1)/2), ceil(size(se,2)/2)];
    [rowIdx, colIdx] = ind2sub(size(se), 1:length(se(:)));

    for i = 1:numRows
        for j = 1:numCols
            % Skip if the cell state is unknown
            if abs(map(i,j) - 0.5) < 1e-6
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

            % Replace 1's in SE with the value of cell
            subse = se(idx)*map(i,j);
            inflatedMap(index) = max(inflatedMap(index), subse');
        end
    end
end
