function [status, msg, metaMethod] = convertMethodNameToMetaMethod(testClass, methodName)
%

% Copyright 2020 The MathWorks, Inc.

status = false;

metaMethod = findobj(testClass.MethodList, 'Name', methodName);
if isempty(metaMethod)
    msg = message('MATLAB:unittest:TestSuite:InvalidMethodName', methodName, testClass.Name);
    metaMethod = [];
    return;
end

if ~(metaclass(metaMethod) <= ?matlab.unittest.meta.method)
    msg = message("MATLAB:unittest:Test:TestMethodAttributeNeeded");
    metaMethod = [];
    return;
end

if ~metaMethod.Test
    msg = message('MATLAB:unittest:Test:TestMethodAttributeNeeded');
    metaMethod = [];
    return;
end

status = true;
msg = message.empty;
end

