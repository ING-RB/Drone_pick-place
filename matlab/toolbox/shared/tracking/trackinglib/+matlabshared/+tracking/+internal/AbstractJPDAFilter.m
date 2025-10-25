classdef (Abstract) AbstractJPDAFilter < handle
%AbstractJPDAFilter Interface definition for filters to support trackerJPDA
%
% The AbstractJPDAFilter is a mixin abstract class that defines the
% interface that every tracking filter must implement to work with
% trackerJPDA. It adds the correctjpda method requirement to the interface
% required by the AbstractTrackingFilter interface.
%
% The following method must be implemented by any JPDA filter:
%   Public methods:
%     [x_corr,P_corr] = correctjpda(filter, z, beta, varargin);
%
% See also: matlabshared.tracking.internal.AbstractTrackingFilter

%   Copyright 2018-2019 The MathWorks, Inc.

methods(Abstract)
    [x_corr,P_corr] = correctjpda(filter, z, beta, varargin);
end

%#codegen
end