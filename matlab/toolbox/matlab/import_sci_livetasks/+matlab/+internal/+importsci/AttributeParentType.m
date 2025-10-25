% This class is unsupported and might change or be removed without notice in a
% future version.

% This enumeration class provides classification for different types of
% attribute parents and is used for code generation for netCDF and HDF5
% import live tasks.

% Copyright 2023 The MathWorks, Inc.

classdef AttributeParentType
    enumeration
        GlobalOrGroup
        DatasetOrVariable
        Datatype % only applicable to HDF5
    end

end