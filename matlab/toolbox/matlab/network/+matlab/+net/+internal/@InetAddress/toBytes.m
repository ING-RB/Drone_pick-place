function bytes = toBytes(inetAddress)
%

%   Copyright 2020 The MathWorks, Inc.

    bytes = {inetAddress.AddressBytes};
    if isscalar(inetAddress)
        bytes = bytes{1};
    end
end
