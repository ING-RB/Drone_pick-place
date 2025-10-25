function list = colormaplist()
%

%  Copyright 2024 The MathWorks, Inc.
narginchk(0,0)
if isdeployed
    error(message('MATLAB:colormap:FunctionNotSupported'))
else
    list = matlab.graphics.internal.getcolormaplist();
end
end