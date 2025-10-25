function out = reduceSummary( in )
% Combine multiple local summary information into a single summary.
%
% "in" should be a 2-D cell array where each row represents info from a
% single chunk. "out" will be a cell row with one entry per variable in the
% table.

%   Copyright 2016-2024 The MathWorks, Inc.


out = in(1,:);
for chunkIdx = 2:size(in, 1)
    for varIdx = 1:size(in, 2)
        baseInfo = out{varIdx};
        incrInfo = in{chunkIdx, varIdx};
        out{varIdx} = iIncrementInfo(baseInfo, incrInfo);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In the reduce phase, we need to increment each info structure. Here we simply
% do this pairwise. The fields must match between the original information and
% the increment.
function info = iIncrementInfo(info, increment)

isEmptyInfo = @(x) (prod(x.Size) == 0);

if isEmptyInfo(info) ~= isEmptyInfo(increment)
    % One or other is empty - but not both - return the non-empty version.
    % g1392643
    if isEmptyInfo(info)
        info = increment;
    end
    return
end

fields = { 'Size', @(x, y) [x(1) + y(1), x(2:end)]; ...
           'NumMissing', @plus; ...
           'MinVal', @(x, y) min([x;y], [], 1); ...
           'MaxVal', @(x, y) max([x;y], [], 1); ...
           'true', @plus; ...
           'false', @plus; ...
           'CategoricalInfo', @iAddCategoricalInfos; ...
           'RowLabelDescr', @iReduceRowLabelDescr; ...
           'SampleRate', @iReduceSampleRate; ...
           'StartTime', @iReduceStartTime; ...
           'TimeStep', @iReduceTimeStep; ...
           'MeanInfo', @iReduceMeanInfo;};
gotFields = isfield(info, fields(:,1));
assert(all(gotFields == isfield(increment, fields(:,1))));

for idx = find(gotFields.')
    [fieldName, fcn] = deal(fields{idx, :});
    info.(fieldName) = fcn(info.(fieldName), increment.(fieldName));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All 'RowLabelDescr' fields should be identical, so the reduction doesn't need
% to do anything - but we can assert that all values are indeed the same.
function out = iReduceRowLabelDescr(out, check)
assert(isequal(out, check));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iAddCategoricalInfos(a, b)

if isequal(a{1}, b{1})
    % Categories were identical for local parts, can simply add together the counts.
    out = { a{1}, a{2} + b{2} };
else
    % Merge category information while maintaining the original ordering.
    outCats = union(a{1}, b{1}, 'stable');
    numCols = size(a{2}, 2); % Always 2-D
    outVals = zeros(numel(outCats), numCols);
    [~, loc] = ismember(a{1}, outCats);
    outVals(loc, :) = a{2};
    [~, loc] = ismember(b{1}, outCats);
    outVals(loc, :) = outVals(loc, :) + b{2};
    out = { outCats, outVals };
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All 'SampleRate' fields should be identical or can be missing for empty
% chunks.
function out = iReduceSampleRate(out, check)
if isequal(out, check)
    return
end
out = [out; check];
missingVal = ismissing(out);
if all(missingVal)
    out = out(1);
else
    out = out(~missingVal);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iReduceStartTime(a, b)
% StartTime is always the first element of RowTimes even if RowTimes is out
% of order. Keep the first value unless it is NaN/NaT and the second one is
% not (this will happen if the first partition is empty).
if ismissing(a)
    out = b;
else
    out = a;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All 'TimeStep' fields should be identical or can be missing for empty
% chunks.
function out = iReduceTimeStep(out, check)
if isequal(out, check)
    return
end
out = [out; check];
missingVal = ismissing(out);
if all(missingVal)
    out = out(1);
else
    out = out(~missingVal);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iReduceMeanInfo(a, b)

% Vercat base info and increment info
vMean = [a{1}; b{1}];
vCount = [a{2}; b{2}];

% Mean
locCount = sum(vCount, 1);
if isdatetime(vMean)
    numTrailingDim = ndims(vMean) - 1;
    trailingDim = repmat({':'}, 1, numTrailingDim);
    fcn = @(x, row) subsref(x, substruct('()', [{row}, trailingDim]));
    ratio = fcn(vCount, 2) ./ (fcn(vCount, 2) + fcn(vCount, 1));
    % METHOD 1: Add scaled (duration) difference
    locMean = fcn(vMean, 1) + ratio.*(fcn(vMean, 2)- fcn(vMean, 1));
else
    vMean(vCount == 0) = 0; % Filter NaN/missing values
    locMean = sum(vCount .* vMean, 1) ./ locCount;
end

out = {locMean, locCount};

end