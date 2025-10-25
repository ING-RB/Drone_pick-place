classdef (Sealed) WeakReference
    properties(WeakHandle, SetAccess = immutable)
        Handle (1, 1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder');
    end
    methods
        function obj = WeakReference(inputHandle)
            arguments
                % Default value allows for users to call WeakReference().
                inputHandle (1, 1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder')
            end
            obj.Handle = inputHandle;
        end
    end
end