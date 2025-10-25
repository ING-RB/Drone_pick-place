classdef (StrictDefaults)I2CSlaveWrite < matlabshared.svd.I2CBlock 
    %I2CSLAVEWRITE Write data on I2C bus from slave.
    
    % Copyright 2015-2016 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    methods
        function obj = I2CSlaveWrite(varargin)
            coder.allowpcode('plain');
            obj.Mode = 'Slave';
            obj.Direction = 'Transmitter';
            setProperties(obj, nargin, varargin{:});
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
                ['text(50,40,''\fontsize{10}\bfSlave Write'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', char(10)], ...
                ['text(50,15,''Address: 0x' sprintf('%X', obj.SlaveAddress) ''' ,''horizontalAlignment'', ''center'');', char(10)], ...
                inport_label, ...
                outport_label, ...
                ];
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','I2C Slave Write', ...
                'Text', ['Write data to an I2C master device.' char(10) char(10) ...
                'The block accepts an [Nx1] or [1xN] array.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [groups, PropertyListOut] = matlabshared.svd.I2CBlock.getPropertyGroupsImpl;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end

