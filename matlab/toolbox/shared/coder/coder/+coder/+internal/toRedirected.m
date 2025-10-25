function [redirectedObj, changed] = toRedirected(obj)
    % toRedirected

    % Copyright 2016-2022 The MathWorks, Inc.
    objClass = builtin('class', obj);
    if issparse(obj)
        redirectedObjClass = 'coder.internal.sparse';
    else
        redirectedObjClass = coder.internal.getRedirectedClassName(objClass);
    end
    if strcmp(redirectedObjClass, objClass)
        redirectedObj = obj;
        changed = false;
    else
        if ~coder.internal.hasStaticMethod(redirectedObjClass, 'matlabCodegenToRedirected', SearchParentClasses=false)
                % If there is no matlabCodegenToRedirected then this class cannot
                % be accepted as an input.
            error(message('Coder:common:NoMatlabCodegenToRedirected', objClass));
        end
        redirectedObj = coder.internal.callMATLABCodegenStaticMethod(redirectedObjClass, 'matlabCodegenToRedirected', obj, SearchParentClasses = false);
        changed = true;
    end
