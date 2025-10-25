classdef (StrictDefaults)SCIRead < matlabshared.svd.SCI & ...
        matlabshared.svd.BlockSampleTime
    %SCIREADBLOCK Read data From the Universal Asynchronous Receiver Transmitter(UART) port.
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    %#codegen    
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end

    properties(Nontunable)
        %DataType Data type
        DataType = 'uint8';
        %DataLength Data length (N)
        DataLength = 1;
    
        %OutputStatus Output status
        OutputStatus (1, 1) logical = false;
        %SampleTime Sample time
        SampleTime = -1;
    end

    properties(Constant, Hidden)
        DataTypeSet = matlab.system.StringSet({'uint8','int8','uint16','int16','uint32','int32','single','double'});
    end
    
    methods
        % Constructor
        function obj = SCIRead(varargin)
            obj = obj@matlabshared.svd.SCI(varargin{:});
            obj.Direction = 'Receive';
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end

        function set.DataLength(obj, value)            
            validateattributes(value,{'numeric'}, {'real','positive','scalar','integer','finite','nonnan','nonempty','<',2^31}, '', 'Data length (N)');
            
            obj.DataLength = value;
        end

        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');

            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods(Access = protected)
        function setupImpl(obj)
            % Initialise SCI Module
            open(obj);
        end
        
        function varargout = stepImpl(obj)
            nargoutchk(1,2);
            
            [RxData, status] = read(obj, obj.DataLength, obj.DataType);
            
            varargout{1} = RxData;
            if nargout > 1
                varargout{2} = status;
            end
        end

        function releaseImpl(obj)
            % Release resources, such as file handles
            close(obj);
        end

        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 0;
        end

        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            if obj.OutputStatus
                num = 2;
            else
                num = 1;
            end
        end

        function varargout = getOutputNamesImpl(obj)
            % Return output port names for System block
            varargout{1} = 'Rx';
            if obj.OutputStatus
                varargout{2} = 'Status';
            end
        end

        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            varargout{1} = [obj.DataLength 1];

            if obj.OutputStatus
                varargout{2} = [1 1];
            end
        end

        function varargout = getOutputDataTypeImpl(obj)
            % Get the Data bits for SCI
            if ~isempty(obj.Hw) && ~getSCIParametersVisibility(obj.Hw, obj.SCIModule)
                DataBitsLoc = getSCIDataBits(obj.Hw, obj.SCIModule);
                if (uint32(DataBitsLoc) < uint32(5)) || (uint32(DataBitsLoc) > uint32(9))
                    error('svd:svd:AllowedSCIDataBits','SCI allows data bits between 5 to 9.');
                end
            else
                DataBitsLoc = obj.DataBitsLengthEnum;
            end
            
            % Data bits are 8 then all data types are possible
            if isequal(DataBitsLoc, 8)
                varargout{1} = obj.DataType;
            elseif isequal(DataBitsLoc, 9)
                % Only uint16
                varargout{1} = 'uint16';
            else
                % only uint8
                varargout{1} = 'uint8';
            end

            if obj.OutputStatus
                varargout{2} = 'uint8';
            end
        end

        function varargout = isOutputComplexImpl(obj)
            % Return true for each output port with complex data
            varargout{1} = false;
            if obj.OutputStatus
                varargout{2} = false;
            end
        end

        function varargout = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            varargout{1} = true;

            if obj.OutputStatus
                varargout{2} = true;
            end
        end
        
        function sts = getSampleTimeImpl(obj)
          sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
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
            
            if isnumeric(obj.SCIModule)
                sciname = ['sprintf(''SCI: 0x%X'',' num2str(obj.SCIModule) ')'];
            else
                sciname = ['sprintf(''SCI: %s'',''' obj.SCIModule ''')'];
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,50,''\fontsize{12}\bfSCI Read'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,15,' sciname ',''horizontalAlignment'', ''center'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','SCI Read', ...
                'Text', ['Read data From the Universal Asynchronous Receiver Transmitter(UART) port.' newline newline ...
                'The block outputs the values received as an [Nx1] array.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % SCI base property list
            [~, PropertyListOut] = matlabshared.svd.SCI.getPropertyGroupsImpl;
            
            %DataType Data type
            DataTypeProp = matlab.system.display.internal.Property('DataType', 'Description', 'svd:svd:DataTypePrompt');
            %DataLength Data length (N)
            DataLengthProp = matlab.system.display.internal.Property('DataLength', 'Description', 'svd:svd:SCIDataLengthPrompt');
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:SCIOutputStatusPrompt');
            %SampleTime Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            
            % Property list
            PropertyListOut{end+1} = DataTypeProp;
            PropertyListOut{end+1} = DataLengthProp;
            PropertyListOut{end+1} = OutputStatusProp;
            PropertyListOut{end+1} = SampleTimeProp;

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
