classdef altimeterSensor< fusion.internal.AltimeterSensorBase & fusion.internal.UnitDisplayer
%ALTIMETERSENSOR Simulate altimeter
%   ALTIMETER = ALTIMETERSENSOR returns a System object, ALTIMETER, that
%   simulates altimeter readings.
%
%   ALTIMETER = ALTIMETERSENSOR('ReferenceFrame', RF) returns an 
%   ALTIMETERSENSOR System object that simulates altimeter readings 
%   relative to the reference frame RF. Specify the reference frame as 
%   'NED' (North-East-Down) or 'ENU' (East-North-Up). The default value is 
%   'NED'.
%
%   ALTIMETER = ALTIMETERSENSOR(..., 'Name', Value, ...) returns an
%   ALTIMETERSENSOR System object with each specified property name set to
%   the specified value. You can specify additional name-value pair
%   arguments in any order as (Name1,Value1,...,NameN, ValueN).
%
%   Step method syntax:
%
%   ALT = step(ALTIMETER, POS) computes an altimeter sensor altitude 
%   reading from the position (POS) input.
%
%   The input to ALTIMETERSENSOR is defined as follows:
%
%       POS       Position of the altimeter sensor in the local navigation
%                 coordinate system specified as a real finite N-by-3 array
%                 in meters. N is the number of samples in the current
%                 frame.
%
%   The output of ALTIMETERSENSOR is defined as follows:
%
%       ALT       Altitude of the altimeter sensor relative to the local
%                 navigation coordinate system origin returned as a real
%                 finite N-by-1 array in meters. N is the number of samples
%                 in the current frame.
%
%   Either single or double datatypes are supported for the input to 
%   ALTIMETERSENSOR. The output has the same datatype as the input.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   ALTIMETERSENSOR methods:
%
%   step               - See above description for use of this method
%   release            - Allow property value and input characteristics to 
%                        change, and release ALTIMETERSENSOR resources
%   clone              - Create ALTIMETERSENSOR object with same property 
%                        values
%   isLocked           - Display locked status (logical)
%   <a href="matlab:help matlab.System/reset   ">reset</a>              - Reset the states of the ALTIMETERSENSOR
%
%   ALTIMETERSENSOR properties:
%
%   SampleRate         - Sampling rate of sensor (Hz)
%   ConstantBias       - Constant offset bias (m)
%   NoiseDensity       - Power spectral density of sensor noise
%                        (m/sqrt(Hz))
%   BiasInstability    - Instability of the bias offset (m)
%   DecayFactor        - Bias instability correlation decay factor
%   RandomStream       - Source of random number stream
%   Seed               - Initial seed of mt19937ar random number
%
%   % EXAMPLE: Generate noisy altimeter data from stationary input.
% 
%   Fs = 1;
%   numSamples = 1000;
%   t = 0:1/Fs:(numSamples-1)/Fs;
% 
%   altimeter = altimeterSensor('SampleRate', Fs, 'NoiseDensity', 0.05);
% 
%   pos = zeros(numSamples, 3);
% 
%   altMeas = altimeter(pos);
% 
%   plot(t, altMeas)
%   title('Altitude')
%   xlabel('s')
%   ylabel('m')
%
%   See also IMUSENSOR, GPSSENSOR, INSSENSOR

 
%   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=altimeterSensor
        end

        function out=displayScalarObject(~) %#ok<STOUT>
        end

    end
end
