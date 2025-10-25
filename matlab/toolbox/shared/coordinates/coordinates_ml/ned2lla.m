function lla = ned2lla(xyzNED, lla0, method)
%ned2lla Transform local North-East-Down coordinates to geodetic coordinates
%  lla = ned2lla(xyzNED, lla0, method) transforms the local North-East-Down (NED)
%  Cartesian coordinates, xyzNED, to geodetic coordinates, lla. Specify
%  the local NED coordinates either as a 3-element row vector or an N-by-3
%  matrix of [xNorth, yEast, zDown] in meters. Specify the origin of the
%  local NED system with the geodetic coordinates, lla0, as a 3-element
%  row vector or an N-by-3 matrix of [lat0, lon0, alt0]. The conversion
%  method is specified either as 'flat' or 'ellipsoid', to specify if earth
%  is assumed to be flat or ellipsoidal. The geodetic coordinates are
%  returned as a 3-element row vector or an N-by-3 matrix of [lat, lon, alt].
%  lat and lat0 specify the latitude in degrees. lon and lon0 specify the
%  longitude in degrees. alt and alt0 specify the altitude in meters.
%
%  Notes
%  -----
%  - The latitude and longitude values in the geodetic coordinate system
%    uses WGS84 standard.
%  - Altitude is specified as height in meters above WGS84 reference
%    ellipsoid.
%
%  Limitations of the Flat Earth approximation
%  -------------------------------------------
%   - This transformation assumes the vehicle moves in parallel to the
%     earth's surface.
%
%  - This transformation method assumes the flat Earth z-axis is normal to
%    the Earth at the initial geodetic latitude and longitude only. This
%    method has higher accuracy over small distances from the initial
%    geodetic latitude and longitude, and nearer to the equator. The
%    longitude will have higher accuracy when there are smaller variations
%    in latitude.
%
%  - Latitude values of +90 and -90 may return unexpected values because of
%    singularity at the poles.
%
%  Example:
%
%     %Define the local NED coordinates
%     xyzNED=[-4556.3, -7134.8, -2852.4];
%
%     %Define the reference geodetic coordinates
%     lla0=[46.017 7.750 1673];
%
%     %Transform from local NED to geodetic coordinates using flat earth
%     %approximation
%     lla = ned2lla(xyzNED, lla0, "flat");
%
%  See also lla2ned, lla2enu, enu2lla

% Copyright 2020 The MathWorks, Inc.

%  References
%  ----------
%  - [1] Stevens, B. L., and F. L. Lewis, Aircraft Control and Simulation,
%    Second Edition, John Wiley & Sons, New York, 2003.
%
%  - [2] Hofmann-Wellenhof, Bernhard, Herbert Lichtenegger, and James Collins.
%    Global positioning system: theory and practice. Springer Science &
%    Business Media, 2012.
%
%#codegen

    narginchk(3,3);
    validateattributes(xyzNED, {'double'}, {"real", "nonempty", "2d", "ncols", 3}, "ned2lla", 'xyzNED', 1);

    validateattributes(lla0, {'double'}, {"real", "nonempty", "2d", "ncols", 3}, "ned2lla", 'lla0', 2);

    method=validatestring(method, {'flat', 'ellipsoid'}, "ned2lla", "method", 3);

    %Verify that the inputs are within the range
    matlabshared.internal.latlon.validateLat(lla0(:,1),0);
    matlabshared.internal.latlon.validateLon(lla0(:,2),0);

    %Verify that input matrix sizes are correct
    [minSize, idx]=min([size(xyzNED,1), size(lla0,1)]);
    if minSize~=1 && size(xyzNED,1)~=size(lla0,1)
        coder.internal.error("shared_coordinates:latlonconv:IncorrectInputSize", "NED", "LLA0");
    elseif size(xyzNED,1)==size(lla0,1)
        idx=0;
    end

    if idx==1
        xyzNEDtmp=repmat(xyzNED,size(lla0,1),1);
        lla0tmp=lla0;
    elseif idx==2
        lla0tmp=repmat(lla0,size(xyzNED,1),1);
        xyzNEDtmp=xyzNED;
    else
        xyzNEDtmp=xyzNED;
        lla0tmp=lla0;
    end

    lla=nan(size(lla0tmp,1),3);

    switch method

      case "ellipsoid"
        %Transform to lat/lon/alt using [2]
        lla = fusion.internal.frames.ned2lla(xyzNEDtmp, lla0tmp);

      case "flat"
        %Transform to lat/lon/alt using [1]
        lla = matlabshared.internal.latlon.ned2llaFlat(xyzNEDtmp, lla0tmp);
    end
