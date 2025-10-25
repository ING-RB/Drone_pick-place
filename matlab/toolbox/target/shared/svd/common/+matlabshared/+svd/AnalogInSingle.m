classdef (StrictDefaults)AnalogInSingle < matlab.System
    %ADCDEV ADC device base class
    
    % Copyright 2015-2021 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Hidden)
        Hw = [];
    end
    
    properties (Hidden,Nontunable)
        
     %handle to deploy and connect to IO server           
     DeployAndConnectHandle     
     %analogioClient
     analogInClient     
     %numeric pin for IO
     PinInternalIO 
     %variable to store Connected IO status
     IsIOEnable  = false ;  
    end
    % Can come from Hw object
    properties (Abstract,Nontunable)
        % Pin Pin
        Pin
    end
    
    properties (Nontunable)
        % ReadResultsOnly Read results only
        ReadResultsOnly (1, 1) logical = false;
    
        % ConversionTriggerSource Trigger A/D conversion
        ConversionTriggerSource = 'Software';
        % ExternalTriggerSource External trigger source
        ExternalTriggerType = uint32(0);
        % OutputDataType Output data type
        OutputDataType = 'double';
    
        % EnableConversionCompleteNotify Enable conversion complete notification
        EnableConversionCompleteNotify (1, 1) logical = false
        % EnableOuputStatus Output A/D conversion status
        EnableOuputStatus (1, 1) logical = false;
    end
    
    % Drop down list
    properties (Constant, Hidden)
        ConversionTriggerSourceSet = matlab.system.StringSet({'Software','External trigger'});
        OutputDataTypeSet = matlab.system.StringSet({...
            'int8',...
            'uint8',...
            'int16',...
            'uint16',...
            'int32',...
            'uint32',...
            'single',...
            'double'});
    end

    properties (Access = protected)
        MW_ANALOGIN_HANDLE;
    end
    
    % Property set/get methods
    methods
        function set.ExternalTriggerType(obj, value)
            if isempty(coder.target)
                validateattributes(value, {'numeric', 'embedded.fi'}, ...
                    {'scalar','integer','nonnegative','finite','nonnan','nonempty'}, ...
                    '', 'ExternalTriggerSource');
            end
            % Assign value
            obj.ExternalTriggerType = uint32(value);
        end
    end
    
    % Functional methods
    methods
        % Constructor
        function obj = AnalogInSingle(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function open(obj)
            if coder.target('Rtw')
                % Init PWM
                coder.cinclude('MW_AnalogIn.h');
                obj.MW_ANALOGIN_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                if isnumeric(obj.Pin)
                    obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogInSingle_Open', obj.Pin);
                else
                    pinname = coder.opaque('uint32_T', obj.Pin);
                    obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogInSingle_Open', pinname);
                end
            else
                % Place simulation setup code here
                obj.MW_ANALOGIN_HANDLE = coder.nullcopy(0);
                if isempty(obj.Pin)
                    error('svd:svd:EmptyPin', ...
                        ['The property Pin is not defined. You must set Pin ',...
                        'to a valid value.'])
                end
                %simulation setup code
                if coder.target('MATLAB')
                    %simulink IO code
                    obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                    if obj.IsIOEnable
                        %handle to deploy and connect to IO server                       
                        obj.DeployAndConnectHandle=matlabshared.ioclient.DeployAndConnectHandle;
                        %get a connected IOclient object
                        obj.DeployAndConnectHandle.getConnectedIOClient();

                        obj.analogInClient = matlabshared.ioclient.peripherals.AnalogInput;
                        %get the hardware name
                        hardwareName=lower(strrep(obj.DeployAndConnectHandle.BoardName,' ','')); 
                        
                        if(isnumeric(obj.Pin))
                            obj.PinInternalIO =uint32(obj.Pin);
                        else
                            %check whether Pin is not a string of numeric value.
                            if(isempty(str2num(obj.Pin)))
                                %list of Psuedo pin values available
                                [~,enumPinValues]=enumeration(['codertarget.simulinkIO.',hardwareName,'.pinInterface']);
                                %validate the Psuedo Pin
                                if(any(strcmp(enumPinValues,obj.Pin)))
                                    %convert to numeric Pin value
                                    obj.PinInternalIO  = uint32(codertarget.simulinkIO.(hardwareName).pinInterface.(obj.Pin));
                                else
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'Analog Input')));
                                end                         
                            else
                                validateattributes(str2double(obj.Pin),{'numeric'},{'nonnegative','integer','scalar','real'},'','Analog Pin');
                                try
                                    codertarget.simulinkIO.(hardwareName).pinInterface(str2double(obj.Pin));
                                catch
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'Analog Input')));
                                end
                                obj.PinInternalIO =uint32(str2double(obj.Pin));                  
                            end
                        end
                        
                        try
                            status=configureAnalogInSingleInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                        catch
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedReconnect',(obj.Pin),'Analog Input'))); 
                        end
                        
                        if(status)
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedPinConflict',(obj.Pin),'Analog Input')));                              
                        end
                        
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function setTriggerSource(obj, ConversionTriggerSource, TriggerType)
            if nargin > 1
                narginchk(3,3);
                
                obj.ConversionTriggerSource = ConversionTriggerSource;
                obj.ExternalTriggerType = TriggerType;
            else
                narginchk(1,1);
            end
            
            if coder.target('Rtw')
                % Evaluate Trigger source type
                trigger_val = coder.const(@obj.getAnalogInTriggerSourceType, obj.ConversionTriggerSource);
                trigger_val = coder.opaque('MW_AnalogIn_TriggerSource_Type', trigger_val);
                % Generate code to set trigger source
                coder.ceval('MW_AnalogIn_SetTriggerSource', obj.MW_ANALOGIN_HANDLE, trigger_val, obj.ExternalTriggerType);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        if isequal(obj.ConversionTriggerSource, 'Software')
                            setTriggerSourceAnalogInInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO, 'Software', uint32(0));%triggerValue is not significant for SoftwareTrigger. Hence assigning 0.
                        else
                           %Not Supported in Simulink IO
                           throwAsCaller(MException(message('svd:svd:ExtTriggerNotSupportedIO')));
                        end
                    else
                        %do nothing
                    end
                end            
            end
        end
        
        function setNotificationType(obj, EnableConversionCompleteNotify)
            narginchk(1,2);
            if nargin > 1
                obj.EnableConversionCompleteNotify = EnableConversionCompleteNotify;
            end
            
            if obj.EnableConversionCompleteNotify
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_EnableNotification', obj.MW_ANALOGIN_HANDLE);
                else
                    if coder.target('MATLAB')
                        if obj.IsIOEnable
                            %Not Supported in Simulink IO
                            throwAsCaller(MException(message('svd:svd:EnableNotificationADCNotSupportedIO')));                           
                        else
                            %do nothing
                        end
                    end
                end
            end
        end
        
        function resetNotificationType(obj)
            if obj.EnableConversionCompleteNotify
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_DisableNotification', obj.MW_ANALOGIN_HANDLE);
                else
                    if coder.target('MATLAB')
                        if obj.IsIOEnable
                            %Not Supported in Simulink IO
                            throwAsCaller(MException(message('svd:svd:DisableNotificationADCNotSupportedIO'))); 
                        else
                            %do nothing
                        end
                    end
                end
            end
        end
        
        function AnalogInStatus = getAnalogInStatus(obj)
            AnalogInStatus = uint8(0);
            
            if coder.target('Rtw')
                AnalogInStatus = coder.ceval('MW_AnalogIn_GetStatus', obj.MW_ANALOGIN_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        AnalogInStatus=getStatusAnalogInInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function mw_analogin_result_out = readAnalogInResult(obj)
            % Initialize data output
            switch obj.OutputDataType
                case 'int8'
                    mw_analogin_result_out = int8(zeros(1,1));
                    datatype_id = uint8(0);
                case 'uint8'
                    mw_analogin_result_out = uint8(zeros(1,1));
                    datatype_id = uint8(1);
                case 'int16'
                    mw_analogin_result_out = int16(zeros(1,1));
                    datatype_id = uint8(2);
                case 'uint16'
                    mw_analogin_result_out = uint16(zeros(1,1));
                    datatype_id = uint8(3);
                case 'int32'
                    mw_analogin_result_out = int32(zeros(1,1));
                    datatype_id = uint8(4);
                case 'uint32'
                    mw_analogin_result_out = uint32(zeros(1,1));
                    datatype_id = uint8(5);
                case 'single'
                    mw_analogin_result_out = single(zeros(1,1));
                    datatype_id = uint8(6);
                case 'double'
                    mw_analogin_result_out = double(zeros(1,1));
                    datatype_id = uint8(7);
            end

            if coder.target('Rtw')
                coder.ceval('MW_AnalogInSingle_ReadResult', obj.MW_ANALOGIN_HANDLE, coder.wref(mw_analogin_result_out), uint8(datatype_id));
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        mw_analogin_result_out=readResultAnalogInSingleInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO, obj.OutputDataType);
                        mw_analogin_result_out = typecast(uint8(mw_analogin_result_out),obj.OutputDataType);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function start(obj)
            if ~obj.ReadResultsOnly && isequal(obj.ConversionTriggerSource, 'Software')
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_Start', obj.MW_ANALOGIN_HANDLE);
                else
                    if coder.target('MATLAB')
                        if obj.IsIOEnable
                            startAnalogInConversionInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                        else
                            %do nothing
                        end
                    end
                end
            end
        end
        
        function stop(obj)
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_Stop', obj.MW_ANALOGIN_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        stopAnalogInConversionInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function close(obj)
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_Close', obj.MW_ANALOGIN_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        unconfigureAnalogInSingleInternal(obj.analogInClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                        obj.DeployAndConnectHandle.deleteConnectedIOClient;
                    else
                        %do nothing
                    end
                end
            end
        end
    end
    
    %% Input/outputs methods
    methods (Access=protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Don't show direction since it is fixed to 'output'
            if obj.ReadResultsOnly
                if isequal(prop, 'Pin') || isequal(prop,'ReadResultsOnly') ...
                        || isequal(prop,'OutputDataType')
                    flag = false;
                else
                    flag = true;
                end
            else
                if isequal(obj.ConversionTriggerSource, 'Software') ...
                        && isequal(prop,'ExternalTriggerType')
                    flag = true;
                else
                    flag = false;
                end
            end
        end
        
        % Number of inputs to step method
        function numIn = getNumInputsImpl(~)
            numIn = 0;
        end
        
        % Number of outputs from step method
        function numOut = getNumOutputsImpl(obj)
            numOut = 1 + obj.EnableOuputStatus;
        end
        
        % Names of System block output ports
        function varargout = getOutputNamesImpl(obj)
            varargout{1} = 'Data';
            
            if obj.EnableOuputStatus
                varargout{getNumOutputsImpl(obj)} = 'Status';
            end
        end
        
        % Set all outputs with fixed size outputs
        function varargout = isOutputFixedSizeImpl(obj)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = true;
            end
        end
        
        % Set output data type
        function varargout = getOutputDataTypeImpl(obj)
            varargout{1} = obj.OutputDataType;
            
            if obj.EnableOuputStatus
                varargout{end+1} = 'uint8';
            end
        end
        
        % Output size
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [1 1];
            
            if obj.EnableOuputStatus
                varargout{end+1} = [1 1];
            end
        end
        
        % Output complex
        function varargout = isOutputComplexImpl(obj)
            varargout{1} = false;
            if obj.EnableOuputStatus
                varargout{end+1} = false;
            end
        end
        
        
        
        
        function getAnalogInHandle(obj)
            if coder.target('Rtw')
                obj.MW_ANALOGIN_HANDLE = coder.opaque('MW_Handle_Type', 'HeaderFile','MW_SVD.h');
                if isnumeric(obj.Pin)
                    obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogIn_GetHandle',obj.Pin);
                else
                    pinname = coder.opaque('uint32_T', obj.Pin);
                    obj.MW_ANALOGIN_HANDLE = coder.ceval('MW_AnalogIn_GetHandle',pinname);
                end
                
            else
                obj.MW_ANALOGIN_HANDLE = coder.nullcopy(0);
            end
        end
    end
    
    %% Run-time methods
    methods (Access=protected)
        function setupImpl(obj)
            if ~obj.ReadResultsOnly
                % Initialise AnalogIn Group
                open(obj);
                % Set trigger type
                setTriggerSource(obj);
                % Enable Notification if any
                setNotificationType(obj);
            end
        end
        
        function varargout = stepImpl(obj,varargin)
            % Trigger AnalogIn with software
            if ~obj.ReadResultsOnly
                start(obj);
            end
            
            % Initialize status output
            if obj.EnableOuputStatus
                varargout{2} = uint8(0);
            end
            
            % Read Ouput result
            if obj.ReadResultsOnly
                getAnalogInHandle(obj);
            end
            varargout{1} = readAnalogInResult(obj);
            
            % Read status
            if obj.EnableOuputStatus
                varargout{obj.NumberOfChannels+1} = getAnalogInStatus(obj);
            else
            end
        end
        
        function releaseImpl(obj)
            if ~obj.ReadResultsOnly
                % Reset Notifications
                resetNotificationType(obj);
                % Stop AnalogIn
                stop(obj);
                % Release AnalogIn
                close(obj);
            end
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
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','Analog Input', ...
                'Text', [['Measure the voltage of an analog input pin.' newline newline] ...
                        'Do not assign the same Pin number to multiple blocks within a model.']);
        end

        function [groups, PropertyList] = getPropertyGroupsImpl
		    % Pin Pin
			PinProp = matlab.system.display.internal.Property('Pin', 'Description', 'svd:svd:PinPrompt');
            % ReadResultsOnly Read results only
            ReadResultsOnlyProp = matlab.system.display.internal.Property('ReadResultsOnly', 'Description', 'svd:svd:AnalogReadResultsOnlyPrompt');
            % ConversionTriggerSource Trigger A/D conversion
            ConversionTriggerSourceProp = matlab.system.display.internal.Property('ConversionTriggerSource', 'Description', 'svd:svd:AnalogConversionTriggerSourcePrompt');
            % ExternalTriggerSource External trigger source
            ExternalTriggerTypeProp = matlab.system.display.internal.Property('ExternalTriggerType', 'Description', 'svd:svd:AnalogExternalTriggerTypePrompt');
            % OutputDataType Output data type
            OutputDataTypeProp = matlab.system.display.internal.Property('OutputDataType', 'Description', 'svd:svd:AnalogOutputDataTypePrompt');
            % EnableConversionCompleteNotify Enable conversion complete notification
            EnableConversionCompleteNotifyProp = matlab.system.display.internal.Property('EnableConversionCompleteNotify', 'Description', 'svd:svd:AnalogEnableConversionCompleteNotifyPrompt');
            % EnableOuputStatus Output A/D conversion status
            EnableOuputStatusProp = matlab.system.display.internal.Property('EnableOuputStatus', 'Description', 'svd:svd:AnalogEnableOuputStatusPrompt');
                        
            % Property list
            PropertyListOut = {PinProp, ReadResultsOnlyProp, ConversionTriggerSourceProp, ExternalTriggerTypeProp, OutputDataTypeProp, EnableConversionCompleteNotifyProp, EnableOuputStatusProp};

            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;

            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
    
    methods (Static, Access=protected)
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
    end    
end
