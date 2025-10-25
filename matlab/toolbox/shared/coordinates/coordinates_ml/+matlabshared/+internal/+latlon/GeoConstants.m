classdef GeoConstants
%  GEOCONSTANTS is an internal class with properties for flattening and
%  equatorial radius of the WGS84 ellipsoid model

%   Copyright 2020 The MathWorks, Inc.
%#codegen
    properties(Constant)
        Flattening = 1/298.257223563;
        EquatorialRadius = 6378137;
    end

end
