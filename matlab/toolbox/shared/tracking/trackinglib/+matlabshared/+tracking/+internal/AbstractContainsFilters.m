classdef (Abstract) AbstractContainsFilters < handle
%AbstractContainsFilters  Interface definition for classes that hold tracking filters
%
% The AbstractContainsFilters is an abstract class that provide access to
% certain tracking filter methods. Trackers and multi-model systems must
% inherit from this class to gain access to the following methods:
%     sync(filter,filter2);
%     nullify(filter);
%     name = modelName(filter);
%
% See also: matlabshared.tracking.internal.AbstractTrackingFilter

%   Copyright 2018 The MathWorks, Inc.

%#codegen
end