function isProtected = isProtectedProperty(metaClassObj, metaPropObj)
%This function is for internal use only. It may be removed in the future.

%isProtectedProperty Check if a property has protected access
%   ISPROTECTED = isProtectedProperty(METACLASSOBJ, METAPROPOBJ) determines
%   if the property defined by the meta property object, METAPROPOBJ, in
%   the class defined by the meta class object, METACLASSOBJ, has protected
%   access rights.
%
%   The property could either be defined as having "protected"
%   access, or have a custom set access list that contains the meta
%   class object for the defining class.

%   Copyright 2019-2023 The MathWorks, Inc.

%#codegen

    if isempty(metaPropObj)
        isProtected = false;
        return
    end

    propSetAccess = metaPropObj.SetAccess;

    % Check if property was defined by this class. Ignore
    % properties in other super or sub classes.
    isDefiningClassProp = (metaPropObj.DefiningClass == metaClassObj);
    if ~isDefiningClassProp
        isProtected = false;
        return
    end

    % Check if the property has protected access
    hasProtectedSetAccess = false;
    if iscell(propSetAccess)
        % If the property has a custom access list, see if the meta
        % class is listed as one of the accessors.
        for i = 1:length(propSetAccess)
            hasProtectedSetAccess = hasProtectedSetAccess || ...
                isequal(propSetAccess{i}, metaClassObj);
        end
    else
        % If the SetAccess is a string, compare against "protected"
        hasProtectedSetAccess = strcmp('protected', propSetAccess);
    end

    % Only return true if both booleans are true
    isProtected = isDefiningClassProp && hasProtectedSetAccess;
end
