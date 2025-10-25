classdef (Hidden) ConstantValue
%CONSTANTVALUE Internal class used store constant values.  
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2020-2021 The MathWorks, Inc.

%#codegen  

    methods (Static)
        function magNED = MagneticFieldNED
            %MAGNETICFIELDNED Default magnetic field vector in microteslas
            %   in NED at 0-latitude, 0-longitude, 0-altitude.
            magNED = [27.5550 -2.4169 -16.0849];
        end
        function out = Gravity
            %GRAVITY Acceleration due to gravity in meters per second
            %   squared.
            out = 9.81;
        end
        function c = SpeedOfLight
            %SPEEDOFLIGHT Speed of light in meters per second.
            c = 299792458;
        end
    end
end
