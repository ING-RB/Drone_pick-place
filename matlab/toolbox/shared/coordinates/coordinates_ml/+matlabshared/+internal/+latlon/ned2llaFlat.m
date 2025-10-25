function lla = ned2llaFlat(xyz, lla0)
%This function is for internal use only. It may be removed in the future.

%NED2LLAFLAT internal function to transform local NED Cartesian coordinates
%to geodetic coordinates using the flat earth assumption.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

% flattening
    f  = matlabshared.internal.latlon.GeoConstants.Flattening;
    % equatorial radius
    R =  matlabshared.internal.latlon.GeoConstants.EquatorialRadius;

    dNorth = xyz(:,1);
    dEast  = xyz(:,2);
    lla=zeros(size(xyz,1),3);
    lla(:,3) = -xyz(:,3) + lla0(:,3);

    Rn = R./sqrt(1-(2*f-f*f)*sind(lla0(:,1)).*sind(lla0(:,1)));
    Rm = Rn.*((1-(2*f-f*f))./(1-(2*f-f*f)*sind(lla0(:,1)).*sind(lla0(:,1))));

    dLat = dNorth.*atan2(1,Rm);
    dLon = dEast.*atan2(1,Rn.*cosd(lla0(:,1)));

    lla(:,1) = rad2deg(dLat) + lla0(:,1);
    lla(:,2) = rad2deg(dLon) + lla0(:,2);

    
    % Below line to avoid logical indexing (g2437010)
	% Desired behavior:
	% lla(any(isnan(lla),2), :)=nan;
	nanIdx = any(isnan(lla),2);
    lla = lla + 0./repmat(~nanIdx, 1, 3);

    %Wrap output values that are outside the limit
    [lla(:,1), lla(:,2)]=matlabshared.internal.latlon.wrapLatitude(lla(:,1), lla(:,2));
    lla(:,2)=matlabshared.internal.latlon.wrapLongitude(lla(:,2));
end
