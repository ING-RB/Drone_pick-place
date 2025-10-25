function setgraphicappdata(h,fieldname,value)
% This undocumented function may be removed in a future release.

%   Copyright 2008-2023 The MathWorks, Inc.

% If value contains handle of graphics object, store as object not as a double
if any(isgraphics(value), 'all')
    setappdata(h,fieldname,handle(value));
else
    setappdata(h,fieldname,value);
end
