function xyzNED = lla2ned(lla, lla0, method)
%lla2ned Transform geodetic coordinates to local North-East-Down coordinates
%  xyzNED = lla2ned(lla, lla0, method) transforms the geodetic coordinates, lla,
%  to local North-East-Down (NED) Cartesian coordinates, xyzNED. Specify
%  the geodetic coordinates either as a 3-element row vector or an N-by-3
%  matrix of [lat, lon, alt]. Specify the origin of the local NED system
%  with the geodetic coordinates, lla0, as a 3-element row vector or an
%  N-by-3 matrix of [lat0, lon0, alt0]. The conversion method is specified
%  either as 'flat' or 'ellipsoid', to specify if earth is assumed to be
%  flat or ellipsoidal. The local NED coordinates are returned as a
%  3-element row vector or an N-by-3 matrix of [xNorth, yEast, zDown] in
%  meters. lat and lat0 specify the latitude in degrees. lon and lon0
%  specify the longitude in degrees. alt and alt0 specify the
%  altitude in meters.
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
%     %Define the geodetic coordinates
%     lla=[45.976,7.658,4531];
%
%     %Define the reference geodetic coordinates
%     lla0=[46.017 7.750 1673];
%
%     %Transform from geodetic to local NED coordinates using flat earth
%     %approximation
%     xyzNED = lla2ned(lla, lla0, "flat");
%
%  See also lla2enu, enu2lla, ned2lla

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
    validateattributes(lla, {'double'}, {"real", "nonempty", "2d", "ncols", 3}, "lla2ned", 'lla', 1);

    validateattributes(lla0, {'double'}, {"real", "nonempty", "2d", "ncols", 3}, "lla2ned", 'lla0', 2);

    method=validatestring(method, {'flat', 'ellipsoid'}, "lla2ned", "method", 3);

    %Verify that the inputs are within the range
    matlabshared.internal.latlon.validateLat(lla0(:,1),0);
    matlabshared.internal.latlon.validateLat(lla(:,1),1);
    matlabshared.internal.latlon.validateLon(lla0(:,2),0);
    matlabshared.internal.latlon.validateLon(lla(:,2),1);

    %Verify that input matrix sizes are correct
    [minSize, idx]=min([size(lla,1), size(lla0,1)]);
    if minSize~=1 && size(lla,1)~=size(lla0,1)
        coder.internal.error("shared_coordinates:latlonconv:IncorrectInputSize", "LLA", "LLA0");
    elseif size(lla,1)==size(lla0,1)
        idx=0;
    end

    if idx==1
        llatmp=repmat(lla,size(lla0,1),1);
        lla0tmp=lla0;
    elseif idx==2
        lla0tmp=repmat(lla0,size(lla,1),1);
        llatmp=lla;
    else
        llatmp=lla;
        lla0tmp=lla0;
    end

    xyzNED=nan(size(lla0tmp,1),3);

    switch method
      case "ellipsoid"
        %Transform to xyz in NED frame using [2]
        xyzNED=fusion.internal.frames.lla2ned(llatmp, lla0tmp);
      case "flat"
        %Transform to xyz in NED frame using [1]
        xyzNED = matlabshared.internal.latlon.lla2nedFlat(llatmp, lla0tmp);
    end
