classdef (Abstract) OverheadEstimator < handle
    % This class is undocumented and subject to change in a future release

    % Copyright 2018-2024 The MathWorks, Inc.        
    
    properties (SetAccess = protected)
        Overhead
    end
    
    methods (Abstract)
        estimate(estimator, meter)
    end
end