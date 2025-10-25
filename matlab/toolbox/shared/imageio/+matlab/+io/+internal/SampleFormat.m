% SampleFormat - specifies how to interpret each pixel sample
%    This property should only be used when setting the
%    'SampleFormat' tag.  Supported enumerated values include
%
%       UInt          - default, unsigned integer data
%       Int           - two's complement signed integer data
%       IEEEFP        - IEEE floating point data
%       Void          - unsupported
%       ComplexInt    - unsupported
%       ComplexIEEEFP - unsupported

% Copyright 2018 The MathWorks, Inc.
classdef SampleFormat < uint32
    enumeration
            UInt(1), ...
            Int(2), ...
            IEEEFP(3), ...
            Void(4), ...
            ComplexInt(5), ...
            ComplexIEEEFP(6)
    end
end