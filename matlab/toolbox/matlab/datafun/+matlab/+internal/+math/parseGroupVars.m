function [groupingData,groupVars] = parseGroupVars(groupVars,tableFlag,messageIdent,T)
% PARSEGROUPVARS Parses grouping variables for table and matrix input.
% Returns the data to group by in a cell array groupingData and groupVars,
% which is unchanged for the matrix case, but will be the variable names of
% the grouping variables in the table case.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

flag = extractAfter(messageIdent,":");
messageIdent = extractBefore(messageIdent,":");

if tableFlag
    % Extract grouping variables
    [groupVars,T] = matlab.internal.math.checkDataVariables(T,groupVars,messageIdent,flag);
    varNamesT = string(T.Properties.VariableNames);
    groupVars = varNamesT(groupVars);

    groupingData = cell(1,numel(groupVars));
    for jj = 1:numel(groupVars)
        groupingData{jj} = T.(groupVars(jj));
        % Check data is column vector since mgrp2idx allows row vectors also
        if ~iscolumn(groupingData{jj})
            if strcmp(messageIdent,"pivot")
                error(message("MATLAB:pivot:" + flag + "VarNotVector"));
            else
                error(message("MATLAB:findgroups:GroupingVarNotVector"));
            end
        end
    end
else
    if nargin == 4
        if iscell(T) && ~iscellstr(T) && strcmp(messageIdent,"groupsummary") %#ok<ISCLSTR>
            % Ensure cells are matrices or vectors
            for jj = 1:numel(T)
                if ~ismatrix(T{jj}) || isstruct(T{jj}) || isa(T{jj},"function_handle")
                    error(message("MATLAB:"+messageIdent+":FirstInputSize"));
                end
            end
        else
            % Ensure the data is a matrix or vector
            if ~ismatrix(T) || isstruct(T) || isa(T,"function_handle")
                if strcmp(messageIdent,"groupsummary") || strcmp(messageIdent,"groupfilter")
                    error(message("MATLAB:"+messageIdent+":FirstInputSize"));
                else
                    error(message("MATLAB:"+messageIdent+":FirstInputType"));
                end
            end
        end
    end
    
    % Error for function handle grouping variable
    if isa(groupVars,"function_handle")
        if strcmp(messageIdent,"groupcounts")
            error(message("MATLAB:"+messageIdent+":FirstInputSize"));
        else
            error(message("MATLAB:"+messageIdent+":SecondInputType"));
        end
    end
    
    % Extract grouping variables
    if iscell(groupVars)
        if isempty(groupVars)
            groupingData = cell(1,0);
        elseif iscellstr(groupVars)
            groupingData = {groupVars};
        else
            groupingData = groupVars(:)';
        end
        % Verify grouping variables are column vectors
        numGroupVars = numel(groupingData);
        for k=1:numGroupVars
            if ~iscolumn(groupingData{k})
                error(message("MATLAB:findgroups:GroupingVarNotVector"));
            end
        end
    else 
        if ~ismatrix(groupVars)
            error(message("MATLAB:findgroups:GroupingVarNotVector"));
        end
        numGroupVars = size(groupVars,2);
        groupingData = cell(1,numGroupVars);
        for k=1:numGroupVars
            groupingData{k} = groupVars(:,k);
        end
    end 
    
    if nargin == 4
        if iscell(T) && ~iscellstr(T) && strcmp(messageIdent,"groupsummary") %#ok<ISCLSTR>
            % Verify size matches between data matrix and grouping vectors
            if isempty(groupVars)
                % This checks the data vs groups for 100x0 vs 100xN and 0x1 vs 0xM
                if ismatrix(groupVars) && (size(groupVars,1)~=0 || size(groupVars,2)~=0)
                    for jj = 1:numel(T)
                        if size(T{jj},1) ~= size(groupVars,1)
                            error(message("MATLAB:"+messageIdent+":FirstSecondMismatchSize"));
                        end
                    end
                elseif size(groupVars,1) == 0 && size(groupVars,2) == 0
                    % groupVars is [] and make sure all the data is the 
                    % same height
                    n = size(T{1},1);
                    for jj = 1:numel(T)
                        if size(T{jj},1) ~= n
                            error(message("MATLAB:"+messageIdent+":FirstInputSizeCellRows"));
                        end
                    end
                end
            else
                for jj = 1:numel(T)
                    if size(T{jj},1) ~= size(groupingData{1},1)
                        error(message("MATLAB:"+messageIdent+":FirstSecondMismatchSize"));
                    end
                end
            end
        else
            % Verify size matches between data matrix and grouping vectors
            if isempty(groupVars)
                % This checks the data vs groups for 100x0 vs 100xN and 0x1 vs 0xM
                if ismatrix(groupVars) && (size(groupVars,1)~=0 || size(groupVars,2)~=0)
                    if size(T,1) ~= size(groupVars,1)
                        error(message("MATLAB:"+messageIdent+":FirstSecondMismatchSize"));
                    end
                end
            else
                if size(T,1) ~= size(groupingData{1},1)
                    error(message("MATLAB:"+messageIdent+":FirstSecondMismatchSize"));
                end
            end
        end
    end
end
