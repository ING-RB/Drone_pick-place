classdef (Hidden) sensorInterface < matlab.System
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Constant)
        % SamplesPerRead Number of samples to be read in a single 'read'
        % operation. For code generation this cannot be changed.
        SamplesPerRead = 1;
        ReadMode = "latest"
        OutputFormat = "matrix"
        TimeFormat = "duration"
    end
    
    properties(SetAccess = protected, GetAccess = public)
        % SamplesRead Number of samples already read.
        SamplesRead = 0;
    end
    
    methods(Abstract, Access = protected)
        % Even though most of these methods are abstract in matlab.system,
        % here it is specifically given to show that these system object methods
        % are being used in this architecture
        data = stepImpl(obj);
        resetImpl(obj);
    end
    
    methods
        function obj = sensorInterface()
        end
    end
    
    methods(Abstract)
        data = read(obj);
        flush(obj);
    end
    
    methods(Access = protected)
        function obj = cloneImpl(obj)
            coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensor','clone')
        end
    end
end