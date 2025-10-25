function icn = getIcon(name)
%GETICON
%
%    icn = getIcon(name)
%
%    Inputs:
%      name - string with icon name
%
%    Outputs:
%       icn - Icon instance
%
% Copyright 2013-2023 The MathWorks, Inc.

icn = matlab.ui.internal.toolstrip.Icon(name);
end