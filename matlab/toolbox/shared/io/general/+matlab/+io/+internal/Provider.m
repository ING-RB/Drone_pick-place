classdef Provider < matlab.io.internal.FunctionInterface ...
                  & matlab.mixin.indexing.RedefinesDot ...
                  & matlab.mixin.CustomDisplay
%Provider   Implements a mechanism to transparently forward properties
%   from composed class instances.
%
%   Think: "Dependent properties, but automatically wired up."
%
%   === RATIONALE ===
%   Lets imagine that you want to implement a new class called "TimetableBuilder".
%   And you need all the properties from an existing "TableBuilder" object to also
%   be present in the "TimetableBuilder" object.
%
%     classdef TableBuilder
%         properties
%             VariableNames (1, :) string
%             VariableTypes (1, :) string
%         end
%     end
%
%     classdef TimetableBuilder
%         properties
%             VariableNames (1, :) string
%             VariableTypes (1, :) string
%             TimeVariableIndex (1, 1) uint64
%         end
%     end
%
%   How would you do this without duplicating code?
%
%   Currently in MATLAB, there are two main approaches:
%   - Inheritance: Make TimetableBuilder derive from TableBuilder.
%       Pros: All property/method visibility is automatically derived.
%       Cons: Save/load, isequaln, copy behavior can be surprising.
%             Cannot switch out superclasses at runtime if desired.
%   - Composition: Add TableBuilder as a private property on TimetableBuilder and
%                  add getters/setters for every sub-property on TableBuilder.
%       Pros: No mixup in storage state for save/load, isequaln, etc.
%             Behavior can be decided at run-time.
%       Cons: Adding new properties is a very tedious manual process. Does not auto-update new
%             properties when the internal object changes.
%
%   So the best of both worlds would be if we can:
%   - automatically pull properties from the inner object, inheritance-style
%   - keep the storage of the objects separate, like composition, so that save-load is easier
%   - allow runtime switching of properties and visibility for even more configurability.
%
%   That is what Provider does.
%
%   === EXAMPLE ===
%
%   Basically, to implement the above TimetableBuilder class, a user can do:
%
%     classdef TimetableBuilder < matlab.io.internal.Provider
%         properties (Provider)
%             TableBuilder
%         end
%         properties
%             TimeVariableIndex (1, 1) uint64
%         end
%     end
%
%   and that's it! All properties from TableBuilder are automatically
%   forwarded to TimetableBuilder (similar to dependent properties, but automatic).
%
%   But TableBuilder is still a separate object, so save-load, copy, etc can be implemented
%   in separate, independent ways for both TableBuilder and TimetableBuilder.

%   Copyright 2021 The MathWorks, Inc.

    methods (Hidden)
        function props = properties(obj)
            % The full list of properties on this class includes all the
            % Provider properties too.

            % Get the default list of properties on this object.
            props = builtin("properties", obj);

            % Augment the list of properties by getting the properties of all the
            % provider objects too.
            providers = matlab.io.internal.provider.listProviderProperties(obj);
            for index = 1:numel(providers)
                props = [props; properties(obj.(providers(index)))];
            end
        end
    end

    % Implement methods needed by RedefinesDot.
    methods (Access = protected)
        function varargout = dotReference(obj, indexingOperation)

            import matlab.io.internal.provider.hasPropertyNested

            [~, providerName] = hasPropertyNested(obj, indexingOperation(1).Name, "get");

            if ~ismissing(providerName)
                try
                    % Property is defined on a Provider property. Forward to that property.
                    [varargout{1:nargout}] = obj.(providerName).(indexingOperation);
                    return;
                catch ME
                    throwAsCaller(ME);
                end
            end

            % Property was not found on the class or any of its providers. Error out instead.
            throwAsCaller(makeUnknownPropertyError(indexingOperation(1).Name, class(obj)));
        end

        function obj = dotAssign(obj, indexingOperation, varargin)

            import matlab.io.internal.provider.hasPropertyNested

            [~, providerName] = hasPropertyNested(obj, indexingOperation(1).Name, "set");

            if ~ismissing(providerName)
                try
                    % Property is defined on a Provider property. Forward to that property.
                    [obj.(providerName).(indexingOperation)] = varargin{:};
                    return;
                catch ME
                    throwAsCaller(ME);
                end
            end

            % Property was not found on the class or any of its providers. Error out instead.
            throwAsCaller(makeUnknownPropertyError(indexingOperation(1).Name, class(obj)));
        end

        function n = dotListLength(obj, indexingOperation, indexingContext)

            import matlab.indexing.IndexingContext
            import matlab.io.internal.provider.hasPropertyNested

            if indexingContext == IndexingContext.Assignment
                [~, providerName] = hasPropertyNested(obj, indexingOperation(1).Name, "set");
            else
                % "Statement" and "Expression" contexts look like "get".
                [~, providerName] = hasPropertyNested(obj, indexingOperation(1).Name, "get");
            end

            if ~ismissing(providerName)
                try
                    % Property is defined on a Provider property. Forward to that property.
                    n = listLength(obj.(providerName), indexingOperation, indexingContext);
                    return;
                catch ME
                    throwAsCaller(ME);
                end
            end

            % Property was not found on the class or any of its providers. Error out instead.
            throwAsCaller(makeUnknownPropertyError(indexingOperation(1).Name, class(obj)));
        end
    end

    % Implement methods for CustomDisplay.
    % The main goal here is to display each Provider's properties in
    % "PropertyGroups".
    methods (Access = protected)
        function propgrps = getPropertyGroups(obj)
            propgrps = getPropertyGroups@matlab.mixin.CustomDisplay(obj);

            providers = matlab.io.internal.provider.listProviderProperties(obj);
            for index = 1:numel(providers)

                provider = obj.(providers(index));

                if isa(provider, "matlab.io.internal.Provider")
                    % Can just get the PropertyGroups display directly.
                    propgrp = getPropertyGroups(provider);
                else
                    % Manually construct the property group.
                    props = properties(provider);
                    propgrp = matlab.mixin.util.PropertyGroup();
                    propgrp.PropertyList = struct();
                    for propindex = 1:numel(props)
                        propgrp.PropertyList.(props{propindex}) = provider.(props{propindex});
                    end
                end

                propgrp(1).Title = "Properties provided by " + providers(index) + ":";

                propgrps = [propgrps; propgrp];
            end
        end
    end
end

function ME = makeUnknownPropertyError(propName, className)

    propName = convertCharsToStrings(propName);
    if ~isstring(propName)
        % If the input is not a field name, we need to throw a different
        % error:
        % "Dynamic structure reference must evaluate to a valid field name."
        ME = MException(message("MATLAB:mustBeFieldName"));
        return;
    end

    if ~isscalar(propName)
        % "Dynamic field or property name must be a string scalar or character vector."
        ME = MException(message("MATLAB:index:dotParenArgsMustBeStringScalarOrCharacterVector"));
        return;
    end

    if ismissing(propName)
        % "<missing> string element not supported."
        ME = MException(message("MATLAB:string:MissingNotSupported"));
        return;
    end

    % The property name has the right datatype and dimensions, but just
    % doesn't exist on the object.
    msgid = "MATLAB:noSuchMethodOrField";
    msg = message(msgid, propName, className);
    ME = MException(msg);
end