classdef (StrictDefaults,Hidden) serializer1D < matlab.System
%serializer1D One dimension serializer
%   hdl1DSe = hdl.serializer1D returns a System object hdl1DSe, and
%   performs conversion of a vector input (slower rate) to smaller size
%   vectors (faster rate) or a stream of scalar outputs.
%
%  Step method syntax:
%
%   [dataOut, startOut, validOut] = step(obj, dataIn, validIn) dataIn is a
%   one dimension vector to be serialized, returns dataOut as the
%   serialized value of dataIn.
%   validIn indicates the dataIn is valid or not startOut is 'logical high'
%   at the beginning of each streamed vector's out.
%   validOut is 'logical high' when dataOut is valid. i.e. logical low
%   during the idle cycles
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   serializer1D methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create serializer1D object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset serializer1D states
%
%   serializer1D properties:
%
%   Ratio      - Defines the input vector size divided by output vector size
%   IdleCycles - Defines the number of idle cycles added at the end of each streamed vector's out
%
%   % EXAMPLE:
%   ser = hdl.serializer1D('Ratio', 5);
%   for idx=1:5
%       ser(1:5, true) % output is 1 to 5
%   end
%    
%   See also hdl.serializer1D, hdl.Delay

%#codegen
%#ok<*EMCLS>

%   Copyright 2013-2024 The MathWorks, Inc.

    properties (Nontunable)
        % Ratio of Input Vector Size/Output Vector Size
        %   Specify the serialization ratio, which is the input vector size
        %   divided by output vector size. The default value of this
        %   property is 1.
        Ratio(1,1) {mustBeInteger, mustBeGreaterThan(Ratio,0)}  = 1;
        
        % IdleCycles Idle Cycles 
        %   Specify the Idle Cycles, which is the number of idle cycles
        %   added at the end of each streamed vector's out. The default
        %   value of this property is 0.
        IdleCycles(1,1) {mustBeInteger, mustBeGreaterThanOrEqual(IdleCycles,0)} = 0;
    end  
    
    properties (Access = private)
        pCnt
        pMatrixBuffer
        pDataInValid
    end
    
    methods
        function obj = serializer1D(varargin)
            coder.allowpcode('plain');
            coder.internal.allowHalfInputs;
            obj.pCnt = int32(0);
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods (Access=protected)  
        function [dataOut, startOut, validOut] = stepImpl(obj, dataIn, validIn)
            
            dataInLen = length(dataIn);
            dataOutLen = dataInLen/obj.Ratio;
            dataOutCol = obj.Ratio;
            
            if obj.pCnt == 0
                obj.pDataInValid = validIn;
            end
            
            if obj.Ratio == 1
                dataOut = dataIn;
            else
                if obj.pCnt == 0
                    % Create output
                    dataIntemp = reshape (dataIn, 1, dataInLen);
                    dataInBegin = dataIntemp(1: dataOutLen).';
                    dataOut =  dataInBegin;

                    % update buffer
                    dataInToLoad = dataIntemp(dataOutLen + 1: end);
                    obj.pMatrixBuffer = reshape(dataInToLoad,  dataOutLen, dataOutCol-1);
                else
                    % create output using buffered data
                    if obj.pCnt > size(obj.pMatrixBuffer, 2)
                        % Because of idle cycles count can be more than
                        % size of buffer
                        dataOut =  obj.pMatrixBuffer(:, end);
                    else
                        dataOut =  obj.pMatrixBuffer(:, obj.pCnt);
                    end
                end
            end

            startOut = ((obj.pCnt == 0) && obj.pDataInValid);
            validOut = obj.pDataInValid && (obj.pCnt < obj.Ratio);
            
            % update counter
            if obj.pCnt == int32(obj.Ratio + obj.IdleCycles - 1)
                obj.pCnt = int32(0);
            else
                obj.pCnt = obj.pCnt + int32(1);
            end
        end
        
        function icon = getIconImpl(~)
            icon = sprintf('Serializer\n1D');
        end
          
        function resetImpl(obj)
            obj.pCnt = int32(0); 
        end
        
        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            if isLocked(obj)
                s.pCnt = obj.pCnt;
                s.pMatrixBuffer = obj.pMatrixBuffer;
                s.pDataInValid = obj.pDataInValid;
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            if wasLocked
                obj.pCnt = s.pCnt;
                obj.pMatrixBuffer = s.pMatrixBuffer;
                obj.pDataInValid = s.pDataInValid;
            end
            % Call the base class method
            loadObjectImpl@matlab.System(obj, s);
        end
        
        function setupImpl(obj,dataIn, validIn)  
            if isempty(coder.target) || ~eml_ambiguous_types
                %validate control signals
                validateattributes(validIn,   {'logical'},{'scalar'},'','validIn');
            end 
            
            obj.pCnt = int32(0); 
            obj.pDataInValid = true;   %true by default
            
            dataInLen = length(dataIn);

            coder.internal.errorIf((mod(dataInLen, obj.Ratio) ~= 0),...
                'hdlsllib:hdlsllib:InvalidSerRatio', 'Serializer1D');

            dataOutLen = dataInLen/obj.Ratio;  
            dataOutCol = obj.Ratio;

            if isenum(dataIn)
                obj.pMatrixBuffer = repmat(dataIn(1), dataOutLen,dataOutCol - 1);
            else    
                obj.pMatrixBuffer = cast(zeros(dataOutLen, dataOutCol - 1), 'like', dataIn);
            end
        end

        function varargout = getOutputSizeImpl(obj)
            a = propagatedInputSize(obj,1);
            if a(1) >= a(2)
                dataInLen = a(1);
                coder.internal.errorIf((a(2) ~= 1),...
                'hdlsllib:hdlsllib:InputVector');
            else
                dataInLen = a(2);
                coder.internal.errorIf((a(1) ~= 1),...
                'hdlsllib:hdlsllib:InputVector');
            end
            
            coder.internal.errorIf((mod(dataInLen, obj.Ratio) ~= 0),...
                'hdlsllib:hdlsllib:InvalidSerRatio', 'Serializer1D');
            
            dataOutLen = dataInLen/obj.Ratio; 

            varargout{1} = dataOutLen;
            varargout{2} = 1;
            varargout{3} = 1;
        end
        
        function varargout = getOutputDataTypeImpl(obj)
 	        varargout{1} = propagatedInputDataType(obj,1);
            varargout{2} = 'logical';
            varargout{3} = 'logical';
 	    end
        
        function varargout = isOutputFixedSizeImpl(obj)
  	        varargout{1} = propagatedInputFixedSize(obj, 1);
            varargout{2} = true;
            varargout{3} = true;
        end
        
        function varargout = isOutputComplexImpl(obj)  
            varargout{1} = propagatedInputComplexity(obj, 1);
            varargout{2} = false;
            varargout{3} = false;
        end
        
        function modes = getExecutionSemanticsImpl(~)
            % supported semantics
            modes = {'Classic', 'Synchronous'};
        end
    end
    
    methods (Access=protected)
        function supported = supportsMultipleInstanceImpl(~)
            % Support in For Each Subsystem
            supported = true;
        end
    end
end

% LocalWords:  DSe Ser Intemp hdlcoder hdlsllib
