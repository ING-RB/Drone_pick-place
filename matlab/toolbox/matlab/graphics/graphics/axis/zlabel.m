function hh = zlabel(varargin)

%   Copyright 1984-2024 The MathWorks, Inc.

nargoutchk(0, 1);
if nargout == 0
    xyzlabel("ZLabel", varargin);
else
    hh = xyzlabel("ZLabel", varargin);
end
