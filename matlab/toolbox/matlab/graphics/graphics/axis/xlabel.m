function hh = xlabel(varargin)

%   Copyright 1984-2024 The MathWorks, Inc.

nargoutchk(0, 1);
if nargout == 0
    xyzlabel("XLabel", varargin);
else
    hh = xyzlabel("XLabel", varargin);
end
