function [varData, omitVars, omitRecords, metadata] = handleReplacement(varData, varOpts, ...
    importErrorRule, missingRule, errorIDs, missingIDs, metadata)
% Handles Replacement Rules for a variable

arguments
    varData
    varOpts
    importErrorRule
    missingRule
    errorIDs
    missingIDs
    metadata = missing
end

% Copyright 2019-2024 The MathWorks, Inc.

% Used for handling replacement rules
missingMetadata = ismissing(metadata);
if missingMetadata
    % readmatrix case
    numVars = 1;
    [rows, cols] = size(errorIDs);
else
    % readtable or ImportOptions case
    numVars = numel(varData);
    cols = length(varData);
    rows = size(errorIDs,1);
end

omitVars = false(1, cols);
omitRecords = false(rows, 1);

    function processRules(ids,rule,errFcn)
        switch(rule)
            case 'error'
                rowK = find(any(ids,2),1);
                colK = find(ids(rowK,:),1);
                errFcn(varOpts{colK}.Type,rowK,colK);
            case 'fill'
                for k = 1 : numVars
                    % Replace fill value
                    fill = varOpts{k}.FillValue;
                    if missingMetadata
                        [fill, varData] = matlab.io.internal.processRawFill(fill, varData);
                        if any(ids,'all')
                            varData(ids) = fill;
                        end
                        % break out since readmatrix only has single data
                        % type
                        break;
                    else
                        [fill, varData{k}] = matlab.io.internal.processRawFill(fill, varData{k});
                        if ~all(ids(:,k) == 0)
                            varData{k}(ids(:,k)) = fill;
                        end
                    end
                end
            case 'omitvar'
                % set the selected variable ID to zero so it can be filtered later.
                omitVars(:,any(ids,1)) = true;
            case 'omitrow'
                % Collect record numbers which need to be omitted
                omitRecords(any(ids,2),:) = true;
        end
    end

% Handle any error

if any(errorIDs,'all')
    processRules(errorIDs, importErrorRule, ...
        @(type, rowNum, colNum)errorRuleError(colNum, rowNum, type));
end

if any(missingIDs,'all')
    processRules(missingIDs, missingRule, ...
        @(~, rowNum, colNum)missingRuleError(colNum, rowNum));
end

% Remove omitted variables
if any(omitVars)
    varData(:,omitVars) = [];
    if ~missingMetadata
        metadata.VariableNames(omitVars(1:numel(metadata.VariableNames))) = [];
    end
end

% handle omit-records
if any(omitRecords)
    if missingMetadata
        varData(omitRecords,:) = [];
    else
        for i = 1 : numel(varData)
            varData{i}(omitRecords, :) = [];
        end
        metadata.RowNames(omitRecords(1:numel(metadata.RowNames))) = [];
    end
end
end

function errorRuleError(i,rowNum,type)
    error(message("MATLAB:spreadsheet:importoptions:ErrorRuleError", i, rowNum, type));
end

function missingRuleError(i,rowNum)
    error(message("MATLAB:spreadsheet:importoptions:MissingRuleError", i, rowNum));
end
