function [obj, changed] = fromRedirected(redirectedObj)
%

%   Copyright 2017-2022 The MathWorks, Inc.

redirectedObjClass = builtin('class', redirectedObj);
if coder.internal.hasStaticMethod(redirectedObjClass, 'matlabCodegenFromRedirected', SearchParentClasses=false)
    obj = coder.internal.callMATLABCodegenStaticMethod(redirectedObjClass, 'matlabCodegenFromRedirected', redirectedObj, SearchParentClasses = false);
    changed = true;
else
    obj = redirectedObj;
    changed = false;
end
