function providerNames = listProviderProperties(obj, mode, mc)
%listProviderProperties   Returns a string column vector listing all the Provider
%   properties on the input class OBJ.
%
%   Optionally supply a metaclass object MC as input to avoid
%   recomputation of the metaclass object for OBJ.
%
%   See also: matlab.io.internal.Provider

%   Copyright 2021 The MathWorks, Inc.

    arguments
        obj % Any class
        mode (1, 1) string = "get"
        mc   (1, 1) meta.class = metaclass(obj);
    end

    import matlab.io.internal.provider.*

    providerNames = string.empty(0, 1);

    if ~isa(obj, "matlab.io.internal.FunctionInterface")
        % Cannot have Provider properties. Just return early.
        return;
    end

    propList = mc.PropertyList;

    for index = 1:numel(propList)
        propMeta = propList(index);

        % Only list public/hidden providers.
        if propMeta.Provider && isAppropriateAccess(propMeta, mode)
            providerNames(end+1) = string(propMeta.Name);
        end
    end
end
