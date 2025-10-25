function [tf,step] = isregular(tT, unit)
%ISREGULAR TRUE for a regular tall timetable, tall datetime or duration array.
%   TF = ISREGULAR(T)
%   TF = ISREGULAR(T,UNIT)
%   [TF,STEP] = ISREGULAR(...)
%
%   See also TIMETABLE/ISREGULAR, DATETIME/ISREGULAR, DURATION/ISREGULAR, TALL.

%   Copyright 2019-2023 The MathWorks, Inc.

tall.checkIsTall(upper(mfilename), 1, tT);
if nargin>1
    tall.checkNotTall(upper(mfilename), 1, unit);
    % Validate using a local input.
    adaptorT = matlab.bigdata.internal.adaptors.getAdaptor(tT);
    localSample = buildSample(adaptorT, adaptorT.Class);
    isregular(localSample, unit);
else
    unit = "time";
end

%ISREGULAR only supports timetables
tT = tall.validateType(tT, upper(mfilename), ["timetable", "datetime", "duration"], 1);

% Simple reduction returning a logical scalar
[~, tf, step] = aggregatefun(@(x) iIsRegularBlock(x,unit), @(a,b,c) iMergeBlockResults(a,b,c,unit), tT);
tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
% If "unit" is "time" (default syntax or provided), step is a duration
% scalar. Otherwise, step is a calendarDuration scalar.
isDefaultUnit = startsWith("time", unit);
if isDefaultUnit
    step = setKnownType(step, "duration");
else
    step = setKnownType(step, "calendarDuration");
end
end

%-----%
function [firstAndLastTimes, isRegular, sampleInterval] = iIsRegularBlock(tt, unit)
% Check for each block whether that block is regular. Also return the first
% and last pairs of slices so that further calls in the reducefun can check
% order between chunks (we need at least three consecutive datapoints to
% prove regularity).


[isRegular, sampleInterval] = isregular(tt, unit);

if isa(tt, "timetable")
    times = tt.Properties.RowTimes;
else
    times = tt;
end

if numel(times)>2
    firstAndLastTimes = {times(1:2), times(end-1:end)};
else
    % Keep them all
    firstAndLastTimes = {times, times};
end

end

%-----%
function [firstAndLastTimes, isRegular, sampleInterval] ...
    = iMergeBlockResults(firstAndLastTimes, isRegular, sampleInterval, unit)
% Merge the results from incoming blocks

% Try to remove empty blocks
emptyBlock = cellfun(@(x) size(x,1)==0, firstAndLastTimes(:,1));
if all(emptyBlock)
    % No data, so just keep the first
    firstAndLastTimes = firstAndLastTimes(1,:);
    isRegular = isRegular(1);
    sampleInterval = sampleInterval(1);
elseif any(emptyBlock)
    % Some, but not all, are empty. Remove the empty ones
    firstAndLastTimes(emptyBlock,:) = [];
    isRegular(emptyBlock) = [];
    sampleInterval(emptyBlock) = [];
end

% If only a single block left, just return it
if size(firstAndLastTimes,1)<2
    return;
end

% We have two non-empty blocks.
isMultiRow = cellfun(@(x) size(x,1)>=2, firstAndLastTimes(:,1));
if ~any(isMultiRow)
    % All were single rows. We can combine into a single block and test
    % that.
    allTimes = cat(1, firstAndLastTimes{:,1});
    [isRegular, sampleInterval] = isregular(timetable(allTimes), unit);
    firstAndLastTimes = {allTimes, allTimes};
    return
end

% At least some were multi-row. Check that they were regular. If so, also
% check that the times at the edge between blocks are regular.
isRegular = all(isRegular(isMultiRow));
if isa(sampleInterval, "duration")
    sampleInterval = min(sampleInterval(isMultiRow), [], "IncludeNaN");
else
    % sampleInterval can be returned as calendarDuration for non-default
    % units. Use datetimes to find the minimum value.
    localDate = datetime(0,0,0) + sampleInterval(isMultiRow);
    minLocalDate = min(localDate, [], "IncludeNaN");
    % The difference between datetimes is a duration array, use vertcat
    % with an empty calendarDuration to always return calendarDuration.
    emptyCalendarDuration = calendarDuration.empty;
    sampleInterval = [emptyCalendarDuration; minLocalDate - datetime(0,0,0)];
end

% Check block boundaries
if isRegular
    for ii=1:size(firstAndLastTimes,1)-1
        combinedTimes = [firstAndLastTimes{ii,2};firstAndLastTimes{ii+1,1}];
        % Only check if we had enough data
        if numel(combinedTimes)>=2
            [tf, sampleInterval] = isregular(timetable(combinedTimes), unit);
            isRegular = isRegular && tf;
        end
    end
end

% Result for next stage needs the first times from the first block and the
% last from the last. If either one didn't have enough rows, include those
% from the neighbouring block.
newFirstTimes = firstAndLastTimes{1,1};
if size(newFirstTimes,1)<2
    % First block only had one row. Include first rows from next block too.
    newFirstTimes = [newFirstTimes;firstAndLastTimes{2,1}];
    if size(newFirstTimes,1)>2
        newFirstTimes = newFirstTimes(1:2);
    end
end

newLastTimes = firstAndLastTimes{end,2};
if size(newLastTimes,1)<2
    % Last block only had one row. Include last rows from previous block too.
    newLastTimes = [firstAndLastTimes{end-1,2};newLastTimes];
    if size(newLastTimes,1)>2
        newLastTimes = newLastTimes(end-1:end);
    end
end

firstAndLastTimes = {newFirstTimes, newLastTimes};
end
