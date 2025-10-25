function specifyThemePropertyMappings( obj, objProp, themeAttr)
% This file is for internal use only and may change in a future release 
% of MATLAB.

% SPECIFYTHEMEPROPERTYMAPPINGS flags a object in such a way that one of its
%     properties, objProp, should receive a value from a standard theme
%     attribute, themeAttr, at the time of function invocation and when the
%     theme changes. If themeAttr is specified as 'remove', any mapping for
%     the specified object and property will be removed and the default
%     behavior restored. Function can take a scalar or homogeneous vector.

% Copyright 2021-2023 The MathWorks, Inc.

arguments % most validation handled by specifyThemePropertyMapping method.
    obj matlab.graphics.Graphics
    objProp
    themeAttr
end

for i = 1:numel(obj)
    thisObj = obj(i);
    try
        thisObj.specifyThemePropertyMapping(objProp, themeAttr);
    catch e
        throw(e)
    end
end

end