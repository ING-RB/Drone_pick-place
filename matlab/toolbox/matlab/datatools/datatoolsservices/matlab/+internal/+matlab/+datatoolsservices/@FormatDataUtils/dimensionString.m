% dimensionString Obtain the dimension string of the given input. This is
% the same as matlab.internal.display.dimensionString except:
% 
% * the times symbol (×) is fixed instead of switching between × and x
% based on matlab.internal.display.isDesktopInUse.
%
% * this version will return '' if the size of the input variable is empty.

% Copyright 2015-2025 The MathWorks, Inc.

function str = dimensionString(inp)
    sz = string(size(inp));
    ndims = numel(sz);
    dimStr = internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL;

    % MATFileVariable.size might return ["" ""].
    sz(sz == "") = [];

    if ndims <= 4
        str = strjoin(sz,dimStr);
    else
        str = ndims + "-D";
    end
    
    str = char(str);
end
