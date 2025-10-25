function [groupBins,scalarExpandBins,scalarExpandVars,flag] = parsegroupbins(groupBins,numGroupVars,messageIdent)
% PARSEGROUPBINS Checks if we in fact have groupbins and they have correct 
% partial matching.  Assembles groupBins into a cell array.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2023 The MathWorks, Inc.

if isstring(groupBins)
    groupBins = num2cell(groupBins);
end
if ischar(groupBins) || isnumeric(groupBins) || isduration(groupBins) || iscalendarduration(groupBins) || isdatetime(groupBins)
    groupBins = {groupBins};
end

flag = true;
scalarExpandBins = false;
scalarExpandVars = false;
for j = 1:numel(groupBins)
    if ischar(groupBins{j}) || isstring(groupBins{j})
        if strcmpi(groupBins{j},"second")
            groupBins{j} = "second";
        elseif strcmpi(groupBins{j},"minute")
            groupBins{j} = "minute";
        elseif strcmpi(groupBins{j},"hour")
            groupBins{j} = "hour";
        elseif strcmpi(groupBins{j},"day")
            groupBins{j} = "day";
        elseif strcmpi(groupBins{j},"week")
            groupBins{j} = "week";
        elseif strcmpi(groupBins{j},"month")
            groupBins{j} = "month";
        elseif strcmpi(groupBins{j},"quarter")
            groupBins{j} = "quarter";
        elseif strncmpi(groupBins{j},"year",1)
            groupBins{j} = "year";
        elseif strncmpi(groupBins{j},"decade",2)
            groupBins{j} = "decade";
        elseif strncmpi(groupBins{j},"century",1)
            groupBins{j} = "century";
        elseif strncmpi(groupBins{j},"secondofminute",7)
            groupBins{j} = "secondofminute";
        elseif strncmpi(groupBins{j},"minuteofhour",7)
            groupBins{j} = "minuteofhour";
        elseif strncmpi(groupBins{j},"hourofday",5)
            groupBins{j} = "hourofday";
        elseif strncmpi(groupBins{j},"dayname",4)
            groupBins{j} = "dayname";
        elseif strncmpi(groupBins{j},"dayofweek",6)
            groupBins{j} = "dayofweek";
        elseif strncmpi(groupBins{j},"dayofmonth",6)
            groupBins{j} = "dayofmonth";
        elseif strncmpi(groupBins{j},"dayofyear",6)
            groupBins{j} = "dayofyear";
        elseif strncmpi(groupBins{j},"weekofmonth",7)
            groupBins{j} = "weekofmonth";
        elseif strncmpi(groupBins{j},"weekofyear",7)
            groupBins{j} = "weekofyear";
        elseif strncmpi(groupBins{j},"monthofyear",6)
            groupBins{j} = "monthofyear";
        elseif strncmpi(groupBins{j},"monthname",6)
            groupBins{j} = "monthname";
        elseif strncmpi(groupBins{j},"quarterofyear",8)
            groupBins{j} = "quarterofyear";
        elseif (startsWith(messageIdent,"groupcounts") && strncmpi(groupBins{j},"none",max(strlength(groupBins{j}),1))) || ...
                (startsWith(messageIdent,"groupsummary") && strncmpi(groupBins{j},"none",max(strlength(groupBins{j}),2))) || ...
                (startsWith(messageIdent,"grouptransform") && strncmpi(groupBins{j},"none",max(strlength(groupBins{j}),3))) || ...
                (startsWith(messageIdent,"groupfilter") && strncmpi(groupBins{j},"none",max(strlength(groupBins{j}),1))) || ...
                (startsWith(messageIdent,"pivot") && strncmpi(groupBins{j},"none",max(strlength(groupBins{j}),1)))
            groupBins{j} = "none";
        else
            if j == 1 && startsWith(messageIdent,"groupsummary")
                % Partial match didn't work, go to method parsing
                flag = false;
                return;
            else
                error(message("MATLAB:"+messageIdent+"BinsEmpty"));
            end
        end
    end   
end

numGroupBins = numel(groupBins);

% Number of groupBins must match numGroupVars unless groupBins is 1 or we
% can do scalar expansion
if isequal(numGroupBins,1)
    if isempty(groupBins{1})
        error(message("MATLAB:"+messageIdent+"BinsEmpty"));
    elseif isequal(numGroupVars,0) && ~strcmpi(groupBins{1},"none")
        error(message("MATLAB:"+messageIdent+"BinsNoGroupVars"));
    else
        groupBins = repmat(groupBins,1,numGroupVars);
        if (numGroupVars > 1)
            scalarExpandBins = true;
        end
    end
elseif ~isequal(numGroupVars,numGroupBins)
    if numGroupVars == 1
        % We can do scalar expansion
        scalarExpandVars = true;
    else
        error(message("MATLAB:"+messageIdent+"BinsVarsDiffSize"));
    end
end
end
