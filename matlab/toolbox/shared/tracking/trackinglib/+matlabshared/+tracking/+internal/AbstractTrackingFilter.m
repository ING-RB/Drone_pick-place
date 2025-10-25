classdef (Abstract) AbstractTrackingFilter < handle
%AbstractTrackingFilter  Interface definition for a tracking filter
%
% The AbstractTrackingFilter is an abstract class that defines the
% interface that every tracking filter must implement. Inherit from
% this class and implment these methods to be able to work with the
% multi-target trackers.
%
% The following methods must be implemented by any tracking filter:
%   Public methods:
%     [x_pred,P_pred] = predict(filter, varargin);
%     [x_corr,P_corr] = correct(filter, z, varargin);
%     d = distance(filter, zmat, varargin);
%     l = likelihood(filter, z, varargin);
%     newFilter = clone(filter);
%   Protected methods accessible by trackers and multi-model filters:
%     sync(filter,filter2);
%     nullify(filter);
%     [stm,mm] = models(filter, dt);
%     name = modelName(filter);
%     tf = supportsVarsizeMeasurements(filter);
%
% See also: matlabshared.tracking.internal.AbstractContainsFilters, 
%           matlabshared.tracking.internal.AbstractJPDAFilter

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen
    
    methods(Abstract)
        % These methods define the exposed interface that every tracking
        % filter must implement
        [x_pred,P_pred] = predict(filter, varargin);
        [x_corr,P_corr] = correct(filter, z, varargin);
        d = distance(filter, zmat, varargin);
        l = likelihood(filter, z, varagin);
        newFilter = clone(filter);
    end
    
    % The following methods are accessible to the filter itself, to classes
    % that contain filters, and to test objects.
    methods(Abstract, Access = ...
            {?matlabshared.tracking.internal.AbstractTrackingFilter, ...
            ?matlabshared.tracking.internal.AbstractContainsFilters, ...
            ?matlab.unittest.TestCase})
        sync(filter, filter2);
        nullify(filter);
        name = modelName(filter);
        [stm,mm] = models(filter, dt);
    end
    methods (Access = ...
            {?matlabshared.tracking.internal.AbstractTrackingFilter, ...
            ?matlabshared.tracking.internal.AbstractContainsFilters, ...
            ?matlab.unittest.TestCase})
        function tf = supportsVarsizeMeasurements(~)
            % Returns whether the filter supports variable-sized
            % measurements in the tracker. This is the default
            % implementation that returns false.
            tf = false;
        end
    end
end