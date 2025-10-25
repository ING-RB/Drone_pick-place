classdef (StrictDefaults,Hidden) deserializer1D < matlab.System
%deserializer1D One dimension deserializer
%   hdl1DDs = hdl.deserializer1D returns a system object hdl1DDs, and
%   performs conversion of vector or a stream of scalar inputs (faster rate)
%   to a larger size vector (lower rate) outputs.
%
%  Step method syntax:
%
%  [dataOut, validOut] = step(obj, dataIn, startIn, validIn)
%   dataIn is a scalar or one dimension vector, and a group (determined by
%   Ratio) of dataIn will be deserialized into a larger sized vector
%   dataOut. validIn is 'logical high' when dataIn is valid input. By
%   default, validIn is 'logical high' startIn is 'logical high' when
%   dataIn will be deserialized at the very beginning of dataOut. By
%   default, startIn is 'logical high' at the first cycle and then after
%   each (Ratio + IdleCycles) cycles validOut is 'logical high' when
%   dataOut is valid.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   deserializer1D methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create deserializer1D object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset deserializer1D states
%
%   deserializer1D properties:
%
%   Ratio      - Defines the output vector size divided by input vector size
%   IdleCycles - Define the number of idle cycles at the end of each dataIn group to be deserialized
%   InitialCondition - Initial values for output
%   StartInPortEnb   - Start of input enable
%   ValidInPortEnb   - Valid inport enable
%
%   Rate transition param = Ratio + IdleCycles
%   when inputs are conflict among Idlecycles, startIn and validIn
%       Idle cycles only affects the rate transition param  
%            (such decision may cause data loss if idle cycles is long and dataIn
%             keeps high. Users should make sure the time sequenced correction of input signals)
%       dataIn is collected when validIn is high and buffer is not overflow
%       (which happens when startIn is used and startIn is not high for a long time while valid is high)
%       startIn means reset of buffer and start getting the first element.
%       If previous vector is not collected sufficiently, do output zeros and is not considered as valid output
%            If startIn is high and validIn is low, we should not start collecting the dataIn
%
%   % EXAMPLE:
%   deSer = hdl.deserializer1D('Ratio', 5);
%   for idx=1:5
%       deSer(idx, true, true);
%   end
%   deSer(6, true, true) % output is (1:5)'
%    
%   See also hdl.serializer1D, hdl.Delay

%#codegen
%#ok<*EMCLS>

