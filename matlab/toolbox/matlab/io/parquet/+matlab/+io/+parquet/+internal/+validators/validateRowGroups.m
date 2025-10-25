function rowgroups = validateRowGroups(rowgroups, info)
%validateRowGroups   Verifies that rowgroups has the right datatype.
%
%   Optionally provide the INFO input to check that all rowgroup indices
%   are in the right range.

%   Copyright 2022 The MathWorks, Inc.

    requirements = ["vector", "real", "positive", "integer", "nonnan"];
    validateattributes(rowgroups, "numeric", requirements, "parquetread", "RowGroups");

    % Reshape to column vector.
    rowgroups = reshape(double(rowgroups), [], 1);

    if nargin > 1
        % Error out if the user-provided rowgroup indices were too high.
        maxRowGroupIndex = max(rowgroups, [], 'all');

        if maxRowGroupIndex > info.NumRowGroups
            error(message("MATLAB:parquetio:read:RowGroupIndexTooLarge", ...
                maxRowGroupIndex, info.NumRowGroups, info.Filename));
        end
    end
end