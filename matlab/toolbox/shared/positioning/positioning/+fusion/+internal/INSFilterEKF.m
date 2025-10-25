classdef (Hidden) INSFilterEKF < fusion.internal.BasicEKF
%INSFilterEKF Abstract class for EKF-based classes returned by insfilter
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2021 The MathWorks, Inc.

%#codegen 
    properties
        % ReferenceLocation Reference location
        % Specify the origin of the local reference frame as a 3-element
        % row vector in geodetic coordinates (latitude, longitude, and
        % altitude). Altitude is the height above the reference ellipsoid
        % model, WGS84. The reference location is in
        % [degrees degrees meters]. The default value is [0 0 0].
        ReferenceLocation = [0 0 0];
    end
    
    methods (Abstract, Access = protected)
        pos = getPosition(obj);
        orient = getOrientation(obj);
        vel = getVelocity(obj);
    end
    
    
    methods
        function obj = INSFilterEKF
            obj = obj@fusion.internal.BasicEKF;
        end

        function set.ReferenceLocation(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','finite','numel',3}, ...
                '', ...
                'ReferenceLocation');
            validateattributes(val(1), {'double','single'}, ...
                {'>=',-90,'<=',90}, ...
                '', ...
                'Latitude');
            validateattributes(val(2), {'double','single'}, ...
                {'>=',-180,'<=',180}, ...
                '', ...
                'Longitude');
            % Ensure it is a row vector.
            obj.ReferenceLocation = val(:).';
        end
    end
    
    methods (Access = protected)
        function s = saveObject(obj)
            s.ReferenceLocation = obj.ReferenceLocation;
        end
        
        function loadObject(obj, s)
            obj.ReferenceLocation = s.ReferenceLocation;
        end
    end

    methods (Sealed)
        function [pos, orient, vel] = pose(obj, format)
        %POSE Current orientation and position estimate
        %   [POS, ORIENT, VEL] = POSE(FUSE) returns the current estimate of the pose.
        %
        %   [POS, ORIENT, VEL] = POSE(FUSE, FORMAT) returns the current estimate of the
        %   pose with ORIENT in the specified orientation format FORMAT.
        %
        %   The inputs to POSE are defined as follows:
        %
        %       FORMAT    The output orientation format. Specify the format as
        %                 either 'quaternion' for a quaternion or 'rotmat' for a
        %                 rotation matrix. The default is 'quaternion'.
        %
        %   The outputs of POSE are defined as follows:
        %
        %       POS       Position estimate in the local reference frame (NED or ENU)
        %                 specified as a real finite 3-element row vector in
        %                 meters.
        %                 
        %       ORIENT    Orientation estimate with respect to the local 
        %                 reference frame (NED or ENU) specified as a scalar
        %                 quaternion or a 3-by-3 rotation matrix. The
        %                 quaternion or rotation matrix is a frame rotation
        %                 from the local reference frame to the body reference
        %                 frame.
        %
        %       VEL       Velocity estimate in the local reference frame (NED or ENU)
        %                 specified as a real finite 3-element row vector in
        %                 meters/sec.
            
            isQuat = true;
            if (nargin > 1)
                isQuat = fusion.internal.parseOrientFormat(format, 'pose');
            end
            
            q = getOrientation(obj);
            if ~isQuat
                orient = rotmat(q, 'frame');
            else
                orient = q;
            end
            
            pos = getPosition(obj);
            vel = getVelocity(obj);
        end
    end
    
end
