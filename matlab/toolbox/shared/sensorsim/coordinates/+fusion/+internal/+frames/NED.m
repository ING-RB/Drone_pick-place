classdef (Hidden) NED < fusion.internal.frames.AbstractReferenceFrame
%NED - NED specific math used by fusion algorithms
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

    properties (Constant)
        % NorthIndex - which index is north
        %   In NED north is the 1st index.
        NorthIndex = 1

        % EastIndex - which index is east
        %   In NED east is the 2nd index.
        EastIndex = 2;

        % NorthAxisSign - is north along the positive or negative axis
        %   In NED, North is pointed to by the positive x-axis. So
        %   NorthAxisSign is +1 not -1.
        NorthAxisSign = 1;

        % GravityIndex - which index is gravity
        %   In NED gravity is the 3rd index (down, z)
        GravityIndex = 3

        % GravityAxisSign - is gravity along the positive or negative axis
        %   In NED, Gravity is pointed to by the positive z-axis (down)
        %   axis(-1)
        GravityAxisSign = 1

        % GravitySign - is gravity a positive or negative quantity
        %   In NED, Gravity is a positive quantity.
        GravitySign = 1

        % ZAxisUpSign - is the z-axis pointing up or down.
        %   In NED, it is pointing down.
        ZAxisUpSign = -1;

        % LinAccelSign - is the linear acceleration a positive or negative
        %   quantity.
        %   In NED, it is a negative quantity.
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
            Rdown = a.';
            Reast = cross(Rdown, m.');
            R(:,3,:) = Rdown;
            R(:,2,:) = Reast;
            R(:,1,:) = cross(Reast, Rdown);
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
            llaMeas = fusion.internal.frames.ned2lla(pos, refloc);
        end

        function pos = lla2frame(llaMeas, refloc)
            pos = fusion.internal.frames.lla2ned(llaMeas, refloc);
        end

        function ecefv = frame2ecefv(nedv, lat, lon)
            ecefv = fusion.internal.frames.ned2ecefv(nedv, lat, lon);
        end

        function nedv = ecef2framev(ecefv, lat, lon)
            nedv = fusion.internal.frames.ecef2nedv(ecefv, lat, lon);
        end

        function R = ecef2framerotmat(lat, lon)
            R = fusion.internal.frames.ecef2nedrotmat(lat, lon);
        end
    end

end
