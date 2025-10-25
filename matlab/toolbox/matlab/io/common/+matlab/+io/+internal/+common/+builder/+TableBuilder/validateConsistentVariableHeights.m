function heights = validateConsistentVariableHeights(varargin)
%validateConsistentVariableHeights   Inputs to buildSelected() and build()
%   must have the same heights.

%   Copyright 2022 The MathWorks, Inc.

    if nargin == 0
        heights = 0;
        return;
    end

    heights = size(varargin{1}, 1);
    for index=2:nargin
        currentHeight = size(varargin{index}, 1);
        if heights ~= currentHeight
            msgid = "MATLAB:io:common:builder:BuildRequiresConsistentHeights";
            error(message(msgid, "buildSelected", heights, index, currentHeight));
        end
    end
end
