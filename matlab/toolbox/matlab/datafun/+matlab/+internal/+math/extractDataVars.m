function [dvData,dataLabels,numDataVars] = extractDataVars(T,groupVars,dataVars,tableFlag,dvNotProvided,allowCellT)
% EXTRACTDATAVARS Extracts data variables for table and matrix input by
% putting each data vector into a cell array. Returns a cell array with the
% data vectors, the labels associated with the data, and the number of data
% variables.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.
if nargin < 6
    allowCellT = false;
end
if tableFlag
    if dvNotProvided
        if istimetable(T)
            idx = ismember(groupVars,T.Properties.DimensionNames{1});
            groupVars(idx) = [];
        end
        dataVars = setdiff(dataVars,groupVars,"stable");
    end
    numDataVars = numel(dataVars);
    dataLabels = dataVars;
    dvData = cell(1,numDataVars);
    for k=1:numDataVars
        dvData{k} = T.(dataVars(k));
    end
else
    % For matrix case, the number of dataVars is the number of columns
    numDataVars = size(T,2);
    
    if (numDataVars ~= 0)        
        % Copy columns over to cell array
        if allowCellT && iscell(T) && ~iscellstr(T) %#ok<ISCLSTR>
            % This is the case where we have a cell with one vector or
            % matrix
            t = T{1};
            if isempty(t) && size(t,2) < 2
                dvData = T;
                numDataVars = 1;
            else
                dvData = mat2cell(t,size(t,1),ones(1,size(t,2)));
                numDataVars = numel(dvData);
            end
        else
            dvData = cell(1,numDataVars);
            for k=1:numDataVars
                dvData{k} = T(:,k);
            end
        end
        % To avoid errors create numbered labels
        dataLabels = string(1:numDataVars);
    else
        % Special case where the input is an nx0 vector
        numDataVars = 1;
        dataLabels="1";
        dvData{1} = T;
    end
end