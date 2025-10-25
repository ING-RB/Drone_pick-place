function [tf, providerName] = hasPropertyNested(obj, name, mode)
%hasPropertyNested   Returns true if OBJ has property NAME accessible
%   through the specified set/get MODE.
%
%   MODE can be "set" or "get".
%
%   This method recurses into Provider properties. If a provider
%   provides NAME then providerName is set to a scalar string, else
%   providerName is set to string(missing).
%
%   See also: matlab.io.internal.Provider

%   Copyright 2021 The MathWorks, Inc.

    arguments
        obj % Any class
        name % Can be a non-string when doing dot-reference with an integer,
             % like >> x.(1)
        mode (1, 1) string
    end

    import matlab.io.internal.provider.*;

    tf = false;
    providerName = string(missing);

    % Exit early if dot reference is done with a non-string argument.
    name = convertCharsToStrings(name);
    if ~isstring(name)
        return;
    end

    if ~isscalar(name) || ismissing(name)
        % <missing> string element not supported.
        % non-scalars are not supported either.
        return;
    end

    % All of this uses meta class. Just call it once here.
    % TODO: find a way to cache this.
    mc = metaclass(obj);

    % Check if this property exists on this object itself.
    if hasPropertyFlat(obj, name, mode, mc)
        tf = true;
        return;
    end

    % List all the provider properties.
    providerNames = listProviderProperties(obj, mode, mc);

    % Iterate through the provider properties and return if one of them
    % define a property with name NAME in this mode.
    for index = 1:numel(providerNames)
        propertyName = providerNames(index);

        if hasPropertyNested(obj.(propertyName), name, mode)
            providerName = propertyName;
            tf = true;
            return;
        end
    end
end

