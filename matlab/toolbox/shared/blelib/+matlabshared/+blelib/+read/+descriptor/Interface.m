classdef Interface < handle
%INTERFACE - Abstract interface class defining required methods for all
%descriptor interfaces that support read operation
    
% Copyright 2019 The MathWorks, Inc.

    methods(Abstract)
        value = read(obj, client)
    end
end