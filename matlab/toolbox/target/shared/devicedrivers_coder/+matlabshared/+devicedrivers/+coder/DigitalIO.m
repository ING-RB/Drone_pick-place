classdef DigitalIO < handle
    
    % Copyright 2019 The MathWorks, Inc.
    
    %#codegen
    
    properties(Access = protected)
        MW_DIGITALIO_HANDLE
    end
    
    methods(Access = public)
        function obj = DigitalIO(varargin)
            % Support code generation from the p-coded file
            coder.allowpcode('plain');
        end
    end
    
    methods(Hidden)
        function configureDigitalPinInternal(obj, pin, mode)
            coder.cinclude('MW_digitalIO.h');
            obj.MW_DIGITALIO_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
            if isnumeric(pin)
                obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_digitalIO_open',pin,mode);
            else
                pinname = coder.opaque('uint32_T', pin);
                obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_digitalIO_open',pinname,mode);
            end
        end
        
        function writeDigitalPinInternal(obj, pin, value)
            % Set the handle for the current pin to property MW_DIGITALIO_HANDLE.
            setDigitalIOHandle(obj, pin);
            coder.ceval('MW_digitalIO_write',obj.MW_DIGITALIO_HANDLE,logical(value));
        end
        
        function readValue = readDigitalPinInternal(obj, pin)
            % Set the handle for the current pin to property MW_DIGITALIO_HANDLE.
            setDigitalIOHandle(obj, pin);
            readValue = coder.nullcopy(false);
            readValue = coder.ceval('MW_digitalIO_read',obj.MW_DIGITALIO_HANDLE);
        end
        
        function unconfigureDigitalPinInternal(obj, pin)
            % Set the handle for the current pin to property MW_DIGITALIO_HANDLE.
            setDigitalIOHandle(obj, pin);
            coder.ceval('MW_digitalIO_close',obj.MW_DIGITALIO_HANDLE);
        end
    end
    
    methods(Access = protected)
        function setDigitalIOHandle(obj, pin)
            % Set the handle for the current pin to property MW_DIGITALIO_HANDLE.
            obj.MW_DIGITALIO_HANDLE = coder.opaque('MW_Handle_Type', 'HeaderFile','MW_SVD.h');
            if isnumeric(pin)
                obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_DigitalIO_GetHandle',uint32(pin));
            else
                pinname = coder.opaque('uint32_T', pin);
                obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_DigitalIO_GetHandle',pinname);
            end
        end
    end
end

%% Local functions
%[EOF]