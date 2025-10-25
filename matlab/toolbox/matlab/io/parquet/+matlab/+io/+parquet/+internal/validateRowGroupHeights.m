function heights = validateRowGroupHeights(heights, totalHeight)
%validateRowGroupHeights   validates the RowGroupHeights input argument to
%   parquetwrite.
%
%   Should ALWAYS return a row vector as the height output.

%   Copyright 2021 The MathWorks, Inc.

    % Basic size/type validation.
    attrs = ["vector", "nonnegative", "integer", "real", "finite", "nonnan"];
    validateattributes(heights, "numeric", attrs, "parquetwrite", "RowGroupHeights");

    heights = double(heights);

    % Expand scalar RowGroupHeights.
    if isscalar(heights)
        heights = validateScalarRowGroupHeights(heights, totalHeight);
    end

    % Validate vector RowGroupHeights.
    heights = validateVectorRowGroupHeights(heights, totalHeight);

    % Reshape to row-vector.
    heights = reshape(heights, 1, []);
end

function heights = validateScalarRowGroupHeights(heights, totalHeight)
    % Avoid DIV/0! when totalHeight is non-zero.
    if heights == 0 && totalHeight > 0
        error(message("MATLAB:parquetio:write:DivByZeroRowGroupHeights", totalHeight));
    end

    % Will be used as the height for every rowgroup in the Parquet
    % file.
    if heights > 0
        numRowGroups = ceil(totalHeight / heights);
        heights = repmat(heights, 1, numRowGroups);

        % Last RowGroupHeight might be truncated
        if sum(heights, 'all') > totalHeight 
            heights(end) = mod(totalHeight, heights(1));
        end
    end
end

function heights = validateVectorRowGroupHeights(heights, totalHeight)
    heightsSum = sum(heights, 'all');
    if heightsSum ~= totalHeight
        heightsStr = join(string(heights), ", ");
        error(message("MATLAB:parquetio:write:InvalidRowGroupHeightsSum", ...
                      totalHeight, heightsStr, heightsSum));
    end
end