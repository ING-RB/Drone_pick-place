classdef SettingValueValidator
%

%   Copyright 2019 The MathWorks, Inc.

    properties
        MinVectorSize {mustBeInteger} = [];
        MaxVectorSize {mustBeInteger} = [];
        MinValue {mustBeNumeric} = [];
        MaxValue {mustBeNumeric} = [];
        ValidStringValues string;
        MinStringSize {mustBeInteger} = [];
        MaxStringSize {mustBeInteger} = [];
        MustBeString(1,1) logical = false;
        MustBeNumeric(1,1) logical = false;
        MustBeInteger(1,1) logical = false;
    end
end
