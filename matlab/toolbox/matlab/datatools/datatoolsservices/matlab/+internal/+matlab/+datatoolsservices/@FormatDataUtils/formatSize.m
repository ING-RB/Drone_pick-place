% Returns the formatted size

% Copyright 2015-2023 The MathWorks, Inc.

function displaySize = formatSize(data, truncateDimensions)
    arguments
        data
        truncateDimensions (1,1) logical = true
    end
    % Temp code, removing this dependency from datatoolsservices
    try
        if isa(data, 'internal.matlab.legacyvariableeditor.NullValueObject')
            % Treat the internal NullValueObject as not having a size
            displaySize = '0';
        else
            if isa(data, 'matlab.mixin.internal.CustomSizeString')
                % This class creates a custom size string for whos, so we need to
                % use the same value.

                w = whos('data');
                s = w.size;
            elseif usejava('jvm') && isjava(data)
                % Always treat Java objects as 1x1, as is done elsewhere
                s = [1,1];
            else
                s = size(data);
            end
            displaySize = internal.matlab.datatoolsservices.FormatDataUtils.getFormattedSize(s, truncateDimensions);
        end
    catch
        % Show 1x1 for classes which error for some reason, for example if a class definition is changed
        % and an error is inserted, while the class exists as a variable in the workspace.
        displaySize = internal.matlab.datatoolsservices.FormatDataUtils.getFormattedSize([1,1], truncateDimensions);
    end
end
