function [groupingData,groupVars,gvLabels,gbForGV] = discGroupVarTall(groupingData,groupVars,gvLabels,groupBins,inclEdge,isTabular,scalarExpandVars)
% DISCGROUPVARTALL Discretize grouping variable
%   This function will discretize the grouping variables stored in 
%   groupingData according to groupBins and update the gvLabel accordingly.
%   This function also removes repeated pairs of groupVars and groupBins.
%   This is a paired down version of the one used in-memory since we don't
%   do any error checking in tall because that is taken care of in the
%   sample test.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2023 The MathWorks, Inc.

% Do the scalar expansion here
if scalarExpandVars
    groupVars = repmat(groupVars, 1, numel(groupBins));
    groupingData = repmat(groupingData, 1, numel(groupBins));
    gvLabels = repmat(gvLabels, 1, numel(groupBins));
end

if isTabular
    % Remove repeated pairs of groupVars and groupBins
    [~,~,idx] = unique(groupVars,'stable');
    uniquePairIdx = true(size(groupVars));
    % Loop over the unique groups
    for i = 1:max(idx)
        % Find the repeats
        ridx = find(idx == i);
        % Loop over the groupbins of the repeats
        for j = 1:numel(ridx)
            for k = j+1:numel(ridx)
                if isequaln(groupBins{ridx(j)},groupBins{ridx(k)})
                    uniquePairIdx(ridx(k)) = false;
                end
            end
        end
    end

    % Remove repeated pairs of groupVars and groupBins from the data
    groupingData = groupingData(uniquePairIdx);
    groupVars = groupVars(uniquePairIdx);
    gvLabels = gvLabels(uniquePairIdx);
    groupBins = groupBins(uniquePairIdx);
end

if nargout == 4
    gbForGV = false(size(groupingData));
end

for j = 1:numel(groupingData)
    if nargout == 4
        [groupingData{j},gvLabels(j),gbForGV(j)] = discOneGroupVar(groupingData{j},gvLabels(j),groupBins{j},inclEdge);
    else
        [groupingData{j},gvLabels(j)] = discOneGroupVar(groupingData{j},gvLabels(j),groupBins{j},inclEdge);
    end
end

if isTabular
    % Make the labels unique
    gvLabels = matlab.lang.makeUniqueStrings(gvLabels);
end

function [gd,label,flag] = discOneGroupVar(gd,label,gbins,incledge)
% Discretize one grouping variable
flag = true;
if strcmpi(gbins,"none")
    flag = false;
    return;
elseif (isnumeric(gbins) || isduration(gbins) || iscalendarduration(gbins) || isdatetime(gbins))
    gd = discretize(gd,gbins,'categorical','IncludedEdge',incledge);
    label = "disc_" + label;
else
    % No need for any checks as they are performed by the sample
    switch lower(gbins)
        case "secondofminute"
            gd = categorical(floor(second(gd)),0:59);
        case "minuteofhour"
            gd = categorical(minute(gd),0:59);
        case "hourofday"
            gd = categorical(hour(gd),0:23);
        case "dayname"
            gd = categorical(day(gd,'name'),datetime.DaysOfWeek.Long);
        case "dayofweek"
            gd = categorical(day(gd,gbins),1:7);
        case "dayofmonth"
            gd = categorical(day(gd,gbins),1:31);
        case "dayofyear"
            gd = categorical(day(gd,gbins),1:366);
        case "weekofmonth"
            gd = categorical(week(gd,gbins),1:6);
        case "weekofyear"
            gd = categorical(week(gd,gbins),1:54);
        case "monthname"
            gd = categorical(month(gd,'name'),datetime.MonthsOfYear.Long);
        case "monthofyear"
            gd = categorical(month(gd,gbins),1:12);
        case "quarterofyear"
            gd = categorical(quarter(gd),1:4);
        otherwise
            gd = discretize(gd,gbins,'categorical','IncludedEdge',incledge);
    end
    label = gbins + "_" + label;
end
