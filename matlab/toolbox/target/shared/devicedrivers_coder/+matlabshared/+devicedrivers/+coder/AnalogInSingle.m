classdef AnalogInSingle < handle
    %Codegen redirector class for AnalogInSingle(device drivers)

    % Copyright 2019-2024 The MathWorks, Inc.

    %#codegen
    properties (Access = public)
        MW_ANALOGIN_HANDLE;
    end

    methods
        function obj = AnalogInSingle(varargin)
            coder.allowpcode('plain');
        end
        
        function configureAnalogInSingleInternal(obj, pin)
            coder.cinclude('MW_AnalogIn.h');
            obj.MW_ANALOGIN_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
            if isnumeric(pin)
                obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogInSingle_Open', uint32(pin));
            else
                pinname = coder.opaque('uint32_T', pin);
                obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogInSingle_Open', pinname);
            end
        end

        function unconfigureAnalogInSingleInternal(obj, pin)
            % For MATLAB codegen the MW_ANALOGIN_HANDLE property will be
            % overwritten if multiple analog modules are used. To close a
            % particlaur analog module first the correct handle should be
            % picked up from the current analog pin and then the module
            % should be closed by reseting the corresponding pin handle.
            setAnalogInHandle(obj, pin);
            coder.ceval('MW_AnalogIn_Close', obj.MW_ANALOGIN_HANDLE);
        end

        function mw_analogin_result_out = readResultAnalogInSingleInternal(obj, pin, dataType)
            % Initialize data output
            setAnalogInHandle(obj, pin);
            coder.cinclude('MW_AnalogIn.h'); % fix for g3413447 - Enums from datatype_id are missed in S function build 
            [mw_analogin_result_out,datatype_id] = coder.const(@matlabshared.devicedrivers.coder.AnalogInSingle.getAnalogInResultDataType,dataType);
            datatype_id = coder.opaque('MW_AnalogIn_ResultDataType_Type',datatype_id);
            coder.ceval('MW_AnalogInSingle_ReadResult', obj.MW_ANALOGIN_HANDLE, coder.wref(mw_analogin_result_out), datatype_id);
        end

        function setTriggerSourceAnalogInInternal(obj, pin, triggerSource, triggerType)
            setAnalogInHandle(obj, pin);
            % Evaluate Trigger source type
            triggerValue = coder.const(@matlabshared.devicedrivers.coder.AnalogInSingle.getAnalogInTriggerSourceType,triggerSource);
            triggerValue = coder.opaque('MW_AnalogIn_TriggerSource_Type', triggerValue);
            % Generate code to set trigger source
            coder.ceval('MW_AnalogIn_SetTriggerSource', obj.MW_ANALOGIN_HANDLE, triggerValue, triggerType);
        end

        function enableNotificationAnalogInInternal(obj, pin)
            % Enable conversion complete notification
            setAnalogInHandle(obj, pin);
            coder.ceval('MW_AnalogIn_EnableNotification', obj.MW_ANALOGIN_HANDLE);
        end

        function disableNotificationAnalogInInternal(obj, pin)
            % Disable notification for analog input pin.
            setAnalogInHandle(obj, pin);
            coder.ceval('MW_AnalogIn_DisableNotification', obj.MW_ANALOGIN_HANDLE);
        end

        function status = getStatusAnalogInInternal(obj, pin)
            setAnalogInHandle(obj, pin);
            status = coder.ceval('MW_AnalogIn_GetStatus', obj.MW_ANALOGIN_HANDLE);
        end

        function startAnalogInConversionInternal(obj, pin)
            setAnalogInHandle(obj, pin);
            coder.ceval('MW_AnalogIn_Start', obj.MW_ANALOGIN_HANDLE);
        end

        function stopAnalogInConversionInternal(obj, pin)
            setAnalogInHandle(obj, pin);
            coder.ceval('MW_AnalogIn_Stop', obj.MW_ANALOGIN_HANDLE);
        end
    end

    methods(Access = protected)
        function setAnalogInHandle(obj, pin)
            obj.MW_ANALOGIN_HANDLE = coder.opaque('MW_Handle_Type', 'HeaderFile','MW_SVD.h');
            if isnumeric(pin)
                obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogIn_GetHandle',uint32(pin));
            else
                pinname = coder.opaque('uint32_T', pin);
                obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogIn_GetHandle',pinname);
            end
        end
    end

    methods (Static)
        function TriggerValue = getAnalogInTriggerSourceType(TriggerSource)
            coder.inline('always');
            switch TriggerSource
                case 'Software'
                    TriggerValue = 'MW_ANALOGIN_SOFTWARE_TRIGGER';
                case 'External trigger'
                    TriggerValue = 'MW_ANALOGIN_EXTERNAL_TRIGGER';
                otherwise
                    TriggerValue = 'MW_ANALOGIN_SOFTWARE_TRIGGER';
            end
        end

        function [mw_analogin_result_out,datatype_id] = getAnalogInResultDataType(type)
            coder.inline('always');
            switch type
                case 'int8'
                    mw_analogin_result_out = int8(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_INT8';
                case 'uint8'
                    mw_analogin_result_out = uint8(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_UINT8';
                case 'int16'
                    mw_analogin_result_out = int16(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_INT16';
                case 'uint16'
                    mw_analogin_result_out = uint16(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_UINT16';
                case 'int32'
                    mw_analogin_result_out = int32(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_INT32';
                case 'uint32'
                    mw_analogin_result_out = uint32(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_UINT32';
                case 'single'
                    mw_analogin_result_out = single(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_FLOAT';
                case 'double'
                    mw_analogin_result_out = double(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_DOUBLE';
                otherwise
                    mw_analogin_result_out = int8(zeros(1,1));
                    datatype_id = 'MW_ANALOGIN_INT8';
            end
        end
    end
end