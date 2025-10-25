classdef (HandleCompatible) INSPluginCommon < handle
%INSPLUGINCOMMON Mixin of common functions for plugins

%   Copyright 2021 The MathWorks, Inc.


    methods (Abstract, Access = {?positioning.internal.insEKFBase, ?positioning.internal.INSPluginCommon}) 
        n = defaultName(obj)
    end
end
