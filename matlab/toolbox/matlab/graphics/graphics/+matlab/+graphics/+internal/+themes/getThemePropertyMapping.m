function themeAttr = getThemePropertyMapping(obj,propName)
% This file is for internal use only and may change in a future release 
% of MATLAB.

% GETTHEMEPROPERTYMAPPING retrieves information from an object instance, 
%     obj, about whether there is a theme mapping in place for that 
%     object's property,propName. If no mapping exists, the return value
%     be an empty string. If a mapping exists, the attribute name will be 
%     returned.
%

% Copyright 2022 The MathWorks, Inc.

% Check inputs
arguments
    obj (1,1) matlab.graphics.Graphics
    propName (1,1) string {mustBePropertyOfClass(propName,obj)}
end

% Clean up property name capitalization & partial property names.
propName = matlab.graphics.internal.validatePartialPropertyNames(class(obj), propName);

themeAttr = obj.getThemePropertyMapping(propName);

end

function mustBePropertyOfClass(p, obj)
try
    assert(isvalid(obj));
    matlab.graphics.internal.validatePartialPropertyNames(class(obj), p);
catch
    error(message("MATLAB:graphics:themes:InvalidClassProperty",class(obj)));
end
end