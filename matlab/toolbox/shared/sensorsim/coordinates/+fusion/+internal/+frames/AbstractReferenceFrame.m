classdef (Hidden) AbstractReferenceFrame 
% ABSTRACTREFERENCEFRAME - Defines API for fusion helpers
%   This class defines an API for reference-frame-specific math. Fusion
%   algorithms and other functions in the toolbox use classes that derive
%   from this to do a function in the NED, ENU, etc way.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen


    properties (Constant, Abstract)
        NorthIndex
        EastIndex
        NorthAxisSign
        GravityIndex
        GravityAxisSign
        GravitySign
        ZAxisUpSign
        LinAccelSign
    end
    methods (Static, Abstract)
        R = ecompass(a, m)
        llaMeas = frame2lla(pos, refloc)
        pos = lla2frame(llaMeas, refloc)
        ecefv = frame2ecefv(vec, lat, lon)
        vec = ecef2framev(ecefv, lat, lon)
        R = ecef2framerotmat(lat, lon)
    end
end
