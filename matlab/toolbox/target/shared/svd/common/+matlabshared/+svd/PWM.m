classdef (StrictDefaults)PWM < matlab.System
    % PWMDev PWM device base class

    %#codegen
    %#ok<*EMCA>

    % Copyright 2015-2021 The MathWorks, Inc.
    
    properties (Hidden, Nontunable)
        Hw = []
    end
    
    properties (Abstract,Nontunable)
        % Pin Pin
        Pin
    end
    properties (Hidden,Nontunable)
     %Handle to deploy and connect to IO server          
     DeployAndConnectHandle     
     %pwmioClient
     pwmIOClient
     %numeric pin for IO
     PinInternalIO    
     %variable to store Connected IO status
     IsIOEnable = false ;
    end 
    properties (Nontunable)
        % EnableInputFrequency Enable frequency input
        EnableInputFrequency (1, 1) logical = false;
    
        % InitialFrequency Initial frequency (Hz)
        InitialFrequency = 2000;
        % InitialDutyCycle Initial duty cycle (0 - 100)
        InitialDutyCycle = 0;
    
        % NotificationType Notify on PWM
        NotificationType = 'None';
    end
    
    % Drop down list
    properties (Constant, Hidden)
        NotificationTypeSet = matlab.system.StringSet({...
            'None', ...
            'Rising edge', ...
            'Falling edge', ...
            'Both rising and falling edges', ...
            });
    end
    
    properties (Access=private, Dependent)
        InitialFrequencyCast;
        InitialDutyCycleCast;
    end

    properties (Access = protected)
        MW_PWM_HANDLE;
    end
    
    methods
        function obj = PWM(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        % Validate InitialFrequency
        function set.InitialFrequency(obj, value)
            if isempty(coder.target)
                validateattributes(value, ...
                    {'numeric', 'embedded.fi'}, ...
                    {'scalar', 'real','nonnegative','finite','nonnan','nonempty'}, ...
                    '', ...
                    'InitialFrequency');
                if ~isempty(obj.Hw)
                    validateattributes(value, ...
                        {'numeric', 'embedded.fi'}, ...
                        {'scalar','real','finite','nonnan','nonempty','>=', getMinimumPWMFrequency(obj.Hw), '<=', getMaximumPWMFrequency(obj.Hw)}, ...
                        '', ...
                        'InitialFrequency'); %#ok<*MCSUP>
                end
            end
            obj.InitialFrequency = value;
        end

        function ret = get.InitialFrequencyCast(obj)
            ret = double(obj.InitialFrequency);
        end
        
        % Validate InitialDutyCycle
        function set.InitialDutyCycle(obj, value)
            if isempty(coder.target)
                validateattributes(value, ...
                    {'numeric', 'embedded.fi'}, ...
                    {'scalar', 'real','finite','nonnan','nonempty', '>=', 0, '<=', 100}, ...
                    '', ...
                    'InitialDutyCycle');
            end
            obj.InitialDutyCycle = value;
        end
        
        function ret = get.InitialDutyCycleCast(obj)
            ret = double(obj.InitialDutyCycle);
        end
    end
    
    methods       
        function open(obj)
            if coder.target('Rtw')
                % Initialise PWM
                coder.cinclude('MW_PWM.h');
                obj.MW_PWM_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                if isnumeric(obj.Pin)
                    obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_Open',obj.Pin, ...
                        obj.InitialFrequencyCast, ...
                        obj.InitialDutyCycleCast);
                else
                    pinname = coder.opaque('uint32_T', obj.Pin);
                    obj.MW_PWM_HANDLE = coder.ceval('MW_PWM_Open',pinname, ...
                        obj.InitialFrequencyCast, ...
                        obj.InitialDutyCycleCast);
                end
            else
                % Place simulation setup code here               
                obj.MW_PWM_HANDLE = coder.nullcopy(0);
                if isempty(obj.Pin)
                   error('svd:svd:EmptyPin', ...
                        ['The property Pin is not defined. You must set Pin ',...
                       'to a valid value.'])
                end

                if coder.target('MATLAB')
                    %simulink IO code
                    obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                    if obj.IsIOEnable
                        %handle to deploy and connect to IO server                       
                        obj.DeployAndConnectHandle=matlabshared.ioclient.DeployAndConnectHandle;
                        %get a connected IOclient object   
                        obj.DeployAndConnectHandle.getConnectedIOClient();

                        obj.pwmIOClient = matlabshared.ioclient.peripherals.PWM;
                        
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
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'PWM Output')));
                                end                         
                            else
                                validateattributes(str2double(obj.Pin),{'numeric'},{'nonnegative','integer','scalar','real'},'','Digital Pin');                               
                                try
                                    codertarget.simulinkIO.(hardwareName).pinInterface(str2double(obj.Pin));
                                catch
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'PWM Output')));
                                end
                                obj.PinInternalIO =uint32(str2double(obj.Pin));
                            end
                        end
                        try
                            status=configurePWMPinInternal(obj.pwmIOClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO, obj.InitialFrequency, obj.InitialDutyCycle/100); % IO server expects duty cycle between 0-1
                        %error when configuring PWM
                        catch
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedReconnect',obj.Pin,'PWM Output')));
                        end
                        
                        if(status)
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedPinConflict',obj.Pin,'PWM Output')));
                        end
                        
                    end
                end
            end
        end
        
        function setPWMDutyCycle(obj, DutyCycle)
            if coder.target('Rtw')
                % Initialise PWM
                coder.ceval('MW_PWM_SetDutyCycle',obj.MW_PWM_HANDLE, ...
                    double(DutyCycle));
            else
                validateattributes(DutyCycle, ...
                        {'numeric', 'embedded.fi'}, ...
                        {'scalar', '>=', 0, '<=', 100}, ...
                        '', ...
                        'Duty Cycle');
                % Place simulation setup code here
                if coder.target('MATLAB')
                    if obj.IsIOEnable

                        setPWMDutyCycleInternal(obj.pwmIOClient,obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO, DutyCycle/100);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function setPWMFrequency(obj, frequencyInHz)
            if coder.target('Rtw')
                coder.ceval('MW_PWM_SetFrequency',obj.MW_PWM_HANDLE, ...
                    double(frequencyInHz));
            else
                validateattributes(frequencyInHz, ...
                    {'numeric', 'embedded.fi'}, ...
                    {'scalar', 'nonnegative','finite','nonnan','nonempty'}, ...
                    '', ...
                    'Frequency');

                    % Check input frequency is within the range
                if ~isempty(obj.Hw)
                    minFreq = getMinimumPWMFrequency(obj.Hw);
                    maxFreq = getMaximumPWMFrequency(obj.Hw);
                    validateattributes(frequencyInHz, ...
                        {'numeric', 'embedded.fi'}, ...
                        {'scalar','finite','nonnan','nonempty', '>=', minFreq, '<=', maxFreq}, ...
                        '', ...
                        'Frequency');
                end
                % Place simulation code here               
                if coder.target('MATLAB')
                    if obj.IsIOEnable

                        setPWMFrequencyInternal(obj.pwmIOClient,obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO, frequencyInHz);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function setNotificationType(obj, NotificationType)
            obj.NotificationType = NotificationType;
            if coder.target('Rtw')
                if ~strcmp(obj.NotificationType, 'None')
                    % Evaluate notification selection to 'PWM_EdgeNotificationType'
                    notify_val = coder.const(@obj.getPwmNotificationTypeValue, obj.NotificationType);
                    notify_val = coder.opaque('MW_PWM_EdgeNotification_Type', notify_val);
                    % Generate code to enable notification
                    coder.ceval('MW_PWM_EnableNotification', obj.MW_PWM_HANDLE, notify_val);
                end
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                      if ~strcmp(obj.NotificationType, 'None')
                        %Not Supported in Simulink IO
                        throwAsCaller(MException(message('svd:svd:EnableNotificationPWMNotSupportedIO')));
                      end
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function resetNotificationType(obj)
            if coder.target('Rtw')
                if ~strcmp(obj.NotificationType, 'None')
                    % Generate code to disable notification
                    coder.ceval('MW_PWM_DisableNotification', obj.MW_PWM_HANDLE);
                end
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                      if ~strcmp(obj.NotificationType, 'None')
                        %Not Supported in Simulink IO
                        throwAsCaller(MException(message('svd:svd:DisableNotificationPWMNotSupportedIO')));
                      end
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function start(obj)
            if coder.target('Rtw')
                % Start PWM
                coder.ceval('MW_PWM_Start',obj.MW_PWM_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        startPWMInternal(obj.pwmIOClient,obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function PwmOutStatus = getPWMOutputStatus(obj)
            PwmOutStatus = coder.nullcopy(double(0));
            if coder.target('Rtw')
                % Get PWM Output status
                PwmOutStatus = coder.ceval('MW_PWM_GetOutputState',obj.MW_PWM_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        getPWMOutputStateInternal(obj.pwmIOClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function stop(obj)
            if coder.target('Rtw')
                % Before stopping PWM, disable notifications if enabled
                if ~strcmp(obj.NotificationType, 'None')
                    % Generate code to disable notification
                    coder.ceval('MW_PWM_DisableNotification', obj.MW_PWM_HANDLE);
                end
                
                % Stop PWM
                coder.ceval('MW_PWM_Stop',obj.MW_PWM_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        if ~strcmp(obj.NotificationType, 'None')
                            disablePWMNotificationInternal(obj.pwmIOClient, obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                        end
                        stopPWMInternal(obj.pwmIOClient,obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function close(obj)
            
            % Disable notifications if any
            stop(obj);
             
            if coder.target('Rtw')                
                % Release PWM
                coder.ceval('MW_PWM_Close',obj.MW_PWM_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        unconfigurePWMPinInternal(obj.pwmIOClient,obj.DeployAndConnectHandle.IoProtocol, obj.PinInternalIO);
                        obj.DeployAndConnectHandle.deleteConnectedIOClient;
                    else
                        %do nothing
                    end
                end
            end
        end
    end

    methods (Access = protected)
        % Number of inputs to step method
        function numIn = getNumInputsImpl(obj)
            if obj.EnableInputFrequency
                numIn = 2;
            else
                numIn = 1;
            end
        end
        
        % Names of System block input ports
        function varargout = getInputNamesImpl(obj)
            % numInputs = getNumInputs(obj);
            varargout{1} = 'Duty Cycle';
            if obj.EnableInputFrequency
                varargout{2} = 'Frequency';
            end
        end
        
        % Number of outputs from step method
        function numOut = getNumOutputsImpl(~)
            numOut = 0;
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout = {};
        end
        
        % Initialize System object
        function setupImpl(obj, varargin)
            % Initialise PWM Channel Pin
            open(obj);
            % Enable Notification if any
            setNotificationType(obj, obj.NotificationType);
            % Start PWM
            start(obj);
        end
        
        % System output and state update equations
        function stepImpl(obj,varargin)
            if obj.EnableInputFrequency
                frequency = double(varargin{2});
                setPWMFrequency(obj, frequency);
            end
			
			dutyCycle = double(varargin{1});
            setPWMDutyCycle(obj, dutyCycle);            
        end
        
        % Release resources
        function releaseImpl(obj)
            % Close PWM channel
            close(obj);
        end

        
        
        
        function validateInputsImpl(~, varargin)
            if isempty(coder.target)
                % Run this always in Simulation
                validateattributes(varargin{end}, ...
                    {'numeric', 'embedded.fi'}, ...
                    {'scalar', '>=', 0, '<=', 100}, ...
                    '', ...
                    'Duty Cycle');
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
%         function header = getHeaderImpl()
%             header = matlab.system.display.Header(mfilename('class'),...
%                 'ShowSourceLink', false, ...
%                 'Title','Analog Input', ...
%                 'Text', [['Measure the voltage of an analog input pin.' char(10) char(10)] ...
%                         'Do not assign the same Pin number to multiple blocks within a model.']);
%         end

        function [groups, PropertyList] = getPropertyGroupsImpl
            % Pin Pin
            PinProp = matlab.system.display.internal.Property('Pin', 'Description', 'svd:svd:PinPrompt');
            % EnableInputFrequency Enable frequency input
            EnableInputFrequencyProp = matlab.system.display.internal.Property('EnableInputFrequency', 'Description', 'svd:svd:PWMEnableInputFrequencyPrompt');
            % InitialFrequency Initial frequency (Hz)
            InitialFrequencyProp = matlab.system.display.internal.Property('InitialFrequency', 'Description', 'svd:svd:PWMInitialFrequencyPrompt');
            % InitialDutyCycle Initial duty cycle (0 - 100)
            InitialDutyCycleProp = matlab.system.display.internal.Property('InitialDutyCycle', 'Description', 'svd:svd:PWMInitialDutyCyclePrompt');
            % NotificationType Notify on PWM
            NotificationTypeProp = matlab.system.display.internal.Property('NotificationType', 'Description', 'svd:svd:PWMNotificationTypePrompt');
      
            % Property list
            PropertyListOut = {PinProp, EnableInputFrequencyProp, InitialFrequencyProp, InitialDutyCycleProp, NotificationTypeProp};

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
        function NotificationValue = getPwmNotificationTypeValue(NotificationValueStr)
            coder.inline('always');
            switch NotificationValueStr
                case 'Rising edge'
                    NotificationValue = 'MW_PWM_RISING_EDGE';
                case 'Falling edge'
                    NotificationValue = 'MW_PWM_FALLING_EDGE';
                case 'Both rising and falling edges'
                    NotificationValue = 'MW_PWM_BOTH_EDGES';
                otherwise
                    NotificationValue = 'MW_PWM_NO_NOTIFICATION';
            end            
        end
    end
end