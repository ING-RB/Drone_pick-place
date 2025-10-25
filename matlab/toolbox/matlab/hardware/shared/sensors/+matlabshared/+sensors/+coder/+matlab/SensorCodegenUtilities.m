classdef (Hidden) SensorCodegenUtilities < handle
    % This class provides internal API to be used by sensor infrastructure
    % for code generation.

    % Copyright 2020-2021 The MathWorks, Inc.

    %#codegen

    methods(Abstract, Access = protected)
        % Implement the following methods in the hardware class
        time = getCurrentTimeImpl(obj);
    end

    methods
        function time = getCurrentTime(obj)
            time = getCurrentTimeImpl(obj);
        end

        function addExternalLibrary(obj)
            addExternalLibraryHook(obj);
        end
    end

    methods(Access = protected)
        function addExternalLibraryHook(~)
            % Target authors can override this to add external libraries.
            % Also, they can inherit from both this class and
            % coder.ExternalDependency to form a concrete hardware class
            % and implement all the abstract methods there.
        end
    end

    methods (Access = public,Hidden)
       delayFunctionForHardware(obj,factor)
    end
end