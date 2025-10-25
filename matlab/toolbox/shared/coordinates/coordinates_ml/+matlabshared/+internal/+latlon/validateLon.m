function validateLon(lon, flag)
%This function is for internal use only. It may be removed in the future.

%VALIDATELON throws an error if the passed longitude value is out of bounds

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen
    if (any(lon>180) || any(lon<-180)) && flag==0
        coder.internal.error("shared_coordinates:latlonconv:Lon0OutOfRange");
    elseif (any(lon>180) || any(lon<-180)) && flag==1
        coder.internal.error("shared_coordinates:latlonconv:LonOutOfRange");
    end
end
