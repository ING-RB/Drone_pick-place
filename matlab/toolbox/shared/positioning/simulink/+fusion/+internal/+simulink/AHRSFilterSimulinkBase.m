classdef (Hidden) AHRSFilterSimulinkBase < fusion.internal.AHRSFilterBase
%AHRSFILTERSIMULINKBASE Nontunable properties for ahrsfilter in Simulink 
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %InitialProcessNoise Covariance matrix for process noise
        %   The initial process covariance matrix accounts for the error in
        %   the process model.  Specify the initial process covariance
        %   matrix as a 12-by-12 real, finite matrix.
        InitialProcessNoise = fusion.internal.AHRSFilterBase.getInitialProcCov()      

        %DecimationFactor Decimation factor
        %   Specify the factor by which to reduce the input sensor data
        %   rate as part of the fusion algorithm. The decimation factor
        %   must be a positive integer scalar value. The number of rows of
        %   each field of the input structure must be a multiple of the
        %   decimation factor. The default value of this property is 1. 
        DecimationFactor = 1;
 
        % SampleRate Sensor sample rate
        %   Specify the sampling rate of the input sensor data in Hertz as
        %   a finite numeric scalar.
        SampleRate = 100;
    end

    methods
        function set.SampleRate(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.SampleRate', 'SampleRate' );
            obj.SampleRate = val;
        end

        function set.DecimationFactor(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'integer', 'positive', ...
                'nonsparse'}, ...
                'set.DecimationFactor', 'DecimationFactor' );
            obj.DecimationFactor = val;
        end

        function set.InitialProcessNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real','size', [12 12],'finite', ...
                'nonsparse'}, ...
                'set.InitialProcessNoise', 'InitialProcessNoise' );
            obj.InitialProcessNoise = val;
        end
    end


    
    
end
