function [colorDisplayData, errID, varargout] = getColorDisplayData( ...
    rawColorData, xData, yData, xDisplayData, yDisplayData, ...
    missingDataValue, varargin)
% Return the ColorData sorted based on the XDisplayData and YDisplayData.

% Copyright 2016-2017 The MathWorks, Inc.

% Determine the size of the ColorData.
[ny,nx] = size(rawColorData);

% Determine whether to calculate additional arguments passed via varargin
% e.g. counts and/or rowindices.
numAdditional = numel(varargin);
additionalData = false(1, numAdditional);
varargout = cell(1, numAdditional);
for n = 1:numAdditional
    data = varargin{n};
    additionalData(n) = size(data,1) == ny && size(data,2) == nx;
    if additionalData(n)
        varargout{n} = data;
    end
end

% Validate the size of XData and YData with respect to the ColorData.
if numel(xData) ~= nx
    % XData does not match the number of columns in ColorData.
    errID = 'MATLAB:graphics:heatmap:XDataMismatch';
    colorDisplayData = rawColorData;
elseif numel(yData) ~= ny
    % YData does not match the number of rows in ColorData.
    errID = 'MATLAB:graphics:heatmap:YDataMismatch';
    colorDisplayData = rawColorData;
else
    % XData and YData match the size of ColorData.
    errID = '';
    
    % Determine if there are any values in XDisplayData or YDisplayData
    % that are not present in the XData/YData.
    [havexdata,xloc] = ismember(xDisplayData,xData);
    [haveydata,yloc] = ismember(yDisplayData,yData);
    
    if all(havexdata) && all(haveydata)
        % We have data for all the display data values, so just sort the
        % ColorData to match the sorting of the display data.
        colorDisplayData = rawColorData(yloc,xloc);
        
        % Calculate the corresponding counts.
        for n = 1:numAdditional
            if additionalData(n)
                varargout{n} = varargin{n}(yloc,xloc);
            end
        end
    else
        % Some display data values do not have matching data, so
        % pre-populate the output based on the missing data value, then
        % fill in the values we have data for.
        nx = size(xDisplayData,1);
        ny = size(yDisplayData,1);
        colorDisplayData = missingDataValue(ones(ny,nx));
        colorDisplayData(haveydata,havexdata) = ...
            rawColorData(yloc(haveydata),xloc(havexdata));
        
        % Calculate the corresponding counts.
        for n = 1:numAdditional
            if additionalData(n)
                varargout{n} = zeros(ny,nx);
                varargout{n}(haveydata,havexdata) = ...
                    varargin{n}(yloc(haveydata),xloc(havexdata));
            end
        end
    end
end