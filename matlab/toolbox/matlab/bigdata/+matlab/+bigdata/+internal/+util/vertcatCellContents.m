function out = vertcatCellContents(c)
% Helper that performs a vertcat on the contents of a cell array.
%
% This exists as removing a layer of cells is done in the evaluation tight
% loop and the input has a good chance of being scalar. Avoiding vertcat in
% these cases proves to be much faster. Further, when there is an
% incompatible vertical concatenation, we need to ensure the error message
% points the user in the right direction.

%   Copyright 2016-2024 The MathWorks, Inc.

if isscalar(c)
    out = c{1};
else
    try
        % This must use cat instead of vertcat as vertcat allows
        % concateniation of empties with incompatible sizes.
        out = cat(1, c{:});
    catch err
        err = matlab.bigdata.BigDataException.build(err);
        
        [found, sizeStr1, sizeStr2] = iFindDifferentSize(c);
        if found
            prependMsg = message(...
                'MATLAB:bigdata:array:InvalidVertcatWithSizes', ...
                sizeStr1, sizeStr2);
        else
            prependMsg = message(...
                'MATLAB:bigdata:array:InvalidVertcat');
        end
        err = prependToMessage(err, getString(prependMsg));
        updateAndRethrow(err);
    end
end
end

function [found, sizeStr1, sizeStr2] = iFindDifferentSize(c)
% Handle a vertical concatenation error.
szStrs = unique(cellfun(@iGetChunkSizeDisplay, c, 'UniformOutput', false));
found = ~isscalar(szStrs);
sizeStr1 = szStrs{1};
sizeStr2 = szStrs{min(2, end)};
end

function str = iGetChunkSizeDisplay(chunk)
% Generate a string that contains both the size and class of the chunk.
sz = size(chunk);
szStr = join(["M", string(sz(2:end))], matlab.internal.display.getDimensionSpecifier());
str = [char(szStr), ' ', class(chunk)];
end
