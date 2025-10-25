classdef (StrictDefaults)I2CSlaveRead < matlabshared.svd.I2CBlock ...
        & matlabshared.svd.BlockSampleTime
    %I2CSLAVEREAD Read uint8 data in slave on I2C bus.
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end

    properties (Nontunable)
        %SampleTime Sample time
        SampleTime = -1;
    end

    
    methods
        function obj = I2CSlaveRead(varargin)
            coder.allowpcode('plain');
            obj.Mode = 'Slave';
            obj.Direction = 'Receiver';
            setProperties(obj, nargin, varargin{:});
        end

        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');

            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods (Access=protected)
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.I2CBlock(obj, prop);
            % Don't show direction since it is fixed to 'input'
            switch (prop)
                case {'Mode','Direction'}
                    flag = true;
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' char(10)]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' char(10)]; %#ok<AGROW>
                end
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');', char(10)]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', char(10)]...
                ['plot([0,0,0,0],[0,0,0,0]);', char(10)]...
                ['color(''blue'');', char(10)] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', char(10)] ...
                ['color(''black'');', char(10)] ...
                ['text(50,60,''\fontsize{12}\bfI2C'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', char(10)], ...
                ['text(50,40,''\fontsize{10}\bfSlave Read'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', char(10)], ...
                ['text(50,15,''Address: 0x' sprintf('%X', obj.SlaveAddress) ''' ,''horizontalAlignment'', ''center'');', char(10)], ...
                inport_label, ...
                outport_label, ...
                ];
        end
        
        function sts = getSampleTimeImpl(obj)
          sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','I2C Slave Read', ...
                'Text', ['Read data from an I2C master device.' char(10) char(10)...
                'The block outputs the values received as an [Nx1] array.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.I2CBlock.getPropertyGroupsImpl;
            
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            
            % Add to property list
            PropertyListOut{end+1} = SampleTimeProp;
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end

