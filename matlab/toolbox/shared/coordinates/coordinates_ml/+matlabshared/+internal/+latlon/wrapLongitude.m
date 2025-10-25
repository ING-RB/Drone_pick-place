function lon=wrapLongitude(lon)
%This function is for internal use only. It may be removed in the future.

%WRAPLONGITUDE internal function to check and fix angle wrapping in
% longitude if needed.

%   Copyright 2020 The MathWorks, Inc.

%#codegen
    pideg=180;
    idx = lon > pideg | lon < -pideg;
    if any(idx)
        % Below line to avoid logical indexing (g2437010)
		% Desired behavior:
		% lon(idx) = rem(lon(idx),2*pideg)- (2*pideg)*fix(rem(lon(idx),2*pideg)/pideg);
        lon = lon.*(~idx) + (rem(lon.*idx,2*pideg)- (2*pideg)*fix(rem(lon.*idx,2*pideg)/pideg)).*idx;
    end
end
