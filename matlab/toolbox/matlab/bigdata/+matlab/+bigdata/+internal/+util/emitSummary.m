function summaryStruct = emitSummary(summaryInfo, tableProperties, isDisplay)
%emitSummary Emit the struct to be returned by 'summary'

% Copyright 2016-2024 The MathWorks, Inc.

summaryStruct = struct();

[min_label, max_label, true_label, false_label] = getSummaryLabels();

emptyCellstr = repmat({''}, 1, numel(summaryInfo));

% Maybe offset into tableProperties per-variable properties depending on
% whether there is an extra summaryInfo
tablePropertiesOffset = getTablePropertiesOffset(summaryInfo);

if isempty(tableProperties.VariableDescriptions)
    varDescrs = emptyCellstr;
else
    varDescrs = tableProperties.VariableDescriptions;
end
if isempty(tableProperties.VariableUnits)
    varUnits = emptyCellstr;
else
    varUnits = tableProperties.VariableUnits;
end
if isempty(tableProperties.VariableContinuity)
    varContinuity = repmat({[]}, 1, numel(summaryInfo));
else
    varContinuity = num2cell(tableProperties.VariableContinuity);
end

% Handle custom properties
customVarPropNames = getPerVarPropNames(tableProperties);

varNames = cellfun(@(info) info.Name, summaryInfo, "UniformOutput", false);
[varNames, modified] = matlab.lang.makeValidName(varNames);
if any(modified)
    varNames = matlab.lang.makeUniqueStrings(varNames);
    if ~isDisplay
        % Disable warning for display only calls
        matlab.internal.datatypes.warningWithoutTrace(message("MATLAB:table:ModifiedVarnames"));
    end
end

for idx = 1:numel(summaryInfo)
    thisInfo = summaryInfo{idx};
    tpIdx = idx - tablePropertiesOffset;
    isRowTimesInfo = (tpIdx == 0);
    if ~isRowTimesInfo
        thisInfo.Description = varDescrs{tpIdx};
        thisInfo.Units = varUnits{tpIdx};
        thisInfo.Continuity = varContinuity{tpIdx};
    end
    thisElement = [];
    infoFields  = {'Size', 'Type', ...
                   'Description', 'Units', ...
                   'Continuity', ...
                   'TimeZone', ...
                   'SampleRate', 'StartTime'};
    elFields    = {'Size', 'Type', ...
                   'Description', 'Units', ...
                   'Continuity', ...
                   'TimeZone', ...
                   'SampleRate', 'StartTime'};
    for jdx = 1:numel(infoFields)
        thisElement = iAddFieldIfPresent(thisElement, thisInfo, ...
                                         infoFields{jdx}, elFields{jdx});
    end
    
    if isfield(thisInfo, 'CategoricalInfo')
        thisElement.Categories = thisInfo.CategoricalInfo{1};
        % Fix up the case of empty categoricals - must be {} not cell(0,1).
        if prod(thisInfo.Size) == 0 && isempty(thisElement.Categories)
            thisElement.Categories = {};
        end
        
        counts = thisInfo.CategoricalInfo{2};
        gotUndef = ~isempty(thisElement.Categories) && ...
            strcmp(thisElement.Categories{end}, 'NumMissing');

        if gotUndef
            % 'Undefined' output is always the final *row* from counts. This isn't
            % completely consistent with the overall 'Counts' output.
            undefCount = counts(end, :);
            counts(end, :) = [];
            % Remove '<undefined>' from categories list
            thisElement.Categories(end) = [];
        else
            undefCount = zeros(1, size(counts, 2));
        end

        thisElement.Counts = counts;
        % Update 'NumMissing' to ensure consistency with the total of
        % <undefined> in counts.
        thisInfo.NumMissing = undefCount;
    end

    infoFields  = {'NumMissing', ...
                   'MinVal', 'MaxVal', ...
                   'true', 'false' };
    elFields    = {'NumMissing', ...
                   min_label, max_label, ...
                   true_label, false_label};
    for jdx = 1:numel(infoFields)
        thisElement = iAddFieldIfPresent(thisElement, thisInfo, ...
                                         infoFields{jdx}, elFields{jdx});
    end

    if isfield(thisInfo, 'MeanInfo')
        thisElement.Mean = thisInfo.MeanInfo{1};
    end

    % Also add custom properties (but not for RowTimes)
    if ~isRowTimesInfo
        for jdx = 1:numel(customVarPropNames)
            thisElement.CustomProperties.(customVarPropNames{jdx}) = ...
                tableProperties.CustomProperties.(customVarPropNames{jdx})(tpIdx);
        end
    end

    if isRowTimesInfo && isfield(thisInfo, 'TimeStep')
        % Add TimeStep at the end of the summary struct.
        thisElement.TimeStep = thisInfo.TimeStep;
    end
    
    summaryStruct.(varNames{idx}) = thisElement;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copy field from computed summary into result if it is present.
function s = iAddFieldIfPresent(s, info, infoField, sField)
if isfield(info, infoField)
    s.(sField) = info.(infoField);
end
end
