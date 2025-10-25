classdef (StrictDefaults)CANFDWrite < matlabshared.svd.CANFD
    %CANWRITEBLOCK Send data to CAN Bus.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
        Title = 'CAN-FD Write'
    end
    
    properties (Nontunable)
        % Message ID
        MsgId = 100;
        % Message Length
        MsgLen = 64;
        % Identifier type
        Identifier (1,:) char {matlab.system.mustBeMember(Identifier,{'Standard (11-bit identifier)','Extended (29-bit identifier)'})} = 'Standard (11-bit identifier)';
        % Data Format 
        DataFormat (1,:) char {matlab.system.mustBeMember(DataFormat,{'Raw data', 'CAN msg'})} = 'Raw data';
        % CAN message type
        CANMessageType (1,:) char {matlab.system.mustBeMember(CANMessageType,{'Classic CAN','CAN-FD'})} = 'CAN-FD';       
    
        %OutputStatus Output status
        OutputStatus (1, 1) logical = false;
        % Bit rate switching 
        BitRateSwitching (1, 1) logical = false;
        % Remote frame
        RemoteFrame (1, 1) logical = false;
    end
    
    methods
        % Constructor
        function obj = CANFDWrite(varargin)
            obj = obj@matlabshared.svd.CANFD(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.MsgLen(obj,value)
            if isequal(obj.CANMessageType, 'CAN-FD') %#ok<MCSUP>
                validateattributes(value,...
                    {'numeric'},...
                    {'real','nonnegative','integer','scalar','<=',64},...
                    '', ...
                    'Length (bytes)');
                possibleValues = [0, 1, 2,  3,  4,  5,  6, 7, 8, 12, 16, 20, 24, 32, 48, 64];   % Check if we can prvide deropdown 
                mustBeMember(value,possibleValues);
            else
                validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar','<=',8},...
                '', ...
                'Length (bytes)');
            end
            obj.MsgLen = value;
        end
        
        function set.MsgId(obj,value)
            if isequal(obj.Identifier, 'Standard (11-bit identifier)') %#ok<MCSUP>
                msgIdLimit = hex2dec('7ff');
            else
                msgIdLimit = hex2dec('1fffffff');
            end
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar','<=',msgIdLimit},...
                '', ...
                'Message ID');
            obj.MsgId = value;
        end
    end
    
    methods (Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            switch prop
                case {'MsgId', 'MsgLen', 'Identifier','CANMessageType'}
                    if isequal(obj.DataFormat, 'Raw data')
                        flag = false;
                    else
                        flag = true;
                    end
                case 'BitRateSwitching'
                    if isequal(obj.DataFormat, 'Raw data') && isequal(obj.CANMessageType, 'CAN-FD')
                        flag = false;
                    else
                        flag = true;
                    end
                case 'RemoteFrame'
                    if isequal(obj.DataFormat, 'Raw data') && isequal(obj.CANMessageType, 'Classic CAN')
                        flag = false;
                    else
                        flag = true;
                    end
                otherwise
                    flag = false;
            end
        end
    end
    
    methods(Access = protected)
        function varargout = stepImpl(obj, varargin)
            Status = uint8(0);
            if coder.target('RtwForRapid') || coder.target('RtwForSfun')
                %
            elseif coder.target('Rtw')
                if isequal(obj.DataFormat, 'Raw data')
                    if isequal(obj.Identifier, 'Standard (11-bit identifier)')
                        ext = uint8(0);
                    else
                        ext = uint8(1);
                    end
                    if isequal(obj.CANMessageType,'CAN-FD')
                       fdf = uint8(1); % set frame format bit
                       rem = uint8(0); % Remote bit always 0 for CAN-FD
                       if obj.BitRateSwitching
                            brs = uint8(1);
                        else
                            brs = uint8(0);
                       end
                    else
                        fdf = uint8(0); % frame format bit 0
                        brs = uint8(0); % bit rate switching disabled
                        if obj.RemoteFrame
                            rem = uint8(1);
                        else
                            rem = uint8(0);
                        end
                    end
                        Status = write(obj, varargin{1}, obj.MsgId, obj.MsgLen, uint8(rem), uint8(ext),uint8(fdf),uint8(brs));
                else
                    % if both fields present in CANFD message when
                    % message coming from CANFD Pack block
                    % if both fields not present in CAN message when
                    % message coming from CAN Pack block
                    if isfield(varargin{1},'ProtocolMode')
                       ProtocolMode = varargin{1}.ProtocolMode;
                    else
                       ProtocolMode = uint8(0);
                    end
                    if isfield(varargin{1},'BRS')
                       % if both fields present in CANFD message when
                       % message coming from CANFD Pack block
                       BRS = varargin{1}.BRS;
                    else
                       
                       BRS = uint8(0);
                    end
                    Status = write(obj, varargin{1}.Data, varargin{1}.ID, varargin{1}.Length, varargin{1}.Remote, varargin{1}.Extended, ProtocolMode, BRS);
                end
            end
            if nargout > 0
                varargout{1} = Status;
            end
        end
        
        function validateInputsImpl(obj, data) % provide validation for structure elements if DAta format is CAN message 
            if isequal(obj.DataFormat, 'Raw data')
                if obj.MsgLen > 0
                    if coder.target('MATLAB')
                        try
                            validateattributes(data, {'uint8'},{'nonnan','finite','size',[obj.MsgLen,1]}, '', 'data');
                        catch ME
                             switch ME.identifier
                                 case 'MATLAB:invalidType'
                                    error(message('TIC2000:blocks:CANInportInvalidDataype'));
                                 otherwise
                                     rethrow(ME);
                             end
                        end
                    end
                end
            end
        end
        
        function setupImpl(obj)
            % Initialise CAN Module
            open(obj);
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            close(obj);
        end
        
        
        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 1;
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            if obj.OutputStatus
                num = 1;
            else
                num = 0;
            end
        end
        
        function varargout = getInputNamesImpl(~)
            % Return input port names for System block
            varargout{1} = 'Tx';
        end
        
        function varargout = getOutputNamesImpl(obj)
            if obj.OutputStatus
                varargout{1} = 'Status';
            else
                varargout = {};
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            if obj.OutputStatus
                varargout{1} = [1 1];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            if obj.OutputStatus
                varargout{1} = 'uint8';
            end
        end
        
        function out = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            out = false;
        end
        
        function varargout = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            if obj.OutputStatus
                varargout{1} = true;
            end
        end
    end
    
    methods (Access=protected)
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            if isequal(obj.DataFormat,'Raw data')
               if isequal(obj.CANMessageType,'Classic CAN')
                    idType = "CAN STD:";
                    if isequal(obj.Identifier, 'Extended (29-bit identifier)')
                        idType = "CAN XTD:";
                    end
               else
                   idType = "CAN-FD STD:";
                    if isequal(obj.Identifier, 'Extended (29-bit identifier)')
                        idType = "CAN-FD XTD:";
                    end
               end
                if isequal(obj.RemoteFrame, true)
                    maskDisplayCmds_Specific = [ ...
                        ['text(50, 30, ''\fontsize{9}' 'Remote Frame' '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline]...
                        ['text(50, 15, ''\fontsize{8}' idType{1} int2str(obj.MsgId) '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline]  ...
                        ];
                else
                    maskDisplayCmds_Specific = ['text(50, 35, ''\fontsize{8}' idType{1} int2str(obj.MsgId) '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline];
                end
            else
                maskDisplayCmds_Specific = [];
            end
            
            maskDisplayCmds_Common = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,50,''\bf' obj.Title ''', ''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
            
            maskDisplayCmds = [maskDisplayCmds_Common, maskDisplayCmds_Specific];
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
                'Title','CAN-FD Write', ...
                'Text', ['Send serial data to CAN Bus.' newline newline ...
                'In "Raw data" mode, the block accepts a 1-D array of type uint8. In "CAN msg" mode, the block accepts input as Simulink bus signal from CAN-FD Pack block']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % CAN base property list
            [~, PropertyListOut] = matlabshared.svd.CANFD.getPropertyGroupsImpl;
            
            DataFormatProp = matlab.system.display.internal.Property('DataFormat', 'Description', 'svd:svd:CANDataFormatPrompt');
            CANIdProp  = matlab.system.display.internal.Property('Identifier', 'Description', 'svd:svd:CANIdentifierPrompt');
            CANMsgIDProp  = matlab.system.display.internal.Property('MsgId', 'Description', 'svd:svd:CANMsgIdPrompt');
            CANMsgLenProp  = matlab.system.display.internal.Property('MsgLen', 'Description', 'svd:svd:CANMsgLenPrompt');
            CANMessageTypeProp = matlab.system.display.internal.Property('CANMessageType', 'Description', 'svd:svd:CANMessageTypePrompt');
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputStatusPrompt');
            RemoteFrameProp = matlab.system.display.internal.Property('RemoteFrame', 'Description', 'svd:svd:CANRemoteFramePrompt');
            BitRateSwitchingProp = matlab.system.display.internal.Property('BitRateSwitching', 'Description', 'svd:svd:CANBitRateSwitchingPrompt');
            % Property list
            PropertyListOut{end+1} = DataFormatProp;
			PropertyListOut{end+1} = CANMessageTypeProp;
            PropertyListOut{end+1} = CANIdProp;
            PropertyListOut{end+1} = CANMsgIDProp;
            PropertyListOut{end+1} = CANMsgLenProp;
            PropertyListOut{end+1} = BitRateSwitchingProp;
            PropertyListOut{end+1} = RemoteFrameProp;
            PropertyListOut{end+1} = OutputStatusProp;
            
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            % Return property list if required
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
