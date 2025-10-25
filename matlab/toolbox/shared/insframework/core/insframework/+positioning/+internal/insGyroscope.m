classdef insGyroscope < positioning.INSSensorModel
%   This class is for internal use only. It may be removed in the future. 
%INSGYROSCOPE Internal Gyroscope related functions
%   Methods in this class are not part of the public API. 
%   Customers should inherit directly from positioning.INSSensorModel

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

    methods (Access = {?positioning.internal.insEKFBase,?positioning.internal.INSSensorModelBase}) 
        function n = defaultName(~)
            n = coder.const('Gyroscope');
        end
        function [h, H] = validateAndTrimMeasurements(~, numMeas, ~, h, H)
            % Validate that the measurement is of the expected size.
            coder.internal.assert(numMeas == 3, ...
                'insframework:insEKF:MeasSize3', 'insGyroscope');
        end
    end
    methods (Static, Hidden)
        function funhelp
            % The INSGYROSCOPE requires a 3-element measurement MEAS and a
            % measurement noise MNOISE that is either a scalar, 3-element
            % array, or 3-by-3 matrix when used with the FUSE or RESIDUAL
            % functions.
            %
            % Example:
            %   gyro = insGyroscope;
            %   filt = insEKF(gyro);
            %   residual(filt, gyro, [0 0 0.1], 0.1);
            %   fuse(filt, gyro, [0 0 0.1], 0.1*eye(3));
        end
    end

end
