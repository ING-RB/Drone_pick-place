function [groupingData,groupVars,gvLabels,T] = parseGroupVarsTall(groupVars,isTabular,messageIdent,T)
% PARSEGROUPVARSTALL Parses grouping variables for table and matrix input.
% Returns the data to group by in a cell array groupingData and groupVars,
% which is unchanged for the matrix case, but will be the variable names of
% the grouping variables in the table case.  Also returns the grouping
% variable labels and T.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

if isTabular
    availableVariableNames = string(subsref(T, substruct('.', 'Properties', '.', 'VariableNames')));
    if isempty(groupVars)
        groupVars = string.empty;
    elseif ischar(groupVars) || iscellstr(groupVars) %#ok<ISCLSTR> 
            groupVars = string(groupVars);
    elseif isnumeric(groupVars) || islogical(groupVars)
        groupVars = availableVariableNames(groupVars);
    elseif isa(groupVars,'vartype')
        groupVars = matlab.internal.math.checkDataVariables(T.Adaptor.buildSample('double'), groupVars, messageIdent);
        groupVars = availableVariableNames(groupVars);
    end
    % Pull the grouping variables out from the tall table
    groupingData = cellfun(@(x) subsref(T,substruct('.',x)),groupVars,'Uniform',false);
    for i=1:numel(groupingData)
        groupingData{i} = tall.validateColumn(groupingData{i},'MATLAB:findgroups:GroupingVarNotVector');
    end
    gvLabels = reshape(groupVars,1,[]);
else
    if ~strcmp(messageIdent,'groupcounts')
        T = tall.validateMatrix(T,['MATLAB:',messageIdent,':FirstInputSize']);
    end
    
    % Extract grouping variables
    if ~strcmp(messageIdent,'groupcounts') && isa(groupVars,'cell')
        groupingData = groupVars(:)'; 
    else
        groupVars = tall.validateMatrix(groupVars,'MATLAB:findgroups:GroupingVarNotVector');
        tmp = array2table(groupVars);
        tmpVariableNames = subsref(tmp, substruct('.', 'Properties', '.', 'VariableNames'));
        if isempty(tmpVariableNames) % catch nx0 case
            tmp = table(groupVars);
            tmpVariableNames = subsref(tmp, substruct('.', 'Properties', '.', 'VariableNames'));
        end
        groupingData = cellfun(@(x) subsref(tmp,substruct('.',x)),tmpVariableNames,'Uniform',false);
    end
    
    % Verify vectors
    numGroupVars = numel(groupingData);
    for i=1:numGroupVars
        groupingData{i} = tall.validateColumn(groupingData{i},'MATLAB:findgroups:GroupingVarNotVector');
    end
    
    if ~strcmp(messageIdent,'groupcounts')
        % Verify size matches between data matrix and grouping vectors
        [T, groupingData{1}] = validateSameTallSize(T,groupingData{1});
    end
    
    % To avoid errors create numbered labels
    gvLabels = string(1:numGroupVars);
end