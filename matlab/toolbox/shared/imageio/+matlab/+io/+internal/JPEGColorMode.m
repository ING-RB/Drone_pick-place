% JPEGColorMode - specify control of YCbCr/RGB conversion
%  These enumerated values should only be used when the
%  photometric interpretation is YCbCr.  Possible values include:
%
%        'Raw'      - keep in YCbCr
%        'RGB'      - convert from RGB to YCbCr

% Copyright 2018 The MathWorks, Inc.
classdef JPEGColorMode < uint32
    enumeration
        Raw(0),...
        RGB(1)
    end
end
