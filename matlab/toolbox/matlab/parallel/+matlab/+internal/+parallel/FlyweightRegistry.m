%FLYWEIGHTREGISTRY Class that enables other classes to act as a
%flyweight, with one object per ID. If you deserialize an object of the same ID,
% this will force that object to be the exact same handle.
%
% Example:
% c = ExampleClass(42);
% c2 = distcompdeserialize(distcompserialize(c))
% c == c2
%
% classdef ExampleClass < handle
%
%     properties (Transient)
%         Data
%     end
%
%     properties (Transient, Constant, Access = private)
%         % The registry for this class.
%         Registry = matlab.internal.parallel.FlyweightRegistry()
%     end
%
%     properties (SetAccess = immutable)
%         UUID
%     end
%
%     methods
%         function obj = ExampleClass(data)
%
%             obj.Data = data;
%
%             % Register class in constructor
%             obj.UUID = ExampleClass.Registry.add(obj);
%         end
%
%
%         function loadobj(S)
%             obj = ExampleClass.Registry.getIfExists(s.UUID);
%             if ~isempty(obj)
%                return
%             else
%                 % Need to call constructor instead.
%             end
%         end
%     end
% end

% Copyright 2023-2024 The MathWorks, Inc.

classdef (Sealed) FlyweightRegistry < handle

    properties (Constant, Access = private)
        % If this registry is accessed more than this number of times
        % without triggering a cleanup of stale keys we will force one to
        % avoid stale keys which are never accessed drooling forever.
        MaxAccessedBeforeForcedCleanup = 1000;
    end

    properties (Access = private)
        Map = dictionary(string.empty(), matlab.lang.WeakReference.empty())

        % Counter to track reaching MaxAccessedBeforeForcedCleanup limit.
        AccessesSinceLastCleanup = 0;
    end

    methods
        function id = add(obj, myObj, id)
            % Add a handle object to the registry, with an optional UUID.
            % Returns a UUID for the object.
            arguments
                obj (1,1) matlab.internal.parallel.FlyweightRegistry
                myObj (1,1) {mustBeHandleObject}
                id (1,1) string = matlab.lang.internal.uuid()
            end
            assert(~isKey(obj,id));
            obj.Map(id) = matlab.lang.WeakReference(myObj);
        end

        function objFromWeak = getIfExists(obj, id)
            % Retrieve an object from the registry given a UUID. If the
            % object does not exist, returns empty.
            arguments
                obj (1,1) matlab.internal.parallel.FlyweightRegistry
                id (1,1) string
            end
            % Returns empty if object does not exist.
            if ~obj.isKey(id)
                objFromWeak = [];
            else
                weakReference = obj.Map(id);
                objFromWeak = weakReference.Handle;
            end
        end

        function objectsFromWeak = getAll(obj)
            % Returns a cell array of all objects held in this registry.
            num = obj.numEntries();
            objectsFromWeak = cell(num, 1);
            weakReferences = values(obj.Map);
            for i = 1:num
                objectsFromWeak{i} = weakReferences(i).Handle;
            end
        end
    end

    methods (Access = private)
        function tf = isKey(obj, id)
            tf = isKey(obj.Map, id);
            if tf
                % Check handle is still valid
                weakReference = obj.Map(id);
                if ~isvalid(weakReference.Handle)
                    % Remove stale entry and any others
                    obj.cleanupStaleEntries();
                    tf = false;
                end
            end
            obj.AccessesSinceLastCleanup = obj.AccessesSinceLastCleanup + 1;
            if obj.AccessesSinceLastCleanup > obj.MaxAccessedBeforeForcedCleanup
                obj.cleanupStaleEntries();
            end
        end

        function cleanupStaleEntries(obj)
            % Find all destroyed references, and remove them from the map.
            if numEntries(obj.Map) > 0
                map = obj.Map;
                uuids = keys(map);
                weakReferences = values(map);

                isStale = arrayfun(@(x) ~isvalid(x.Handle), weakReferences);
                staleUuids = uuids(isStale);
                map(staleUuids) = [];

                obj.Map = map;
            end
            obj.AccessesSinceLastCleanup = 0;
        end
    end

    methods (Hidden)
        function count = numEntries(obj)
            % For testing purposes, expose total number of flyweight ids in
            % existence.
            obj.cleanupStaleEntries();
            count = obj.Map.numEntries();
        end
    end
end

function mustBeHandleObject(obj)
if ~isa(obj,"handle")
    error(message("MATLAB:class:MustBeHandle"));
end
end
