function polarobj = thetaregion(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

narginchk(1,inf);
try
    obj = matlab.graphics.internal.polarregionhelper('ThetaSpan', varargin{:});
catch me
    throw(me)
end

if nargout > 0
    polarobj = obj;
end

end
