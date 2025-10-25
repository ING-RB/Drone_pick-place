classdef (Hidden) AccelerometerSimulator < fusion.internal.IMUSensorSimulator
%   Internal class used by imuSensor. 
%
%   This class is used to calculate sensor output values based on ideal
%   input and model parameters.
% 
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2019 The MathWorks, Inc.
    
%#codegen

    properties (Constant, Hidden)
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Nontunable, Access = private)
        % Cached reference frame.
        pRefFrame;
    end
    
    methods
        % Constructor
        function obj = AccelerometerSimulator(varargin)
            obj = obj@fusion.internal.IMUSensorSimulator(varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, acceleration, ~, ~)
            setupImpl@fusion.internal.IMUSensorSimulator(obj, acceleration);
            
            obj.pRefFrame = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
        end
        
        function out = stepImpl(obj, acceleration, orientation, randNums)
            refFrame = obj.pRefFrame;
            gravAxisSign = refFrame.GravityAxisSign;
            linAccelSign = refFrame.LinAccelSign;
            gravVect = zeros(1,3);
            gravVect(refFrame.GravityIndex) = gravAxisSign;
            gravOffset = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(cast(gravVect, class(acceleration)));
            idealSensorData = linAccelSign .* acceleration + repmat(gravOffset,size(acceleration,1),1);
            out = stepImpl@fusion.internal.IMUSensorSimulator(obj, idealSensorData, orientation, randNums);
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@fusion.internal.IMUSensorSimulator(obj);

            % Save private properties. 
            if isLocked(obj)
                s.pRefFrame = obj.pRefFrame;
            end
        end

        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@fusion.internal.IMUSensorSimulator(obj, s, wasLocked)

            % Load private properties. 
            if wasLocked
                obj.pRefFrame = s.pRefFrame;
            end
        end
    end 
end
