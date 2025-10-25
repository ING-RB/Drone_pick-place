classdef SCI < handle
    % This class provides internal APIs to access serial peripheral during
    % code generation. It is accessed by HWSDK and Simulink block mask
    % provided by device driver
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Access = protected)
        MW_SCIHANDLE
    end
    
    methods(Access = public)
        function obj = SCI()
            coder.allowpcode('plain');
            obj.MW_SCIHANDLE = coder.opaque('MW_Handle_Type','NULL','HeaderFile','MW_SVD.h');
        end
        
        function openSCIBusInternal(obj, module, rxPin, txPin, isString)
            if nargin < 5
                isString = false;
            end
            % Create variable for Rx-pin
            if isempty(rxPin)
                RxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else                
                if isnumeric(rxPin)
                    RxPinLoc = uint32(rxPin);
                else
                    RxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                end
            end
            % create variable for Tx-pin
            if isempty(txPin)
                TxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(txPin)
                    TxPinLoc = uint32(txPin);
                else
                    TxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                end
            end
            coder.cinclude('MW_SCI.h');
            obj.MW_SCIHANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
            % Intialise SCI
            if isnumeric(module)
                % SCIModule is a numeric value and is represented as
                % obj.SCIModule = 1
                isString = false;
                SCIModuleLoc = coder.opaque('uint32_T');
                SCIModuleLoc = coder.ceval('(uint32_T)', module);
                obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', coder.rref(SCIModuleLoc), isString, RxPinLoc, TxPinLoc);
            else
                % obj.SCIModule is represented as non numeric.
                % This can be in 2 different ways within a system obj:
                % obj.SCIModule = '1' or obj.SCIModuel = '/dev/serial1'
                % Use getSCIModuleNameIsString() API to check how
                % SCIModules are represented within the target.
                
                
                if ~isString
                    % SCIModule is a numeric value for the target but
                    % in system obj it is represented as a char :
                    % obj.SCIModule = '1'
                    SCIModuleLoc = coder.opaque('uint32_T', module);
                    obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', coder.rref(SCIModuleLoc), isString, RxPinLoc, TxPinLoc);
                else
                    % SCIModule is not a numeric value :
                    % obj.SCIModule = '/dev/serial1'
                    % In C++ codegen, SCIModule will be const char[]
                    % and cannot be casted to void* directly
                    SCIModuleLoc = [module char(0)];
                    SCIModuleVoidPtr = coder.opaque('void*');
                    SCIModuleVoidPtr = coder.ceval('(void*)',SCIModuleLoc);
                    obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', SCIModuleVoidPtr, isString, RxPinLoc, TxPinLoc);
                end
            end
        end
        
        function status = setSCIBaudrateInternal(obj, module, baudrate)
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            % Init Bus speed            
            status = coder.nullcopy(uint8(0));
            status = coder.ceval('MW_SCI_SetBaudrate', obj.MW_SCIHANDLE, baudrate);
        end
        
        function status = configureSCIHardwareFlowControlInternal(obj, module, flowControlType, rtsPin, ctsPin)
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            if isempty(rtsPin)
                rtsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(rtsPin)
                    rtsPinLoc = uint32(rtsPin);
                else
                    rtsPinLoc = coder.opaque('uint32_T', rtsPin);
                end
            end
            if isempty(ctsPin)
                ctsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(ctsPin)
                    ctsPinLoc = uint32(ctsPin);
                else
                    ctsPinLoc = coder.opaque('uint32_T', ctsPin);
                end
            end
            % HardwareFlowControlValue value
            HardwareFlowControlValue = coder.const(@obj.getSCIHardwareFlowControlTypeValue, flowControlType);
            HardwareFlowControlValue = coder.opaque('MW_SCI_HardwareFlowControl_Type', HardwareFlowControlValue);
            status = coder.nullcopy(uint8(0));
            status = coder.ceval('MW_SCI_ConfigureHardwareFlowControl', obj.MW_SCIHANDLE, HardwareFlowControlValue, rtsPinLoc, ctsPinLoc);
        end
        
        function status = setSCIFrameFormatInternal(obj, module, dataBitslength, parity, stopBits)
            % Init SCI device
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            % StopBits value
            StopBitsValue = coder.const(@obj.getSCIStopBitsTypeValue, stopBits);
            StopBitsValue = coder.opaque('MW_SCI_StopBits_Type', StopBitsValue);
            % Parity value
            ParityValue = coder.const(@obj.getSCIParityTypeValue, parity);
            ParityValue = coder.opaque('MW_SCI_Parity_Type', ParityValue);
            % Intialise SCI
            status = coder.nullcopy(uint8(0));
            status = coder.ceval('MW_SCI_SetFrameFormat', obj.MW_SCIHANDLE,...
                uint8(dataBitslength), ParityValue, StopBitsValue);
        end
        
        function [readValue, status] = sciReceiveBytesInternal(obj, module, numBytes)
            coder.cinclude('MW_SCI.h');
            readValue = coder.nullcopy(cast(zeros(numBytes, 1), 'uint8'));
            setSCIHandle(obj, module);
            % Receive the data from SCI
            status = coder.nullcopy(uint8(0));
            
            status = coder.ceval('MW_SCI_Receive', obj.MW_SCIHANDLE,...
                coder.wref(readValue), uint32(numBytes));
        end
        
        function status = sciTransmitBytesInternal(obj, module, data, dataLength)
            status = coder.nullcopy(uint8(0));
            setSCIHandle(obj, module);
            coder.cinclude('MW_SCI.h');
            status = coder.ceval('MW_SCI_Transmit',obj.MW_SCIHANDLE,...
                coder.rref(data),uint32(dataLength));
        end
        
        function output = getSCIStatusInternal(obj, module)
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            output = coder.ceval('MW_SCI_GetStatus', obj.MW_SCIHANDLE);
        end
        
        function sciSendBreakInternal(obj, module)
            % Send break command
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            coder.ceval('MW_SCI_SendBreak', obj.MW_SCIHANDLE);
        end
        
        function sciCloseInternal(obj, module)
            % Release SCI module
            coder.cinclude('MW_SCI.h');
            setSCIHandle(obj, module);
            coder.ceval('MW_SCI_Close', obj.MW_SCIHANDLE);
        end
    end
    
    methods(Access = protected)
        function setSCIHandle(~, ~)
            % set MW_SCIHANDLE property here based on the SCI module number
        end
    end
    
    
    methods (Access = protected, Static)
        function StopBitsValue = getSCIStopBitsTypeValue(StopBitsStr)
            % Get the enum values for stop bit
            coder.inline('always');
            switch StopBitsStr
                case '0.5'
                    StopBitsValue = 'MW_SCI_STOPBITS_0_5';
                case '1'
                    StopBitsValue = 'MW_SCI_STOPBITS_1';
                case '1.5'
                    StopBitsValue = 'MW_SCI_STOPBITS_1_5';
                case '2'
                    StopBitsValue = 'MW_SCI_STOPBITS_2';
                otherwise
                    StopBitsValue = 'MW_SCI_STOPBITS_1';
            end
        end
        
        function ParityValue = getSCIParityTypeValue(ParityStr)
            % Get the enum values for parity bit
            coder.inline('always');
            switch ParityStr
                case 'None'
                    ParityValue = 'MW_SCI_PARITY_NONE';
                case 'Even'
                    ParityValue = 'MW_SCI_PARITY_EVEN';
                case 'Odd'
                    ParityValue = 'MW_SCI_PARITY_ODD';
                otherwise
                    ParityValue = 'MW_SCI_PARITY_NONE';
            end
        end
        
        function HardwareFlowControlValue = getSCIHardwareFlowControlTypeValue(HardwareFlowControlStr)
            % Get the enum values for flow control
            coder.inline('always');
            switch HardwareFlowControlStr
                case {false,'None'}
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_NONE';
                case {true,'RTS/CTS'}
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_RTS_CTS';
                otherwise
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_NONE';
            end
        end
    end
end