function tf = isLineSpec(str)
% This function is undocumented and may change in a future release.

%   Copyright 2016-2018 The MathWorks, Inc.

if matlab.graphics.internal.isCharOrString(str)
    [~,~,~,msg]=colstyle(str);
    tf = isempty(msg);
else
    tf = false;
end

end
