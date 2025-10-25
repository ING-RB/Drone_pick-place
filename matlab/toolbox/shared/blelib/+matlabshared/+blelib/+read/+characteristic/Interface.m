classdef Interface < handle
%INTERFACE - Abstract base class defining required methods for all
%classes that support read operation
    
% Copyright 2019 The MathWorks, Inc.

    methods(Abstract)
        [value, timestamp] = read(obj, client, varargin)
        fcn = getDataAvailableFcn(obj)
        setDataAvailableFcn(obj, client, fcn)
        subscribe(obj, client, usercalled, varargin)
        unsubscribe(obj, client)
        displayDataAvailableFcn(obj)
        resetSubscription(obj, client)
    end
end