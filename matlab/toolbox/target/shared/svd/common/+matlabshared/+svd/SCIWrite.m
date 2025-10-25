classdef (StrictDefaults)SCIWrite < matlabshared.svd.SCI
    %SCIWRITEBLOCK Send serial data to the Universal Asynchronous Receiver Transmitter(UART) port.
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    %#codegen    
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end

    properties (Nontunable)
        %OutputStatus Output status
        OutputStatus (1, 1) logical = false;
    end

    methods
        % Constructor
        function obj = SCIWrite(varargin)
            obj = obj@matlabshared.svd.SCI(varargin{:});
            obj.Direction = 'Transmit';
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        function varargout = stepImpl(obj,varargin)
            nargoutchk(0,1);
            
            status = write(obj, varargin{1}, class(varargin{1}));
            
            if nargout > 0
                varargout{1} = status;
            end
        end

        function setupImpl(obj)
            % Initialise SCI Module
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
                ['text(50,50,''\fontsize{12}\bfSCI Write'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,15,' sciname ',''horizontalAlignment'', ''center'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
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
                'Title','SCI Write', ...
                'Text', ['Send serial data to the Universal Asynchronous Receiver Transmitter(UART) port.' newline newline ...
                'The block expects the values as an [Nx1] or [1xN] array.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % SCI base property list
            [~, PropertyListOut] = matlabshared.svd.SCI.getPropertyGroupsImpl;
            
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:SCIOutputStatusPrompt');
            
            % Property list
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
