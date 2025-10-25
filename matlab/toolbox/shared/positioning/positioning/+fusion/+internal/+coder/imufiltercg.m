classdef (Hidden) imufiltercg < fusion.internal.IMUFilterMATLABBase
%IMUFILTERCG - Codegen class for imufilter
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = imufiltercg(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end 
end
