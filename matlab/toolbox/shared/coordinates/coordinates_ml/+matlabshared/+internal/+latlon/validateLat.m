function validateLat(lat, flag)
%This function is for internal use only. It may be removed in the future.

%VALIDATELAT throws an error if the passed latitude value is out of bounds

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen
    if (any(lat>90) || any(lat<-90)) && flag==0
        coder.internal.error("shared_coordinates:latlonconv:Lat0OutOfRange");
    elseif (any(lat>90) || any(lat<-90)) && flag==1
        coder.internal.error("shared_coordinates:latlonconv:LatOutOfRange");
    end
end
