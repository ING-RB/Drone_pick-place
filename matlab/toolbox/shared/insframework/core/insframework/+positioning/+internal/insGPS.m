classdef insGPS < positioning.INSSensorModel
%   This class is for internal use only. It may be removed in the future. 
%INSGPS Internal GPS related functions
%   Methods in this class are not part of the public API. 
%   Customers should inherit directly from positioning.INSSensorModel

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

    properties (Abstract)
        ReferenceLocation
    end

    methods (Access = {?positioning.internal.insEKFBase,?positioning.internal.INSSensorModelBase}) 
        function n = defaultName(~)
            n = coder.const('GPS');
        end
        function [h, H] = validateAndTrimMeasurements(~, numMeas, ~, h, H)
            % Validate that the measurement is of the expected size.
            % Trim as needed
            nh = numel(h);
            % The motion model can supply 3 or 6 element outputs from measurement(). 
            % We expect the meas input to fuse/residual to be either:
            %   * 3. Just position. Always works whether or not velocity is tracked.
            %   * 6. Only works if both position and velocity are tracked
            %       and, therefore, nh == 6.
            coder.internal.assert(numMeas == 3 || (numMeas == 6 && nh == 6), ...
                'insframework:insEKF:GPSMeasSize');
            h = h(1:numMeas);
            H = H(1:numMeas,:);
        end
        function zout = convertMeasurement(sensor, filt, zin)
            % Convert position measurement based on reference location 
            zout = zin;
            rf = getReferenceFrameObject(filt);
            zout(1:3) = rf.lla2frame(zin(1:3), sensor.ReferenceLocation);    
        end
    end

    methods
        function obj = insGPS(varargin)
            if ~isempty(varargin)
                obj = matlabshared.fusionutils.internal.setProperties(obj, ...
                    nargin, varargin{:});
            end
        end
    end
    methods (Static, Hidden)
        function funhelp
            % For the FUSE and RESIDUAL functions the measurement MEAS and
            % measurement noise MNOISE for the INSGPS can have different
            % sizes depending on the motion model used.
            % 
            % If the INSGPS is used with a motion model that tracks both
            % position and velocity, like the INSMOTIONPOSE, then either:
            % * MEAS can be a 6-element vector representing position and
            %   velocity as [position velocity], and MEASNOISE is either a
            %   scalar, a 6-element array, or a 6-by-6 matrix, or
            % * MEAS can be a 3-element vector representing only position.
            %   In this case MEASNOISE is either a scalar, 3-element array
            %   or 3-by-3 matrix.
            % 
            % If the INSGPS is used with a motion model that only tracks
            % position, then MEAS must be a 3-element vector representing
            % only position and MEASNOISE is either a scalar, 3-element
            % array or 3-by-3 matrix.
            %
            % Example:
            %   gps = insGPS;
            %   filt = insEKF(gps, insMotionPose);
            %   pos = [1 2 3];
            %   vel = [0 0.1 0];
            %   posNoise = [1 1 1];
            %   velNoise = [0.1 0.1 0.1];
            %   residual(filt, gps, [pos vel], [posNoise velNoise]);
            %   fuse(filt, gps, [pos vel], blkdiag(diag(posNoise), ...
            %       diag(velNoise)));
            %   fuse(filt, gps, pos, posNoise);
            %
            %

        end
    end
end
