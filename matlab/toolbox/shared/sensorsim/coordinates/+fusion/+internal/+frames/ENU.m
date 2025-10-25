classdef (Hidden) ENU < fusion.internal.frames.AbstractReferenceFrame
%ENU - ENU specific math used by fusion algorithms
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    properties (Constant)
        % NorthIndex - which index is north
        %   In ENU north is the 2nd index.
        NorthIndex = 2;

        % EastIndex - which index is east
        %   In ENU east is the 1st index.
        EastIndex = 1;

        % NorthAxisSign - is north along the positive or negative axis
        %   In ENU, North is pointed to by the positive y-axis. So
        %   NorthAxisSign is +1 not -1.
        NorthAxisSign = 1;

        % GravityIndex - which index is gravity
        %   In ENU gravity is the 3rd index (up, z)
        GravityIndex = 3;

        % GravityAxisSign - is gravity along the positive or negative axis
        %   In ENU, Gravity is pointed to by the negative z-axis (up)
        %   axis(-1)
        GravityAxisSign = -1;

        % GravitySign - is gravity a positive or negative quantity
        %   In ENU, Gravity is a positive quantity.
        GravitySign = 1;

        % ZAxisUpSign - is the z-axis pointing up or down.
        %   In ENU, it is pointing up.
        ZAxisUpSign = 1;

        % LinAccelSign - is the linear acceleration a positive or negative
        %   quantity.
        %   In ENU, it is a negative quantity.
        LinAccelSign = -1;
    end

    methods (Static)

        function R = ecompass(a, m)
        % vectorized ecompass math.
        % m is Nx3, a is Nx3.
        % R is 3x3xN

            if isa(m, 'single') || isa(a, 'single')
                R = zeros(3,3,size(m,1), 'single');
            else
                R = zeros(3,3, size(m,1), 'double');
            end
            Rup = -a.';
            Reast = cross(m.', Rup);
            R(:,3,:) = Rup;
            R(:,2,:) = cross(Rup, Reast);
            R(:,1,:) = Reast;
            n = sqrt(sum(R.*R,1)); % norm of each column
            R = bsxfun(@rdivide, R, n);

            nanPageIdx = (any(any(isnan(R),1),2));

            for ii=1:size(R,3) % for each page
                if nanPageIdx(ii)
                    R(:,:,ii) = eye(3, 'like', m);
                end
            end
        end

        function llaMeas = frame2lla(pos, refloc)
            llaMeas = fusion.internal.frames.enu2lla(pos, refloc);
        end

        function pos = lla2frame(llaMeas, refloc)
            pos = fusion.internal.frames.lla2enu(llaMeas, refloc);
        end

        function ecefv = frame2ecefv(enuv, lat, lon)
            ecefv = fusion.internal.frames.enu2ecefv(enuv, lat, lon);
        end

        function enuv = ecef2framev(ecefv, lat, lon)
            enuv = fusion.internal.frames.ecef2enuv(ecefv, lat, lon);
        end

        function R = ecef2framerotmat(lat, lon)
            R = fusion.internal.frames.ecef2enurotmat(lat, lon);
        end
    end

end
