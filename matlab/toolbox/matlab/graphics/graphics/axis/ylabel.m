function hh = ylabel(varargin)

%   Copyright 1984-2024 The MathWorks, Inc.

nargoutchk(0, 1);
if nargout == 0
    xyzlabel("YLabel", varargin);
else
    hh = xyzlabel("YLabel", varargin);
end
