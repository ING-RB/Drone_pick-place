classdef (Abstract) BindingDestination < handle
    %BINDINGDESTINATION Interface for a binding destination

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        setData(obj, varargin)
        start(obj, binding)
        stop(obj, binding)
    end
end

