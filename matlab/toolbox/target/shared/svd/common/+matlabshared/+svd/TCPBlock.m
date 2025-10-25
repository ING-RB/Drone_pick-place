classdef (StrictDefaults)TCPBlock <  matlabshared.svd.TCP 
        % TCP base class
    
    %#codegen
    %#ok<*EMCA>
    
    % Copyright 2015-2021 The MathWorks, Inc.
    
    properties (Nontunable)
        % Direction
        Direction = 'Receive'
    end 
    
    properties (Constant, Hidden)
        DirectionSet = matlab.system.StringSet({'Receive','Send'});
        DataTypeSet = matlab.system.StringSet({...
            'double','single','int8','uint8',...
            'int16','uint16','int32','uint32',...
            'boolean', ...
            });
    end 
    
    properties (Dependent, Hidden)
        DirectionEnum
    end
    
   properties (Nontunable)
       OutputStatus (1, 1) logical = false;
    
        %DataType - Data type
        DataType = 'uint8';
        %DataLength - Data size (N)
        DataLength = 1;
    end
    
    properties (Nontunable, Dependent, Hidden)
        DataTypeLength;
    end
     
    
    methods
        function obj = TCPBlock(varargin)
            obj= obj@matlabshared.svd.TCP(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
        end
        
        function ret = get.DirectionEnum(obj)
            if isequal(obj.Direction,'Receive')
                ret = SVDTypes.MW_Input;
            else
                ret = SVDTypes.MW_Output;
            end
        end
        
        function set.DataLength(obj, val)
            validateattributes(val,{'numeric'},...
                {'nonnegative','scalar','integer','finite','nonnan','nonempty'}, ...
                '', 'Data Length');
            obj.DataLength = val;
        end
        
        function value = get.DataTypeLength(obj)
            switch obj.DataType
                case {'int8', 'uint8', 'boolean'}
                    value = 1;
                case {'int16', 'uint16'}
                    value = 2;
                case {'int32', 'uint32','single'}
                    value = 4;
                case {'double'}
                    value = 8;
            end
        end
    
    end
    
    
    methods (Access=protected)
        
         function num = getNumInputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                num = 0;
            else
                num = 1;
            end
        end
        
        function num = getNumOutputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
               num = 1 + obj.OutputStatus;
            else
               num = double(obj.OutputStatus);
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = [double(obj.DataLength) 1];
                if obj.OutputStatus
                    varargout{2} = [1 1];
                end
                validateattributes((obj.DataLength * obj.DataTypeLength), {'numeric'}, ...
                {'scalar', '<=', 1460}, ...
                '', 'output data size (in bytes)');
            else
                if obj.OutputStatus
                    varargout{1} = [1 1];
                end
                
            end
        end
        
        
        
        function varargout = getOutputDataTypeImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = obj.DataType;
                if obj.OutputStatus
                    varargout{2} = 'uint8';
                end
            else
                if obj.OutputStatus
                    varargout{1} = 'uint8';
                end
            end            
        end
        
        
         function varargout = getOutputNamesImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = 'Data';
                if obj.OutputStatus
                    varargout{2} = 'Status';
                end
            else
                if obj.OutputStatus
                    varargout{1} = 'Status';
                end
            end            
        end
        
        
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = true;
            end
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = false;
            end
        end
        
        function setupImpl(obj)
            open(obj);
        end
        
        function validatePropertiesImpl(~)
        end
        
        function varargout= stepImpl(obj,varargin)
            if obj.DirectionEnum == SVDTypes.MW_Input
                
%                 if coder.target('Rtw')% done only for code gen
                    
                    [TCPOutput, TCPStatus] = receive(obj, obj.DataType, obj.DataLength ,obj.DataTypeLength);
                    varargout{1} = TCPOutput;
                    
                    if nargout > 1
                        varargout{2} = TCPStatus;
                    end
                    
%                 elseif( coder.target('Sfun') )
%                       %Do nothing in simulation
%                 end
               
            else
                if coder.target('Rtw')% done only for code gen
                    TCPStatus= send(obj, varargin{1}, class(varargin{1}));
                    if nargout <= 1
                        varargout{1} = TCPStatus;
                    end
                    
                elseif ( coder.target('Sfun') )
                    %Do nothing in simulation
                end
            end
        end
        
        
        
        
         
        function releaseImpl(obj)
            close(obj);
        end
    end
    
      methods(Static, Access=protected)
        
      function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.TCP.getPropertyGroupsImpl;
            
            
            %SlaveDataType Data type
            DataTypeProp = matlab.system.display.internal.Property('DataType', 'Description', 'svd:svd:TCPUDPDataTypePrompt');
            %DataLength Data size (N)
            DataLengthProp = matlab.system.display.internal.Property('DataLength', 'Description', 'svd:svd:TCPUDPDataLengthPrompt');
             %OutputStatus Output error status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputErrorStatusPrompt');
            
            PropertyListOut{end+1} = DataTypeProp;
            PropertyListOut{end+1} = DataLengthProp;
            PropertyListOut{end+1} = OutputStatusProp;
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
      end
      
      function simMode = getSimulateUsingImpl(~)
          simMode = 'Interpreted execution';
      end
      
      function isVisible = showSimulateUsingImpl
          isVisible = false;
      end
      
      
    end
end


