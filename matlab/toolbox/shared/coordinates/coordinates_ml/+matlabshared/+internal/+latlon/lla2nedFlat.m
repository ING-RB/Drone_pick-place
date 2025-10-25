function xyzNED = lla2nedFlat(lla, lla0)
%This function is for internal use only. It may be removed in the future.

%LLA2NEDFLAT internal function to transform geodetic coordinates
%to local NED Cartesian coordinates using the flat earth assumption.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

% flattening
    f  = matlabshared.internal.latlon.GeoConstants.Flattening;
    % equatorial radius
    R =  matlabshared.internal.latlon.GeoConstants.EquatorialRadius;

    dLat = lla(:,1) - lla0(:,1);
    dLon = lla(:,2) - lla0(:,2);

    [dLat, dLon]=matlabshared.internal.latlon.wrapLatitude(dLat, dLon);
    dLon=matlabshared.internal.latlon.wrapLongitude(dLon);

    Rn = R./sqrt(1-(2*f-f*f)*sind(lla0(:,1)).*sind(lla0(:,1)));
    Rm = Rn.*((1-(2*f-f*f))./(1-(2*f-f*f)*sind(lla0(:,1)).*sind(lla0(:,1))));

    dNorth = dLat./atan2d(1,Rm);
    dEast = dLon./atan2d(1,Rn.*cosd(lla0(:,1)));

    xyzNED=zeros(length(dNorth),3);
    xyzNED(:,1) = dNorth;
    xyzNED(:,2) = dEast;
    xyzNED(:,3) = -lla(:,3) + lla0(:,3);
    
    % Below line to avoid logical indexing (g2437010)
    % Desired behavior:
	% xyzNED(any(isnan(xyzNED),2), :)=nan;
	nanIdx = any(isnan(xyzNED),2);
    xyzNED = xyzNED + 0./repmat(~nanIdx, 1, 3);
end
