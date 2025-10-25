classdef (Hidden) ahrsfiltercg < fusion.internal.AHRSFilterMATLABBase
%AHRSFILTERCG - Codegen class for ahrsfilter
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = ahrsfiltercg(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end 
end
