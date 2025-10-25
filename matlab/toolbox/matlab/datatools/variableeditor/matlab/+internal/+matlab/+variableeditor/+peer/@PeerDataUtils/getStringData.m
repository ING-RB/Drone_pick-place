% Returns the string data

% Copyright 2017-2023 The MathWorks, Inc.

function [stringData] = getStringData(fullData, dataSubset, rows, cols, scalingFactor, displayFormat)
    arguments
        fullData
        dataSubset
        rows
        cols
        scalingFactor  = strings(0);
        displayFormat = "short"
    end
    if (isnumeric(dataSubset) || islogical(dataSubset)) && ismatrix(dataSubset) && ~isempty(dataSubset)
        subset = dataSubset(1:rows, 1:cols);
        if ~isempty(scalingFactor)
            % if scaling factor exists pass the display APIs should be called
            % with the fullData
            [stringData, scalingFactor] = internal.matlab.variableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, subset, true, true, displayFormat);
            stringData = sprintf("\n\t1.0e+%02d *\n%s", log10(scalingFactor), stringData);
        else
            % if no scaling factor exists the the display APIs should be called
            % without using fullData for better performance
            stringData = internal.matlab.variableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, subset, true, false, displayFormat);
        end
    else
        % Indexing will not work for types like curve-fitting objects that
        % cannot be concatenated. Fallback to disp'ing everything (g2032641).
        try
            stringData = evalc('disp(dataSubset(1:rows, 1:cols))');
        catch
            stringData = evalc('disp(dataSubset)');
        end
    end
end
