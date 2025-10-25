% function returns the data as an array or scalar string using disp APIs
%
% fullData: All the data in the data model
% dataSubset: The subset of data which needs to be rendered
% isScalarOutput: true if the display should be returned as a 1x1
% scalar string, false if it should be returned as a string array
% useFullData: true if the full data should also be passed to API
% to compute the subset display. If scaling factor exists and we
% need the scaled values for a data subset then this should be
% true. If we want the raw values of the subset or no scaling
% factor exists then this should be false

% Copyright 2017-2024 The MathWorks, Inc.

function [dispData, scalingFactor, convertSubsetToComplex] = getDisplayDataAsString(fullData, dataSubset, isScalarOutput, useFullData, displayFormat)
    % defaults
    arguments
        fullData;
        dataSubset;
        isScalarOutput = false;
        useFullData = true;
        displayFormat = "short";
    end
    try
        [fullData, dataSubset] =  internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(fullData, dataSubset);
    catch
        % Handle cases for objects which lie about being numeric
        fullData = repmat([], size(fullData));
        dataSubset = repmat([], size(dataSubset));
    end
    % if full data is complex then querying for a subset might return a
    % non-complex value if that subset has all real values. So convert subset to
    % complex if data is of complex type
    convertSubsetToComplex = false;
    if ~isempty(fullData) && ~isreal(fullData)
        convertSubsetToComplex = true;
        dataSubset = complex(dataSubset);
    end

    if ~isempty(fullData) && useFullData
        [dispData, scalingFactor] =  matlab.internal.display.numericDisplay(fullData, dataSubset, 'ScalarOutput', isScalarOutput, 'Format', displayFormat);
    else
        [dispData, scalingFactor] =  matlab.internal.display.numericDisplay(dataSubset, 'ScalarOutput', isScalarOutput, 'Format', displayFormat);
    end
end
