function [dvData,dataLabels,numDataVars] = extractDataVarsTall(T,isTabular,dataVars)
% EXTRACTDATAVARSTall Extracts data variables for table and matrix input by
% putting each data vector into a cell array. Returns a cell array with the
% data vectors, the labels associated with the data, and the number of data
% variables.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

if isTabular
    % Compute labels
    dataLabels = dataVars;
    numDataVars = numel(dataLabels);
    
    % Get data variables datavars in cell dvData
    dvData = cellfun(@(x) subsref(T,substruct('.',x)),dataVars,'Uniform',false);
else
    tmp = array2table(T);
    tmpVariableNames = subsref(tmp, substruct('.', 'Properties', '.', 'VariableNames'));
    if isempty(tmpVariableNames) % catch nx0 case
        tmp = table(T);
        tmpVariableNames = subsref(tmp, substruct('.', 'Properties', '.', 'VariableNames'));
    end
    dvData = cellfun(@(x) subsref(tmp,substruct('.',x)),tmpVariableNames,'Uniform',false);
    numDataVars = numel(dvData);
    % To avoid errors create numbered labels
    dataLabels = string(1:numDataVars);
end