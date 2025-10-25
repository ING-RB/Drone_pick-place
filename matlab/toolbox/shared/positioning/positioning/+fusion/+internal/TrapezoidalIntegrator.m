classdef (Hidden) TrapezoidalIntegrator < matlab.System
    %TRAPEZOIDALINTEGRATOR Trapezoidal Integration
    %   This class is for internal use only. It may be removed in the future.
    %   
    % INT = TRAPEZOIDALINTEGRATOR returns TrapezoidalIntegrator System
    % object INT, for performing trapezoidal integration of the input signal. 
    %
    % INT = TRAPEZOIDALINTEGRTOR('PropertyName', PropertyValue, ...) returns
    % a TrapezoidalIntegrator, with each specified property set to a
    % specified value.
    %
    %   Step method syntax:
    %
    %   X = step(INT, XDERIV) integrates the data in XDERIV, along the
    %   columns, to produce the output X.
    %
    %   System objects may be called directly like a function instead of
    %   using the step method. For example, y = step(obj, x) and y = obj(x)
    %   are equivalent.
    %
    %   TRAPEZOIDALINTEGRATOR  methods:
    %
    %   step                - See above description for use of this method
    %   release             - Allow changes to non-tunable properties
    %                         values and input characteristics
    %   clone               - Create an TRAPEZOIDALINTEGRATOR object with 
    %                         the same property values and internal states
    %   isLocked            - Locked status (logical)
    %   reset               - Reset the internal states to initial
    %                         conditions
    %
    %   TRAPEZOIDALINTEGRATOR properties:
    %   
    %   SampleRate          - Sample rate of data from sensor
    %   InitialValue        - Initial value of the integrator
    %

    %   Copyright 2018-2019 The MathWorks, Inc.
    %

%#codegen

    % Public
    properties (Nontunable)

        %InitialValue Initial value of the integrator
        %   Specify the initial value of the integrator. The InitialValue
        %   property is a 1-by-3 vector. Each column corresponds to the
        %   initial value of an integrator.
        InitialValue = [0 0 0];
    end
    
    properties(Access = private)
        pPrev
        pInputPrototype
    end
    
    methods
        function obj = TrapezoidalIntegrator(varargin)
            setProperties(obj,nargin,varargin{:})
        end


        function set.InitialValue(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real',  ...
                'nonnan', 'nonempty', 'nonsparse', 'ncols', 3, ...
                '2d'}, ...
                'set.InitialValue', 'InitialValue' );
            obj.InitialValue = val;
        end
    end

    methods(Access = protected)
        function setupImpl(obj,u, ~)
            obj.pInputPrototype = u; 
      end
        
        function y = stepImpl(obj,u, freq)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.
            y = 0.5.* (1./freq) .* (u + obj.pPrev);
            obj.pPrev = u;
        end
        
        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.pPrev = cast(obj.InitialValue, 'like', ...
                obj.pInputPrototype);
        end
    end
end
