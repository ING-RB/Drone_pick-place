function tf = hasPropertyFlat(obj, name, mode, mc)
%hasPropertyFlat   Returns true if OBJ has property NAME accessible
%   through the specified set/get MODE.
%
%   MODE can be "set" or "get".
%
%   This method does NOT recurse into Provider properties. Use
%   hasPropertyNested() if that's what you're looking for.
%
%   Also provide a metaclass instance of OBJ to avoid
%   recomputation of the meta class.
%
%   See also: matlab.io.internal.Provider

%   Copyright 2021 The MathWorks, Inc.

    arguments
        obj % Any class
        name (1, 1) string {mustBeNonmissing}
        mode (1, 1) string
        mc   (1, 1) meta.class
    end

    import matlab.io.internal.provider.*

    tf = false;
    propmeta = mc.PropertyList;

    % Iterate through the metaclass of the input object and return
    % true if the object has the desired property.
    for i=1:numel(propmeta)
        prop = propmeta(i);
        if prop.Name == name && isAppropriateAccess(prop, mode)
            tf = true;
            return;
        end
    end
end
