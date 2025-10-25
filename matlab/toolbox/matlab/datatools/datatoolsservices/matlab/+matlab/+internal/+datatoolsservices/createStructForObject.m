% This class is unsupported and might change or be removed without
% notice in a future version.

% Utility to creat a structure from an object

% Copyright 2013-2025 The MathWorks, Inc.

function s = createStructForObject(obj, p, excludeGraphics)
% Creates a structure from a given object.  This is used
% instead of calling struct(obj) directly, because some objects
% lie about their properties.  For example, calling
% properties(obj) is different than getting the metaclass
% information for the class and looking at the public
% properties in its PropertyList.  The inspector looks at the
% properties of the object, as if calling properties(obj).

arguments
    obj

    % Properties can be passed in, or if not will be determined by
    % calling properties on the object.
    p = properties(obj);

    excludeGraphics logical = false;
end

if isstruct(obj)
    s = obj;
    return;
end
s = struct;
limitingProps = {'Toolbar', 'CurrentPoint', 'TightInset', 'ContextMenu'};
p(contains(p, limitingProps)) = [];
for i = 1:length(p)
    propName = p{i};
    try
        if excludeGraphics && isa(obj.(propName), "handle") && isgraphics(obj.(propName))
            s.(propName) = [];
        elseif isprop(obj, propName + "_I")
            % Try to use the _I property, if it exists.  For
            % graphics objects, this prevents any internal object
            % from being created, which may be created if you access
            % the property directly.  Do in a try/catch because some
            % graphics objects have these _I properties as private,
            % and its quicker to do try/catch than to access the
            % property and check its access state.
            try
                s.(propName) = obj.(propName + "_I");
            catch
                s.(propName) = obj.(propName);
            end
        else
            s.(propName) = obj.(propName);
        end
    catch
        % Typically this won't fail, but it can sometimes with
        % dependent properties that become invalid (for
        % example, property d is determined by a+b, but b is a
        % matrix and b is a char array).  Set to empty in this
        % case.  Also skip if the propName is not valid.
        if isvarname(propName)
            s.(propName) = [];
        end
    end
end

% The purpose of this method is to be used for object comparison --
% but you can't compare tall objects.  If there are any tall
% properties, set them to empty [].
isTall = structfun(@istall, s);
if any(isTall)
    f = fieldnames(s);
    fs = f(isTall);
    for j = 1:length(fs)
        s.(fs{j}) = [];
    end
end
end
