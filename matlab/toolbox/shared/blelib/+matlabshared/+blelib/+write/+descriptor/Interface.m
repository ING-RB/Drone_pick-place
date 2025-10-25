classdef Interface < handle
%INTERFACE - Abstract interface class defining required methods for all
%descriptor interfaces that support write operation
    
% Copyright 2019 The MathWorks, Inc.

    methods(Abstract)
        write(obj, client, varargin)
    end
end