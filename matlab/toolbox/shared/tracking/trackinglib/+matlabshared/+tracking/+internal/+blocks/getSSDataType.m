function dataTypeID = getSSDataType(str)
% Get "Integer Data Type ID (DTypeId)" from string for use in S-Fcns
%
% Inputs:
%    str        - 'double' or 'single'
%
% Outputs:
%    dataTypeID - Integer Data Type ID (DTypeId), see doc of ssGetInputPortDataType

%   Copyright 2017 The MathWorks, Inc.

switch str
    case 'double'
        dataTypeID = uint32(0); % SS_DOUBLE
    case 'single'
        dataTypeID = uint32(1); % SS_SINGLE
    otherwise
        assert(false);
end
end
