function [u, c, g, n] = groupAndCountLabels(l)
%GROUPANDCOUNTLABELS Returns grouped indices and counted labels.
%
%   See also matlab.io.datastore.ImageDatastore.splitEachLabel

%   Copyright 2018 The MathWorks, Inc.
    [g, u] = findgroups(l);
    c = splitapply(@numel, l, g);
    n = [];
    switch class(l)
        case 'categorical'
            % count the number of undefined labels
            [c, u, n] = iAddUngroupedCounts(isundefined(l), categorical(nan), c, u, n);
        case 'cell'
            % count the number of empty strings
            % empty string indexes are NaNs in grouping indexes
            [c, u, n] = iAddUngroupedCounts(isnan(g), {''}, c, u, n);
        case 'logical'
            % nothing to do for logical; all logicals are always grouped
        otherwise
            % It has to be numerical at this point, since
            % labels can only be numerical, logical, cellstr or categorical.
            [c, u, n] = iAddUngroupedCounts(isnan(l), nan, c, u, n);
    end
end

function [c, u, n] = iAddUngroupedCounts(ungrouped, ungroupedValue, c, u, n)
% Add ungrouped counts and values to the count c, unique groups u, and
% the ungrouped indexes to n;
    ungroupedCount = nnz(ungrouped);
    if ungroupedCount ~= 0
        if isempty(c)
            c = ungroupedCount;
        elseif ~isempty(ungroupedCount)
            c = [c; ungroupedCount];
        end

        if isempty(u)
            u = ungroupedValue;
        elseif ~isempty(ungroupedValue)
            u = [u; ungroupedValue];
        end

        n = ungrouped;
    end
end