%   Copyright 2013-2024 The MathWorks, Inc.
    
    properties (Nontunable)
        % Ratio of Output Vector Size/Input Vector Size
        % Specify the deserialization ratio, which is the output vector size divided by input vector size. 
        Ratio(1,1) {mustBeInteger, mustBeGreaterThan(Ratio,0)}  = 1;
        
        % IdleCycles Idle Cycles 
        % Specify the Idle Cycles, which is the number of idle cycles at the end of each dataIn group to be deserialized.  
        IdleCycles(1,1) {mustBeInteger, mustBeGreaterThanOrEqual(IdleCycles,0)} = 0;
        
        % Initial condition
        % Initial value in the first slow cycle's output
        InitialCondition(1,1) {mustBeNumeric} = 0;
    
        % StartInPortEnb startIn
        % Specify whether the startIn Port is enabled in mask
        StartInPortEnb(1, 1) logical = false;
        
        % ValidInPortEnb validIn
        % Specify whether the validIn Port is enabled in mask
        ValidInPortEnb(1, 1) logical = false;
    end

    properties (Access = private)
        pCnt
        pCntValidOut
        pMatrixBuffer
        pDataBuffer
        pValidOutBuffer
        pStartsCollect
    end
    
    methods
        function obj = deserializer1D(varargin)
            coder.allowpcode('plain');
            coder.internal.allowHalfInputs;
            obj.pCnt = int32(0);
            obj.pCntValidOut = int32(0);
            obj.pValidOutBuffer  = false;
            obj.pStartsCollect = false;
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    methods (Access=protected) 
        function [dataOut, validOut] = outputImpl(obj, dataIn, startIn, validIn) %#ok<INUSD>
            dataInLen = length(dataIn);
            dataOutLen = dataInLen * obj.Ratio; 

            % output and flush the buffer
            if obj.pCntValidOut == int32(obj.Ratio + obj.IdleCycles)
                obj.pCntValidOut = int32(0);
                obj.pValidOutBuffer = false;
            end
            
            if obj.pCnt == int32(obj.Ratio)
                obj.pDataBuffer = reshape(obj.pMatrixBuffer, 1 ,dataOutLen);
                obj.pValidOutBuffer = true;
                obj.pCntValidOut = int32(0);
                if isenum(dataIn)
                    obj.pMatrixBuffer = repmat(obj.InitialCondition, dataInLen, obj.Ratio);
                else
                    obj.pMatrixBuffer = cast(repmat(obj.InitialCondition, dataInLen, obj.Ratio), 'like', dataIn);
                end
            end
            
            dataOut = obj.pDataBuffer.';
            
            validOut = obj.pValidOutBuffer;
        end
        
        function updateImpl(obj, dataIn, startIn, validIn)
            dataInLen = length(dataIn);
            if (~obj.ValidInPortEnb && obj.StartInPortEnb && startIn) ||  ...
               (obj.ValidInPortEnb && obj.StartInPortEnb && startIn && validIn)
                if (obj.pCnt > int32(0)) &&  (obj.pCnt < int32(obj.Ratio))
                    %when it's startIn, but previous group of data is not
                    %fully collected. We clear the buffer and do not
                    %consider previously collected data as valid output
                    if isenum(dataIn)
                        obj.pMatrixBuffer = repmat(obj.InitialCondition, dataInLen, obj.Ratio);
                    else
                        obj.pMatrixBuffer = cast(repmat(obj.InitialCondition, dataInLen, obj.Ratio), 'like', dataIn);
                    end
                end
            end
            
            if (obj.StartInPortEnb && startIn)||( ~obj.StartInPortEnb && obj.ValidInPortEnb && validIn)
                 obj.pStartsCollect = true;
            end
            
             % clear counter
            if ~obj.ValidInPortEnb && ~obj.StartInPortEnb
                if obj.pCnt == int32(obj.Ratio + obj.IdleCycles)
                    obj.pCnt = int32(0);
                end
            elseif ~obj.ValidInPortEnb && obj.StartInPortEnb && startIn
                obj.pCnt = int32(0);
            elseif obj.ValidInPortEnb && ~obj.StartInPortEnb
                if obj.pCnt == int32(obj.Ratio)
                    %when validIn is used, the counter is determined only
                    %by the valid In, and idle cycles only affect the rate
                    %transition factor
                    obj.pCnt = int32(0);
                end
            elseif obj.ValidInPortEnb && obj.StartInPortEnb && startIn && validIn
                obj.pCnt = int32(0);
            end
            
             % counter increase
            if ~obj.ValidInPortEnb
                if ~obj.StartInPortEnb || (obj.StartInPortEnb && obj.pStartsCollect)
                    obj.pCnt = obj.pCnt + int32(1);
                    if obj.pCnt <= int32(obj.Ratio)
                        dataInTemp = reshape (dataIn, dataInLen, 1);
                        obj.pMatrixBuffer (:, obj.pCnt) = dataInTemp;
                    end
                end
            else
                %when valid is used, validIn serves as enable of obj.pCnt
                if validIn && (obj.pCnt <= int32(obj.Ratio))&& obj.pStartsCollect
                    obj.pCnt = obj.pCnt + int32(1);
                    if obj.pCnt <= int32(obj.Ratio)
                        dataInTemp = reshape (dataIn, dataInLen, 1);
                        obj.pMatrixBuffer (:, obj.pCnt) = dataInTemp;
                    end
                elseif ~validIn && (obj.pCnt == int32(obj.Ratio))
                    obj.pCnt = obj.pCnt + int32(1);
                end
            end            

            if obj.pValidOutBuffer
                obj.pCntValidOut = obj.pCntValidOut + int32(1);
            end
        end
        
        function [flag1, flag2, flag3] = isInputDirectFeedthroughImpl(obj, dataIn, startIn, validIn) %#ok<INUSD>
            flag1 = false;
            flag2 = false;
            flag3 = false;
        end   % prevent algebraic loop

        function icon = getIconImpl(~)
            icon = sprintf('Deserializer\n1D');
        end
        
        function resetImpl(obj)
            obj.pCnt = int32(0); 
            obj.pCntValidOut = int32(0);
            obj.pValidOutBuffer = false;
            obj.pStartsCollect = false;
        end
        
        function setupImpl(obj,dataIn, startIn, validIn)   
            if isempty(coder.target) || ~eml_ambiguous_types
                %validate control signals
                validateattributes(startIn, {'logical'},{'scalar'},'','startIn');
                validateattributes(validIn, {'logical'},{'scalar'},'','validIn');
            end 
            
            obj.pCnt = int32(0); 
            obj.pCntValidOut = int32(0);
            obj.pValidOutBuffer = false;
            obj.pStartsCollect = false;
            
            dataInLen = length(dataIn);
            dataOutLen = dataInLen * obj.Ratio;
            if isenum(dataIn)
                obj.pMatrixBuffer = repmat(obj.InitialCondition, dataInLen, obj.Ratio);
                obj.pDataBuffer = repmat(obj.InitialCondition, 1, dataOutLen);
            else
                obj.pMatrixBuffer = cast(repmat(obj.InitialCondition, dataInLen, obj.Ratio), 'like', dataIn);
                obj.pDataBuffer = cast(repmat(obj.InitialCondition, 1, dataOutLen), 'like', dataIn);
            end
        end % setupImpl
        
        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            if isLocked(obj)
                s.pCnt = obj.pCnt;
                s.pCntValidOut = obj.pCntValidOut;
                s.pMatrixBuffer = obj.pMatrixBuffer;
                s.pDataBuffer = obj.pDataBuffer;
                s.pValidOutBuffer = obj.pValidOutBuffer;
                s.pStartsCollect = obj.pStartsCollect;
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            if wasLocked
                obj.pCnt = s.pCnt;
                obj.pCntValidOut = s.pCntValidOut;
                obj.pMatrixBuffer = s.pMatrixBuffer;
                obj.pDataBuffer = s.pDataBuffer;
                obj.pValidOutBuffer = s.pValidOutBuffer;
                obj.pStartsCollect  = s.pStartsCollect;
            end
            % Call the base class method
            loadObjectImpl@matlab.System(obj, s);
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
            dataOutLen = dataInLen * obj.Ratio; 

            varargout{1} = dataOutLen;
            varargout{2} = 1;
        end
        
        function varargout = getOutputDataTypeImpl(obj)
 	        varargout{1} = propagatedInputDataType(obj,1);
            varargout{2} = 'logical';
 	    end
        
        function varargout = isOutputFixedSizeImpl(obj)
  	        varargout{1} = propagatedInputFixedSize(obj, 1);
            varargout{2} = true;
        end
        
        function varargout = isOutputComplexImpl(obj)  
            varargout{1} = propagatedInputComplexity(obj, 1);
            varargout{2} = false;
        end
        
        function modes = getExecutionSemanticsImpl(~)
            % supported semantics
            modes = {'Classic', 'Synchronous'};
        end % getExecutionSemanticsImpl
    end
    
    methods (Access=protected)
        function supported = supportsMultipleInstanceImpl(~)
            % Support in For Each Subsystem
            supported = true;
        end
    end    
end

% LocalWords:  DDs Idlecycles Enb hdlcoder hdlsllib
