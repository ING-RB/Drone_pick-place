% gets the formatted numeric data.

% TODO: This is not a peer functionality, move this to FormatDataUtils

% Copyright 2017-2025 The MathWorks, Inc.

function [renderedData, renderedDims, scalingFactorString] = getFormattedNumericData(fullData, dataSubset, scalingFactorString, displayFormat, showMultipliedExponent)
    arguments
        fullData;
        dataSubset;
        scalingFactorString = strings(0);
        displayFormat = 'short';
        showMultipliedExponent (1,1) logical = false;
    end

    convertSubsetToComplex = false;
    if ~isempty(dataSubset)

        [fullData, dataSubset] = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(fullData, dataSubset);

        useFullData = ~isempty(scalingFactorString);
        if ~useFullData
            % Need to check to see if the data subset has a different
            % scaling factor than the full dataset.  If so we need to pass
            % in the full dataset to the numeric display API so that it
            % formats things correctly.  We try not to do this all the time
            % because it can be slower to use the full dataset when you have a
            % large array.
            subsetScalingFactor = num2str(internal.matlab.variableeditor.peer.PeerDataUtils.getScalingFactor(dataSubset));
            useFullData = ~isempty(subsetScalingFactor);
        end

        vals = cell(size(dataSubset,2),1);

        if  useFullData
            % either scaling factor is greater than 1 or it needs to be computed
            % if scaling factor is greater than 1 then disp data should be
            % queried by calling the API with full data and data subset
            [dispData, scalingFactor, convertSubsetToComplex] = internal.matlab.variableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, dataSubset, false, true, displayFormat);
            scalingFactorString = num2str(scalingFactor);
        else
            % if scaling factor is empty then we default/assume that the data
            % has no scaling factor (.i.e. scaling factor is 1)
            [dispData, displayScalingFactor] = internal.matlab.variableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, dataSubset, false, false, displayFormat);
            % If we had empty scalingFactorString but displayScalingFactor is
            % not empty, could be a different display format like long causing a
            % scaling factor. Update the scalingFactorString so that we multiply
            % with exponent.(g2713710)
            if isempty(scalingFactorString) && (displayScalingFactor ~= 1) 
                scalingFactorString = num2str(displayScalingFactor);
            end
        end

        % if not live editor and scaling factor exists then compute raw values
        % TODO: Fix widget registry so the view model does not know about live
        % editor
        if ~isempty(scalingFactorString) && showMultipliedExponent
            for column=1:size(dataSubset,2)
                subset = dataSubset(:,column);
                if convertSubsetToComplex == true
                    subset = complex(dataSubset(:,column));
                end
                vals{column} = {cellstr(matlab.internal.display.numericDisplay(subset, subset, 'ScalarOutput', false, 'Format', displayFormat, 'OmitScalingFactor', true))};
            end
            renderedData = [vals{:}];

            if ~isempty(renderedData)
                renderedData = [renderedData{:}];
            end
            % if live editor
        else
            renderedData = cellstr(dispData);
        end
        renderedDims = size(renderedData);
    else
        renderedDims = size(dataSubset);
        renderedData = cell(renderedDims);
    end
end
