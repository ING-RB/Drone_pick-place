function polarobj = radiusregion(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

narginchk(1,inf);
try
    obj = matlab.graphics.internal.polarregionhelper('RadiusSpan', varargin{:});
catch me
    throw(me)
end

if nargout > 0
    polarobj = obj;
end

end
