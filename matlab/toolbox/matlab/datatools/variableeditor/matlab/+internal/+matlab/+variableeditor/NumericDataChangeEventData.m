% This class is unsupported and might change or be removed without
% notice in a future version.

% NumericDataChangeEventData Published when data changes for numeric
% data types (For e.g on slice changes for ND Arrays)

% Copyright 2023 The MathWorks, Inc.


classdef NumericDataChangeEventData < internal.matlab.datatoolsservices.data.DataChangeEventData

    properties
        Slice string = []
        UserAction string = ""
    end
end