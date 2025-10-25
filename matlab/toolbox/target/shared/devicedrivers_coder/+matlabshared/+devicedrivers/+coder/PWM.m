classdef PWM < handle
    %   PWM - This class generates driver function calls to access PWM
    %   peripheral on the target
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    %#codegen
    properties(Access = protected)
        MW_PWM_HANDLE
    end
    
    methods (Hidden)
        
        function obj = PWM(varargin)
            coder.allowpcode('plain');
        end
        
        function configurePWMPinInternal(obj, pin, initialFrequencyCast, initialDutyCycleCast)
            coder.cinclude('MW_PWM.h');
                obj.MW_PWM_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                if isnumeric(pin)
                    obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_Open', pin, ...
                        initialFrequencyCast, ...
                        initialDutyCycleCast);
                else
                    pinname = coder.opaque('uint32_T', pin);
                    obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_Open',pinname, ...
                        initialFrequencyCast, ...
                        initialDutyCycleCast);
                end
            
        end
        
        function startPWMInternal(obj, pin)
            % Start the genrating the PWM as per it is configured
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_Start',obj.MW_PWM_HANDLE);
            
        end
        
        function setPWMDutyCycleInternal(obj, pin, dutyCycle)
            % Set the duty cycle of PWM
            
            % Everywhere recovering MW_PWM_HANDLE from pin number, consider
            % character pin number also
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_SetDutyCycle',obj.MW_PWM_HANDLE, ...
                    double(dutyCycle));
        end
        
        function setPWMFrequencyInternal(obj, pin, frequencyInHz)
            % Set the frequency of PWM
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_SetFrequency',obj.MW_PWM_HANDLE, ...
                    double(frequencyInHz));
        end
        
        function disablePWMNotificationInternal(obj, pin)
            % Disable the notification on PWM channel
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_DisableNotification', obj.MW_PWM_HANDLE);
            
        end
        
        
        function enablePWMNotificationInternal(obj, pin, notifyVal)
            % Enable the notification on PWM channel
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_EnableNotification', obj.MW_PWM_HANDLE, notifyVal);
        end
        
        function pwmOutStatus = getPWMOutputStateInternal(obj, pin)
            % Read the output on PWM pin
            setPWMHandle(obj, pin);
            pwmOutStatus = coder.ceval('MW_PWM_GetOutputState',obj.MW_PWM_HANDLE);
            
        end
        
        function stopPWMInternal(obj, pin)
            % Stop the PWM
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_Stop',obj.MW_PWM_HANDLE);
        end
        
        function unconfigurePWMPinInternal(obj, pin)
            % Unconfigure the PWM pin
            setPWMHandle(obj, pin);
            coder.ceval('MW_PWM_Close',obj.MW_PWM_HANDLE);
        end
    end
    
    methods(Access = protected)
        function setPWMHandle(obj, pin)
            % Set the handle for the current pin to property MW_DIGITALIO_HANDLE.
            obj.MW_PWM_HANDLE = coder.opaque('MW_Handle_Type', 'HeaderFile','MW_SVD.h');
            if isnumeric(pin)
                obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_GetHandle',uint32(pin));
            else
                pinname = coder.opaque('uint32_T', pin);
                obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_GetHandle',pinname);
            end
        end
    end
end
