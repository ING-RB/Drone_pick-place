function [groupingData,groupVars,gvLabels,gbForGV] = discgroupvar(groupingData,groupVars,gvLabels,groupBins,inclEdge,scalarExpandBins,scalarExpandVars,messageIdent,tableFlag)
% DISCGROUPVAR Discretize grouping variable
%   This function will discretize the grouping variables stored in 
%   groupingData according to groupBins and update the gvLabel accordingly.
%   This function also removes repeated pairs of groupVars and groupBins
%   unless the messageIdent is 'pivot'.
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

if tableFlag && ~strcmp(messageIdent,"pivot")
    % Remove repeated pairs of groupVars and groupBins
    [~,~,idx] = unique(groupVars,"stable");
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
    gbForGV = false(size(groupVars));
end

try
    % Flag for at least one successful discretization
    oneDisc = false;
    for jj = 1:numel(gvLabels)
        if isempty(groupBins{jj})
            error(message("MATLAB:"+messageIdent+":GroupBinsEmpty"));
        end
        if nargout == 4
            [groupingData{jj},gvLabels(jj),gbForGV(jj)] = discOneGroupVar(groupingData{jj},gvLabels(jj),groupBins{jj},inclEdge,messageIdent);
        else
            [groupingData{jj},gvLabels(jj)] = discOneGroupVar(groupingData{jj},gvLabels(jj),groupBins{jj},inclEdge,messageIdent);
        end
        % Succeeded with at least one discretization
        oneDisc = true;
    end
catch ME
    if (scalarExpandBins && oneDisc)
        % Return error message with added information
        m = message("MATLAB:"+messageIdent+":GroupBinsScalarExpand");
        throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
    else
        throw(ME);
    end
end

if tableFlag && ~strcmp(messageIdent,"pivot")
    % Make the labels unique
    gvLabels = matlab.lang.makeUniqueStrings(gvLabels);
end

%--------------------------------------------------------------------------
function [gd,label,flag] = discOneGroupVar(gd,label,gbins,incledge,messageIdent)
% Discretize one grouping variable
flag = true;
if strcmpi(gbins,"none")
    flag = false;
    return;
elseif (isnumeric(gbins) || isduration(gbins) || iscalendarduration(gbins) || isdatetime(gbins))
    try
        gd = discretize(gd,gbins,"categorical","IncludedEdge",incledge);
        label = "disc_"+label;
    catch ME
        % Return error message
        gbins = string(gbins);
        if isscalar(gbins) && ~ismissing(gbins)
            m = message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label);
            throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
        else
            m = message("MATLAB:"+messageIdent+":GroupBinsErrorUnnamed",label);
            throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
        end
    end
else
    try
        if isduration(gd) || isdatetime(gd)
            switch lower(gbins)
                case "secondofminute"
                    gd = categorical(floor(second(gd)),0:59);
                case "minuteofhour"
                    gd = categorical(minute(gd),0:59);
                case "hourofday"
                    if isduration(gd)
                        error(message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label));
                    else
                        gd = categorical(hour(gd),0:23);
                    end
                case "dayname"
                    gd = categorical(day(gd,"name"),datetime.DaysOfWeek.Long);
                case "dayofweek"
                    if isduration(gd)
                        error(message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label));
                    else
                        gd = categorical(day(gd,gbins),1:7);
                    end
                case "dayofmonth"
                    if isduration(gd)
                        error(message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label));
                    else
                        gd = categorical(day(gd,gbins),1:31);
                    end
                case "dayofyear"
                    if isduration(gd)
                        error(message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label));
                    else
                        gd = categorical(day(gd,gbins),1:366);
                    end
                case "weekofmonth"
                    gd = categorical(week(gd,gbins),1:6);
                case "weekofyear"
                    gd = categorical(week(gd,gbins),1:54);
                case "monthname"
                    if isduration(gd)
                        error(message("MATLAB:duration:MonthsNotSupported","month"));
                    else
                        gd = categorical(month(gd,"name"),datetime.MonthsOfYear.Long);
                    end
                case "monthofyear"
                    if isduration(gd)
                        error(message("MATLAB:duration:MonthsNotSupported","month"));
                    else
                        gd = categorical(month(gd,gbins),1:12);
                    end
                case "quarterofyear"
                    gd = categorical(quarter(gd),1:4);
                otherwise
                    gd = discretize(gd,gbins,"categorical","IncludedEdge",incledge);
            end
        else
            gd = discretize(gd,gbins,"categorical","IncludedEdge",incledge);
        end
    catch ME
        % Return error message
        m = message("MATLAB:"+messageIdent+":GroupBinsError",gbins,label);
        throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
    end
    label = gbins+"_"+label;
end