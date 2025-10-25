classdef (StrictDefaults)AnalogIn < matlab.System & coder.ExternalDependency
    %ADCDEV ADC device base class
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
       
    properties (Hidden)
        Hw = [];
    end
    
    % Can come from Hw object
    properties (Nontunable)
        % GroupId ADC group
        GroupId = uint32(1);
        % ChannelsId Channels list (Maximum 20)
        ChannelsId = uint32(1);
        % ChannelsConversionTimeInSec Channels conversion time in seconds (Maximum 20)
        ChannelsConversionTimeInSec = 1;
    
        % ReadResultsOnly Read results only
        ReadResultsOnly (1, 1) logical = false;
    
        % ConversionTriggerSource Trigger A/D conversion
        ConversionTriggerSource = 'Software';
        % ExternalTriggerSource External trigger source
        ExternalTriggerType = uint32(0);
        % OutputDataType Output data type
        OutputDataType = 'double';
    
        % EnableContinuousConversion Enable continuous conversion
        EnableContinuousConversion (1, 1) logical = false;
        % EnableConversionCompleteNotify Enable conversion complete notification
        EnableConversionCompleteNotify (1, 1) logical = false
        % EnableOuputStatus Output A/D conversion status
        EnableOuputStatus (1, 1) logical = false;
    end
    
    properties (Access = private, Dependent)
        NumberOfChannels;
    end
    
    % Drop down list
    properties (Constant, Hidden)
        ConversionTriggerSourceSet = matlab.system.StringSet({'Software','External trigger'});
        OutputDataTypeSet = matlab.system.StringSet({'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'single', 'double'});
    end
    
    % Property set/get methods
    methods
        % Validate GroupId
        function set.GroupId(obj, value)
            % Validate Pin value
            if isempty(obj.Hw)
                validateattributes(value, {'numeric'}, ...
                    {'scalar', 'integer','nonnegative','finite','nonnan','nonempty'}, ...
                    '', ...
                    'GroupId');
            else
%                 if ~ismember(value, obj.Hw.AnalogIn.GroupId)
%                     error('foo:bar','Invalid pin');
%                 end
                if ~ismember(value, obj.Hw.AnalogIn.AvailablePin)
                    error(message('svd:svd:PinNotFound',value,'Analog input'));
                end
            end
            
            % Assign value
            obj.GroupId = uint32(value);
        end
        
        % Validate GroupId
        function set.ChannelsId(obj, value)
            % Validate Pin value
            if isempty(obj.Hw)
                validateattributes(value, {'numeric', 'embedded.fi'}, ...
                    {'vector', 'integer', 'nonnegative','finite','nonnan','nonempty'}, ...
                    '', 'ChannelsId');
                
                assert(numel(value) <= 20, 'Maximum channels allowed is 20 in a group.');
                
                assert(numel(value) == numel(unique(value)), 'Repeating channels');
            else
%                 if ~ismember(value, obj.Hw.AnalogIn.ChannelsId)
%                     error('foo:bar','Invalid pin');
%                 end
            end
            
            if isfloat(value)
                % Assign value
                obj.ChannelsId = uint32(value);
            else
                % Assign value
                obj.ChannelsId = value;
            end
        end
        
        % Validate GroupId
        function set.ChannelsConversionTimeInSec(obj, value)
            % Validate Pin value
            if isempty(obj.Hw)
                validateattributes(value, {'numeric', 'embedded.fi'}, ...
                    {'vector','real','nonnegative','finite','nonnan','nonempty'}, ...
                    '', 'ChannelsConversionTimeInSec');
                
                assert(numel(value) <= 20, 'Maximum channels allowed is 20 in a group.');
            else
%                 if ~ismember(value, obj.Hw.AnalogIn.ChannelsConversionTimeInSec)
%                     error('foo:bar','Invalid pin');
%                 end
            end
            
            % Assign value
            obj.ChannelsConversionTimeInSec = value;
        end
        
        function set.ExternalTriggerType(obj, value)
            validateattributes(value, {'numeric', 'embedded.fi'}, ...
                {'scalar','integer','nonnegative'}, ...
                '', 'ExternalTriggerSource');
            
            % Assign value
            obj.ExternalTriggerType = uint32(value);
        end
        
        function value = get.NumberOfChannels(obj)
            value = uint8(numel(obj.ChannelsId));
        end
    end
    
    % Functional methods
    methods
        % Constructor
        function obj = AnalogIn(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function open(obj, GroupId, ChannelsInGroup, ChannelConversionTimeSec)
            if nargin > 1
                narginchk(4,4);
                
                obj.GroupId = GroupId;
                obj.ChannelsId = ChannelsInGroup;
                obj.ChannelsConversionTimeInSec = ChannelConversionTimeSec;
            else
                narginchk(1,1);
            end
            
            channelsId = obj.ChannelsId;
            chlconvtime = obj.ChannelsConversionTimeInSec;
            if coder.target('Rtw')
                coder.cinclude('MW_AnalogIn.h');
                coder.ceval('MW_AnalogInMulti_Open', obj.GroupId, coder.rref(channelsId), coder.rref(chlconvtime),obj.NumberOfChannels);
            else
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
                coder.ceval('MW_AnalogIn_SetTriggerSource', obj.GroupId, trigger_val, obj.ExternalTriggerType);
            else
            end
        end
        
        function setNotificationType(obj, EnableConversionCompleteNotify)
            narginchk(1,2);
            if nargin > 1
                obj.EnableConversionCompleteNotify = EnableConversionCompleteNotify;
            end

            if obj.EnableConversionCompleteNotify
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_EnableNotification', obj.GroupId);
                else
                end
            end
        end
        
        function resetNotificationType(obj)
            if obj.EnableConversionCompleteNotify
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_DisableNotification', obj.GroupId);
                else
                end
            end
        end
        
        function setContinuousConversion(obj, EnableContinuousConversion)
            narginchk(1,2);
            if nargin > 2
                obj.EnableContinuousConversion = EnableContinuousConversion;
            end
            
            if obj.EnableContinuousConversion
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_EnableContConversion', obj.GroupId);
                else
                end
            end
        end
        
        function setChannelConversionRank(obj, ChannelId, Rank)
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_SetChannelConvRank', obj.GroupId, ChannelId, uint32(Rank));
            else
                validateattributes(ChannelId, {'numeric', 'embedded.fi'}, ...
                    {'scalar','integer', 'nonnegative','finite','nonnan','nonempty'}, ...
                    '', 'ChannelId');
                validateattributes(ChannelId, {'numeric', 'embedded.fi'}, ...
                    {'scalar','integer', 'nonnegative','finite','nonnan','nonempty'}, ...
                    '', 'Rank');
                
                assert(ismember(ChannelId, obj.ChannelsId), 'Not memeber');
            end
        end
        
        function AnalogInStatus = getAnalogInStatus(obj)
            AnalogInStatus = uint8(0);
            
            if coder.target('Rtw')
                AnalogInStatus = coder.ceval('MW_AnalogIn_GetStatus', obj.GroupId);
            else
            end
        end
        
        function mw_analogin_result_out = readAnalogInResult(obj)
            % Initialize data output
            switch obj.OutputDataType
                case 'int8'
                    mw_analogin_result_out = int8(zeros(1,obj.NumberOfChannels));
                    datatype_id = 0;
                case 'uint8'
                    mw_analogin_result_out = uint8(zeros(1,obj.NumberOfChannels));
                    datatype_id = 1;
                case 'int16'
                    mw_analogin_result_out = int16(zeros(1,obj.NumberOfChannels));
                    datatype_id = 3;
                case 'uint16'
                    mw_analogin_result_out = uint16(zeros(1,obj.NumberOfChannels));
                    datatype_id = 4;
                case 'int32'
                    mw_analogin_result_out = int32(zeros(1,obj.NumberOfChannels));
                    datatype_id = 5;
                case 'uint32'
                    mw_analogin_result_out = uint32(zeros(1,obj.NumberOfChannels));
                    datatype_id = 6;
                case 'single'
                    mw_analogin_result_out = single(zeros(1,obj.NumberOfChannels));
                    datatype_id = 7;
                case 'double'
                    mw_analogin_result_out = double(zeros(1,obj.NumberOfChannels));
                    datatype_id = 8;
            end
            
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_ReadResult', obj.GroupId, coder.wref(mw_analogin_result_out), obj.NumberOfChannels, uint8(datatype_id));
            else
            end
        end
        
        function start(obj)
            if ~obj.ReadResultsOnly && isequal(obj.ConversionTriggerSource, 'Software')
                if coder.target('Rtw')
                    coder.ceval('MW_AnalogIn_Start', obj.GroupId);
                else
                end
            end
        end
        
        function stop(obj)
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_Stop', obj.GroupId);
            else
            end
        end
        
        function close(obj)
            if coder.target('Rtw')
                coder.ceval('MW_AnalogIn_Close', obj.GroupId);
            else
            end
        end
    end
    
    %% Input/outputs methods
    methods (Access=protected)
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
            varargout{1} = [1 double(obj.NumberOfChannels)];
            
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
        
        
        
        
        % Validate property values
        function validatePropertiesImpl(obj)
            assert(numel(obj.ChannelsId) == numel(obj.ChannelsConversionTimeInSec), message('svd:svd:MultiChannelAnalogInNumel',obj.GroupId));
        end
    end
    
    %% Run-time methods
    methods (Access=protected)
        function setupImpl(obj)
            if ~obj.ReadResultsOnly
                % Initialise AnalogIn Group
                open(obj);
                % Configure conversion priorities
                if obj.NumberOfChannels > 1
                    for i = 1:obj.NumberOfChannels
                        setChannelConversionRank(obj, obj.ChannelsId(i), i);
                    end
                end
                % Set trigger type
                setTriggerSource(obj);
                % Set Continuous Conversion mode
                setContinuousConversion(obj);
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
                % One-time deinit
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
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'AnalogInDev';
        end
        
        function tf = isSupportedContext(~)
            tf = true;
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Header paths
                rootDir = fileparts(mfilename('fullpath'));
                addIncludePaths(buildInfo,strrep(fullfile(rootDir,'..','..','include'), '\', '/'));
                % Use the following API's to add include files, sources and
                % linker flags
                addIncludeFiles(buildInfo,'MW_AnalogIn.h');
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

