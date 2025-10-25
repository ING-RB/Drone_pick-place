function [propertyName, propertyValue] = convertScaleColorClientValueToServerValue(propertyName,propertyValue)
% SCALECOLORVALUEEDITED Converts scale colors and scalecolorlimits
% client value to server value
%
% same logic in ScaleColorsEditor.m
% when app designer switch to server driven, these logic
% can be removed, because we can get the value conversion
% for free.

% Copyright 2018 Mathworks.

    if iscell(propertyValue)
        propertyValue = cell2mat(propertyValue);
    else
        try
            propertyValue = evalin('base', ['[' propertyValue ']']);
            if ischar(propertyValue)
                propertyValue = evalin('base', ['{' propertyValue '}']);
            end
        catch
            % do nothing, the property value will be passed
            % into model, let model handle the value.
        end
        
        if strcmp(propertyName, 'ScaleColors') && ...
                ((ischar(propertyValue) && isvector(propertyValue)) || (isstring(propertyValue) && isscalar(propertyValue)))
            % Convert ' r, g b ' to {'r' 'g' 'b'} for colors
            propertyValue = strsplit(strtrim(propertyValue), ',|;|\s*', ...
                'DelimiterType', 'RegularExpression');
        elseif strcmp(propertyName, 'ScaleColorLimits') && ...
                isvector(propertyValue) && length(propertyValue) > 2 && isnumeric(propertyValue)
            % Convert [1 2 3 4] to [1 2; 2 3; 3 4] for limits
            lims = ones(length(propertyValue) - 1, 2);
            for i = 1:length(propertyValue) - 1
                lims(i, :) = propertyValue(i:i+1);
            end
            propertyName = lims;
        end
    end
end

