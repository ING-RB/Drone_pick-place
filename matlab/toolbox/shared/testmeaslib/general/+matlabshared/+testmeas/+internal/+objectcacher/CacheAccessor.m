classdef CacheAccessor
    %CACHEACCESSOR allows access to the internal cached (strong or weak)
    %handles for the interfaces.

    %   Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function resource = accessCachedResource(type, action, val)
            % Get the list of all cached handles for a given "type" by
            % setting action = "get" or set the new list of cached handles
            % for the given "type" by setting action = "set".

            arguments
                type (1, 1) string {matlabshared.testmeas.internal.objectcacher.Cache.validateType(type)}
                action (1, 1) string {mustBeMember(action, ["get", "set"])}
                val = []
            end

            % Get the associated function handle to access the cache for
            % the given type.
            cacheFcnHandle = matlabshared.testmeas.internal.objectcacher.Cache.TypeAndCacheFcnDictionary(type);
            if action == "get"
                resource = cacheFcnHandle(action, []);

                % If there are any instances that have been deleted
                % (outside of the objectcacher), remove them from the
                % cached list using the clearInterfaceFcnHandle.
                clearInterfaceFcnHandle = matlabshared.testmeas.internal.objectcacher.Cache.TypeAndClearInterfaceFcnDictionary(type);
                resource = clearDeletedInstances(resource, cacheFcnHandle, clearInterfaceFcnHandle);
            else
                cacheFcnHandle("set", val);
            end

            %% NESTED FUNCTION
            function objectsToQuery = clearDeletedInstances(objectsToQuery, cacheFcnHandle, clearInterfaceFcnHandle)
                % If the hardware object instance gets deleted outside of
                % the ObjectCacher, remove the deleted handle from the list
                % of saved objects.

                invalidIndices = [];
                needsReEval = false;

                % Keep a list of indices of "objectsToQuery" that have
                % deleted or invalid handles. These will be removed from
                % the cache.
                for currIndex = 1 : length(objectsToQuery)
                    if checkIfObjectInvalid(objectsToQuery(currIndex))
                        invalidIndices(end+1) = currIndex; %#ok<AGROW>
                        needsReEval = true;
                    end
                end

                % Remove the indices pertaining to invalid handles from the
                % "objectsToQuery".
                objectsToQuery = clearInterfaceFcnHandle(objectsToQuery, invalidIndices);

                if isempty(objectsToQuery)
                    objectsToQuery = [];
                end

                if needsReEval
                    % Update the cache with the new list of only valid
                    % handles.
                    cacheFcnHandle("set", objectsToQuery);
                end

                %% NESTED FUNCTION
                function flag = checkIfObjectInvalid(object)
                    % Returns true if the object is an invalid handle,
                    % false for valid objects. This function handles both
                    % strong and weak handles.

                    % Check if object was "deleted". The below condition
                    % will apply for both strong as well as weak handles.
                    flag = false;
                    if isempty(object) || ~isvalid(object)
                        flag = true;
                        return
                    end

                    % Only for weak handles, we need to clean up the weak
                    % handles if the internal object was "cleared"
                    isWeakHandle = isa(object, "matlab.internal.WeakHandle");

                    if isWeakHandle
                        flag = isDestroyed(object);
                    end
                end
            end
        end
    end
end
