classdef Delay < matlab.System
%Delay Delay input by specified number of samples
%   DELAY = hdl.Delay returns a System object, DELAY, to delay the input by
%   a specified number of samples.
%
%   DELAY = hdl.Delay('PropertyName', PropertyValue, ...) returns a delay
%   System object, DELAY, with each specified property set to the specified
%   value.
%
%   DELAY = hdl.Delay(LEN, 'PropertyName', PropertyValue, ...) returns a
%   delay System object, DELAY, with the Length property set to LEN and
%   other specified properties set to the specified values.
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
%   Delay methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create delay object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset delay states
%
%   Delay properties:
%
%   Length                      - Amount of delay
%   InitialConditions           - Initial output of System object
%   InputProcessing             - Input processing mode for Delay
%
%   % EXAMPLE: Delay input by five samples
%   delay = hdl.Delay(5);
%   x = (1:10)';
%   y = delay(x);       % Output is [0 0 0 0 0 1 2 3 4 5]'
%
%   See also hdl.RAM

%   Copyright 2011-2022 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %Length Amount of delay
        %   Specify amount of delay to apply to the input signal. The value
        %   of this property must be a scalar non-negative integer.
        %   The default value of this property is 1.
        Length (1,1) {mustBeNonnegative, mustBeInteger, mustBeNumeric} = 1
        %InitialConditions Initial output of Delay
        %   Specify the initial output of the Delay System object. This
        %   property must be set to a scalar MATLAB built-in numeric data
        %   type. The default value of this property is 0.
        InitialConditions (1,1) {mustBeNumericOrLogical} = 0
        %InputProcessing Input processing
        %   Specify the input processing mode for the Delay System object.
        %   There are two modes: Frame-Based Processing and Sample-Based Processing.
        %   The default value of this property is FrameBasedProcessing.
        InputProcessing (1,1) hdl.InputProcessingEnum = hdl.InputProcessingEnum.FrameBasedProcessing
    end

    properties(DiscreteState)
        pState % State to hold input values
        pIndex % Circular buffer index for the state
    end

    properties(Access = private, Nontunable)
        pInitialConditions % InitialConditions cast to input data type
        pNumRows           % Number of rows in the data
    end

    methods
        function obj = Delay(varargin)
            setProperties(obj, nargin, varargin{:}, 'Length');
        end
    end

    methods(Access = protected)
        function setupImpl(obj, u)
            obj.pInitialConditions = cast(obj.InitialConditions, 'like', u);
            obj.pNumRows = size(u, 1);

            if obj.InputProcessing == hdl.InputProcessingEnum.FrameBasedProcessing
                pStateRows = obj.Length;
            else % Sample-Based Processing
                % All elements are delayed in sample-based processing, thus all of their values need to be stored
                pStateRows = obj.Length * obj.pNumRows;
            end
            obj.pState = repmat(obj.pInitialConditions, [pStateRows, size(u,2)]);
        end

        function y = outputImpl(obj, u)
            y = coder.nullcopy(u);
            if obj.InputProcessing == hdl.InputProcessingEnum.FrameBasedProcessing
                if obj.pNumRows < obj.Length
                    % Input size is less than delay length
                    if obj.pIndex + obj.pNumRows - 1 <= obj.Length
                        % We have enough data from obj.pIndex location to end
                        % of state without having to go around circular buffer
                        % to produce output
                        %
                        % Using coder.const in next line helps coder determine
                        % size of following expression
                        outSize = coder.const(obj.pNumRows-1);
                        y = obj.pState(obj.pIndex:(obj.pIndex+outSize), :);
                    else
                        % We need to get partial output from obj.pIndex
                        % location of state and remaining from the beginning of
                        % the state.
                        %
                        % Using for-loops instead of vectorized assignments
                        % helps coder to determine that it is fixed-size
                        % assignment.
                        yidx = 1;
                        for ii=obj.pIndex:obj.Length
                            y(yidx, :) = obj.pState(ii, :);
                            yidx = yidx + 1;
                        end
                        for ii=1:(obj.pNumRows-(obj.Length-obj.pIndex)-1)
                            y(yidx, :) = obj.pState(ii, :);
                            yidx = yidx + 1;
                        end
                    end
                elseif obj.pNumRows == obj.Length
                    y = obj.pState;
                else % data size is bigger than delay size
                     % We need to use part of current input to create output
                    y = [obj.pState; ...
                         u(1:(obj.pNumRows-obj.Length), :)];
                end
            else % Sample-Based Processing
                % For sample-based processing, the height of pState is always a multiple of pNumRows,
                % so we always have enough data from pIndex location to end of pState
                if obj.Length == 0
                    % pState is empty if delay is 0, errors out for nonzero
                    % input data, if there is no delay then we pass the
                    % data itself
                    y = u;
                else
                    outSize = coder.const(obj.pNumRows-1);
                    y = obj.pState(obj.pIndex:(obj.pIndex+outSize), :);
                end
            end
        end

        function updateImpl(obj,u)
            if obj.InputProcessing == hdl.InputProcessingEnum.FrameBasedProcessing
                if obj.pNumRows < obj.Length
                    if obj.pIndex + obj.pNumRows - 1 <= obj.Length
                        % Using coder.const in next line helps coder determine
                        % size of following expression
                        stateSize = coder.const(obj.pNumRows-1);
                        obj.pState(obj.pIndex:(obj.pIndex+stateSize), :) = u;
                    else
                        uidx = 1;
                        for ii=obj.pIndex:obj.Length
                            obj.pState(ii, :) = u(uidx, :);
                            uidx = uidx + 1;
                        end
                        for ii=1:(obj.pNumRows-(obj.Length-obj.pIndex)-1)
                            obj.pState(ii, :) = u(uidx, :);
                            uidx = uidx + 1;
                        end
                    end
                elseif obj.pNumRows == obj.Length
                    obj.pState = u;
                else % data size is bigger than delay size
                    obj.pState = u((obj.pNumRows-obj.Length+1):end, :);
                end
                obj.pIndex = obj.pIndex + obj.pNumRows;
                if obj.pIndex > obj.Length
                    obj.pIndex = rem(obj.pIndex, obj.Length);
                end
            else % Sample-Based Processing                
                % Store all elements in u in pState so that we can query them later

                if obj.Length ~= 0
                    % No delay, also prevents index out of bounds error due
                    % to pState being empty
                    stateSize = coder.const(obj.pNumRows-1);
                    obj.pState(obj.pIndex:(obj.pIndex+stateSize), :) = u;
                end

                % Move pIndex to the next position after updating pState
                obj.pIndex = obj.pIndex + obj.pNumRows;
                if obj.pIndex > size(obj.pState, 1)
                    obj.pIndex = 1; % reset pIndex to the start of pState if we are at the end of pState
                end
            end
        end

        function resetImpl(obj)
            obj.pState(:) = obj.pInitialConditions;
            obj.pIndex = 1;
        end

        function validateInputsImpl(~, u)
            validateattributes(u, {'numeric', 'embedded.fi', 'logical'}, ...
                    {'2d'},...
                    'hdl.Delay', 'input data', 1);
        end

        function s = saveObjectImpl(obj)
            % saveObjectImpl
            % save states & properties into output structure
            % Save the public properties
            s = saveObjectImpl@matlab.System(obj);
            % Save private properties if object is locked
            if obj.isLocked
                s.pState = obj.pState;
                s.pIndex = obj.pIndex;
                s.pInitialConditions = obj.pInitialConditions;
                s.pNumRows = obj.pNumRows;
            end
        end % saveObjectImpl

        function loadObjectImpl(obj, s, ~)
            % loadObjectImpl
            % load states & properties from input structure
            fn = fieldnames(s);
            for ii = 1:numel(fn)
                obj.(fn{ii}) = s.(fn{ii});
            end
        end
        
    end
end

