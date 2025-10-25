classdef TappedDelay < matlab.System
%TappedDelay Delay a signal and output all the delay versions
%   DELAY = hdl.TappedDelay returns a System object, DELAY, to delay the
%   input by a specified number of samples.
%
%   DELAY = hdl.TappedDelay('PropertyName', PropertyValue, ...) returns a
%   delay System object, DELAY, with each specified property set to the
%   specified value.
%
%   DELAY = hdl.TappedDelay(LEN, 'PropertyName', PropertyValue, ...)
%   returns a delay System object, DELAY, with the NumDelays property
%   set to LEN and other specified properties set to the specified values.
%
%   Step method syntax:
%
%   Y = step(DELAY, X) adds delay to input X to return output Y. Each
%   column of X is treated as an independent channel of input.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   TappedDelay methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create delay object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset delay states
%
%   TappedDelay properties:
%
%   NumDelays                  - Amount of delay
%   TapLength                  - Length of each delay element
%   InitialCondition           - Initial output of System object
%   DelayOrder                 - Order of output values
%   includeCurrent             - Include current input in the output
%
%   % EXAMPLE: Delay input by five samples
%   delay = hdl.TappedDelay(5);
%   for ii=1:5
%       delay(ii);
%   end
%   y = delay(1); % Output is [5 4 3 2 1]'
%
%   See also hdl.RAM, hdl.Delay

%   Copyright 2011-2022 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %NumDelays Number of delays
        %   Specify amount of delay to apply to the input signal. The value
        %   of this property must be a scalar non-negative integer.
        %   The default value of this property is 1.
        NumDelays (1,1) {mustBePositive, mustBeInteger, mustBeNumeric} = 4;

        %TapLength Length of each delay element
        TapLength (1,1) {mustBePositive, mustBeInteger, mustBeNumeric} = 1;

        %InitialCondition Initial output of Delay
        %   Specify the initial output of the TappedDelay System object.
        %   This property must be set to a scalar MATLAB built-in numeric
        %   data type. The default value of this property is 0.
        InitialCondition {mustBeNumericOrLogical} = 0;

        %DelayOrder Order of output values
        %   Specify the output order of the TappedDelay System object as one
        %   of ['Oldest' | 'Newest']. The default is 'Oldest'.
        DelayOrder = 'Oldest';

        %includeCurrent Include current input in the output
        %   Specify the initial output of the Delay System object. This
        %   property must be set to a scalar MATLAB built-in numeric data
        %   type. The default value of this property is 0.
        includeCurrent (1, 1) logical = false;
    end

    properties(Constant, Hidden)
        DelayOrderSet = matlab.system.StringSet( {'Oldest','Newest'} );
    end
    
    properties(DiscreteState)
        pState; % State to hold input values
    end

    properties(Access = private, Nontunable)
        pInitialCondition; % InitialCondition cast to input data type
    end

    methods
        function obj = TappedDelay(varargin)
            setProperties(obj, nargin, varargin{:}, 'NumDelays');
        end
    end

    methods(Access = protected)
        function setupImpl(obj, u)
            obj.pInitialCondition = cast(obj.InitialCondition, 'like', u);
            obj.pState = repmat(obj.pInitialCondition, [obj.NumDelays, size(u,2)]);
        end

        function y = outputImpl(obj, u)
            if obj.includeCurrent
                if strcmp(obj.DelayOrder, 'Oldest')
                    y = [flipud(obj.pState(obj.TapLength:obj.TapLength:end)); u];
                else
                    y = [u; obj.pState(obj.TapLength:obj.TapLength:end)];
                end
            else
                if strcmp(obj.DelayOrder, 'Oldest')
                    y = flipud(obj.pState(obj.TapLength:obj.TapLength:end));
                else
                    y = obj.pState(obj.TapLength:obj.TapLength:end);
                end                
            end
        end

        function updateImpl(obj,u)
            obj.pState = [u; obj.pState(1:end-1)];
        end

        function resetImpl(obj)
            obj.pState(:) = obj.pInitialCondition;
        end

        function validateInputsImpl(~, u)
            validateattributes(u, {'numeric', 'embedded.fi', 'logical'}, ...
                    {'scalar'},...
                    'hdl.TappedDelay', 'input data', 1);
        end
        
        function validatePropertiesImpl(obj)
            % A valid TapLength is positive, a factor of NumDelays, and
            % less than or equal to NumDelays
            invalidTapLength = obj.TapLength < 1 || mod(obj.NumDelays, obj.TapLength)~=0 || ...
                    obj.TapLength > obj.NumDelays;
            coder.internal.errorIf(invalidTapLength, 'hdlmllib:hdlmllib:InvalidTapLengthValue', ...
                    'IfNotConst', 'Fail');

            if any(size(obj.InitialCondition) > 1)
                % A valid InitialCondition is either a scalar or a vector,
                % but not a matrix. If it is a vector, one dimension needs
                % to match NumDelays
                dimSize = size(obj.InitialCondition);
                invalidInitialCondition = ~(any(dimSize == 1)) || dimSize(dimSize~=1) ~= obj.NumDelays;
                coder.internal.errorIf(invalidInitialCondition, 'hdmllib:hdlmllib:TapDelayICMismatch', ...
                        'IfNotConst', 'Fail');
            end
        end

        function s = saveObjectImpl(obj)
            % saveObjectImpl
            % save states & properties into output structure
            % Save the public properties
            s = saveObjectImpl@matlab.System(obj);
            % Save private properties if object is locked
            if obj.isLocked
                s.pState = obj.pState;
                s.pInitialCondition = obj.pInitialCondition;
            end
        end % saveObjectImpl

        function out = getOutputSizeImpl(obj)
            if obj.includeCurrent
                out = [(obj.NumDelays/obj.TapLength+1) 1];
            else
                out = [(obj.NumDelays/obj.TapLength) 1];
            end
        end

        function [sz,dt,cp] = getDiscreteStateSpecificationImpl(obj,~)
            % Return size, data type, and complexity of discrete-state
            % specified in name
            sz = [obj.NumDelays, 1];
            dt = propagatedInputDataType(obj, 1);
            cp = propagatedInputComplexity(obj, 1);
        end

        function loadObjectImpl(obj, s, ~)
            % loadObjectImpl
            % load states & properties from input structure
            fn = fieldnames(s);
            for ii = 1:numel(fn)
                obj.(fn{ii}) = s.(fn{ii});
            end
        end
    end

    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = "Interpreted execution";
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block
            flag = false;
        end
    end
end
