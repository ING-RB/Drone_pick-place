function classUsesPropertyValueDisplay = doesClassUsePropertyValuePairDisplay(obj, optional)
% doesClassUsePropertyValuePairDisplay returns true for all classes that
% use the default object display format (i.e. property-value pair display).
% The API returns false for classes that do not use this format, which 
% include classes that provide text-based display customization by 
% overriding DISP/ DISPLAY for example.

%   Copyright 2023 The MathWorks, Inc.

arguments(Input)
    obj (1, :) {mustBeNonempty}
    % Optional parameters
    % Issue an error if the input object is not a MATLAB class or it
    % provides a text-based display customization
    optional.IssueError (1,1) logical = false
end
arguments(Output)
    classUsesPropertyValueDisplay (1,1) logical
end

import matlab.display.internal.isMCOSClass;

mc = metaclass(obj);

% Check if object overrides disp/ display
dispImpl = findobj(mc.MethodList, 'Name', 'disp');
displayImpl = findobj(mc.MethodList, 'Name', 'display');
hasDispImpl = ~isempty(dispImpl) && ...
    ~strcmp(dispImpl.DefiningClass.Name, "matlab.mixin.CustomDisplay");
hasDisplayImpl = ~isempty(displayImpl) && ...
    ~strcmp(displayImpl.DefiningClass.Name, "matlab.mixin.CustomDisplay");

% Check if object overrides CustomDisplay's displayScalarObject or
% displayNonScalarObject
displayScalarObjectImpl = findobj(mc.MethodList, 'Name', 'displayScalarObject');
displayNonScalarObjectImpl = findobj(mc.MethodList, 'Name', 'displayNonScalarObject');
hasDisplayScalarObjectImpl = isa(obj, "matlab.mixin.CustomDisplay") && ...
    ~strcmp(displayScalarObjectImpl.DefiningClass.Name, "matlab.mixin.CustomDisplay");
hasDisplayNonScalarObjectImpl = isa(obj, "matlab.mixin.CustomDisplay") && ...
    ~strcmp(displayNonScalarObjectImpl.DefiningClass.Name, "matlab.mixin.CustomDisplay");

if isMCOSClass(obj) && ~hasDispImpl && ~hasDisplayImpl && ...
        ~hasDisplayScalarObjectImpl && ~hasDisplayNonScalarObjectImpl && ...
        ~isenum(obj)
    classUsesPropertyValueDisplay = true;
else
    if ~optional.IssueError
        classUsesPropertyValueDisplay = false;
    else
        if ~isMCOSClass(obj)
            error(message('MATLAB:objectPropertyDisplay:InputMustBeObject'));
        else
            error(message('MATLAB:objectPropertyDisplay:UnsupportedDisplayCustomization'));
        end
    end
end
end