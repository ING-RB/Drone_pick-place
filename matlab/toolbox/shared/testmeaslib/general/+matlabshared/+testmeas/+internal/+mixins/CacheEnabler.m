classdef (Abstract) CacheEnabler < handle
    %CACHEENABLER mixin allows interfaces to be use the internal testmeas
    %object cacher.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant, Hidden, Abstract)
        % The unique tag that identifies a given object type.
        ObjectType (1, 1) string
    end

    properties (Hidden, SetAccess = immutable)
        % Signifies whether the object is cached by default when the
        % CacheEnabler constructor is invoked.
        %
        % true - cached by default.
        %
        % false - not cached by default. Invoke the "cacheResource" method
        % to cache.
        %
        % Default = true -> Cached by default
        CachedByDefault (1, 1) logical = true

        % Signifies whether the object is saved as a strong handle or a
        % weak handle.
        %
        % true - cached as weak-handle. Keeps an internal reference count.
        % Object is automatically cleared when last reference count dies.
        % Can be cleaned by calling "clear" on the last object handle.
        %
        % false - cached as a strong-handle. Object is not automatically
        % cleared upon removal of the last instance of the object. Cannot
        % be cleaned up using "clear". Have to call "delete" on the handle
        % to clean up this object.
        %
        % Default = true -> Cached as weak handle.
        CachedAsWeakHandle (1, 1) logical = true
    end

    %% Lifetime
    methods
        function obj = CacheEnabler(cacheByDefault, cacheAsWeakHandle)
            arguments
                cacheByDefault (1, 1) logical = true
                cacheAsWeakHandle (1, 1) logical = true
            end

            obj.CachedByDefault = cacheByDefault;
            obj.CachedAsWeakHandle = cacheAsWeakHandle;

            if obj.CachedByDefault
                cacheResource(obj);
            end
        end
    end

    %% API
    methods (Hidden)
        function cacheResource(obj)
            arguments
                obj (1, 1)
            end
            matlabshared.testmeas.internal.objectcacher.ObjectCacher.cache(obj, obj.CachedAsWeakHandle);
        end
    end
end
