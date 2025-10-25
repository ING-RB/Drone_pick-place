classdef (Hidden,HandleCompatible) CoverageFormatMixin < matlab.unittest.internal.mixin.NameValueMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2017-2021 The MathWorks, Inc.
    properties (Hidden,Access = protected)
        % Format - a matlab.unittest.plugins.codecoverage.CoverageFormat instance.
        % Stores code coverage report format.
        Format matlab.unittest.plugins.codecoverage.CoverageFormat
    end
end

