classdef (StrictDefaults)CANFD < matlab.System
    % Interfaces to access CAN bus
    
    %#codegen
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Hidden)
        Hw = [];
    end
    
    properties (Abstract,Nontunable)
        %CANModule CAN Module
        CANModule;
    end
    
    properties (Access = protected)
        MW_CAN_HANDLE;
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = CANFD(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    %% CAN formal functions
    methods
        % Initialize the CAN device
        function open(obj)
            if coder.target('RtwForRapid') || coder.target('RtwForSfun')
                %
            elseif coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                obj.MW_CAN_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                obj.MW_CAN_HANDLE = coder.ceval('MW_CAN_Open', uint32(obj.CANModule));
            end
        end
        
        % Transmit the data over CAN
        function varargout = write(obj, TxData, Id, DataLength, Type, Format, CANMsgType, isBRSEnable)
            Status = coder.nullcopy(uint8(0));
            In = cast(TxData,'uint8');
            if coder.target('RtwForRapid') || coder.target('RtwForSfun')
                %
            elseif coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                Status = coder.ceval('MW_CANFD_TransmitMessage',obj.MW_CAN_HANDLE,uint32(Id),coder.rref(In),uint8(DataLength), uint8(Type), uint8(Format),uint8(CANMsgType), uint8(isBRSEnable));
                varargout{1} = Status;
            end
        end
        
        % Receive the data over CAN
        function [receivedFrame,status] = read(obj,rxIndex)
            status = coder.nullcopy(uint8(0));
            receivedFrame = struct;
            coder.cstructname(receivedFrame, 'MW_CANFD_MSG_T','extern', 'HeaderFile', 'MW_CAN.h');
            receivedFrame.ID = coder.nullcopy(uint32(0));
            receivedFrame.Extended = coder.nullcopy(uint8(0));
            receivedFrame.ProtocolMode = coder.nullcopy(uint8(0));
            receivedFrame.BRS = coder.nullcopy(uint8(0));
            receivedFrame.Length = coder.nullcopy(uint8(0)); 
            receivedFrame.Remote = coder.nullcopy(uint8(0));
            receivedFrame.DLC = coder.nullcopy(uint8(0));
            receivedFrame.Data = coder.nullcopy(uint8(zeros(1,64)));
            if coder.target('RtwForRapid') || coder.target('RtwForSfun')
                %
            elseif coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                status = coder.ceval('MW_CANFD_ReceiveMessages',obj.MW_CAN_HANDLE, coder.wref(receivedFrame), rxIndex);
            end         
        end
        
        % Release the CAN module
        function close(obj)
            if coder.target('RtwForRapid') || coder.target('RtwForSfun')
                %
            elseif coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                coder.ceval('MW_CAN_Close',obj.MW_CAN_HANDLE);
            else
                % Place simulation setup code here
            end
        end
        
    end
    
    % System object methods
    methods (Access = protected)
        function varargout = stepImpl(~,varargin)
            varargout{1} = 0;
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl 
            CANModuleProp = matlab.system.display.internal.Property('CANModule', 'Description', 'svd:svd:CANModulePrompt');           
            PropertyListOut = {CANModuleProp};
            
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end