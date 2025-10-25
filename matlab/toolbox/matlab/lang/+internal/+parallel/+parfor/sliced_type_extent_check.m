function sliced_type_extent_check(varname, value, sliceDim, loopRangeArgs, varargin)
% This function is undocumented and reserved for internal use.  It may be
% removed in a future release.

% varname - name of the sliced variable being checked
% value - existing value of that variable
% sliceDim - the dimension in which the variable is being sliced, needed to check whether
%   a sliced table will be extended in the "variables" dimension
% loopRangeArgs - cell array of either 2 or 4 elements to be passed to (colon)_range_check
%   to validate the loop range and return the range extent
% varargin - empty if the sliced variable access is not being offset from the loop variable,
%   or the name and value of any offset expression. For passing to (colon)_range_check

% Copyright 2024 The MathWorks, Inc.

% First, check that the type is OK before we proceed.
try
    internal.parallel.parfor.sliced_type_check(varname, value);
catch E
    throwAsCaller(E);
end

% Tabular variables must not be extended in the "variables" dimension by indexing in PARFOR,
% so if the value is tabular and the slice dimension is 2, we perform additional checks.
if istabular(value) && sliceDim == 2
    try
        % Need to convert the cell array of range arguments into the actual range.
        % sliced_type_extent_check is invoked prior to the main parallel_function invocation, so the
        % loop range has not yet been validated. Therefore, this might throw
        % if the range is invalid.
        if numel(loopRangeArgs) == 2
            loopRange = internal.parallel.parfor.range_check(loopRangeArgs{:}, varargin{:});
        else
            assert(numel(loopRangeArgs) == 4, ...
                   'Invalid arguments for loop range check.');
            loopRange = internal.parallel.parfor.colon_range_check(loopRangeArgs{:}, varargin{:});
        end
    catch E
        throwAsCaller(E);
    end
    if loopRange(2) < loopRange(1)
        % Empty range, nothing to check
        return
    end
    if nargin < 5
        % No offset argument is present.
        offsetValue = 0;
    else
        offsetValue = varargin{2};
    end
    numTabVarsExtant = width(value);
    numTabVarsNeeded = loopRange(2) + offsetValue;
    if numTabVarsNeeded > numTabVarsExtant
        throwAsCaller(MException(message('MATLAB:parfor:InvalidSlicedTabularVariableRange', ...
                                 varname, numTabVarsNeeded)));
    end
end
end
