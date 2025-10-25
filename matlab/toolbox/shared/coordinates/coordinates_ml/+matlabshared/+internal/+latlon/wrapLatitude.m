function [lat, lon]=wrapLatitude(lat, lon)
%This function is for internal use only. It may be removed in the future.

%WRAPLATITUDE internal function to check and fix angle wrapping in
% latitude and longitude if needed.

%   Copyright 2020 The MathWorks, Inc.

%#codegen
    pideg=180;
    flat = abs(lat);
    idx = flat>pideg;
    if any(idx)
        % Below line to avoid logical indexing (g2437010)
		% Desired behavior:
		% lat(flat>pideg) = mod(lat(flat>pideg)+pideg,2*pideg)-pideg;
        lat = lat .* (~idx) + (mod(lat.*idx+pideg, 2*pideg)-pideg).*idx;
        flat = abs(lat);
    end

    % Determine if any latitudes need to be wrapped
    idx = flat>pideg/2;

    if any(idx)
        % Adjustments for -90 to 90
        flat = abs(lat);
        latp2 = flat>pideg/2;
        
        % Below line to avoid logical indexing (g2437010)
		% Desired behavior:
		% lon(idx) = lon(idx) + pideg;
        % lat(latp2) = sign(lat(latp2)).*(pideg/2-(flat(latp2)-pideg/2));
		lon = lon + pideg*idx;
        lat = lat.*(~latp2) + sign(lat.*latp2).*(pideg/2-(flat.*latp2-pideg/2)).*latp2;
    end
end
