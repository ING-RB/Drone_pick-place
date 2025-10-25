function ObjList=findall(HandleList,varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

if ~isa(HandleList,'matlab.graphics.Graphics') && any(~isgraphics(HandleList), 'all')
    error(message('MATLAB:findall:InvalidHandles'));
end

% Set ShowHiddenHandles to true. Don't use an onCleanup object because the
% anonymous function is a performance bottleneck.
root = groot();
startingSHH = root.ShowHiddenHandles;
root.ShowHiddenHandles = true;

try
    ObjList=findobj(HandleList,varargin{:});
    root.ShowHiddenHandles = startingSHH;
catch
    root.ShowHiddenHandles = startingSHH;
    error(message('MATLAB:findall:InvalidParameter'));
end

end
