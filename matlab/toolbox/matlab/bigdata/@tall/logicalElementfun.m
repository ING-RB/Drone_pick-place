function varargout = logicalElementfun(opts, fcn, varargin)
%LOGICALELEMENTFUN Helper that calls the underlying logicalElementfun
%
%   LOGICALELEMENTFUN(fcn, arg1, ...)
%   LOGICALELEMENTFUN(opts, fcn, arg1, ...)

%   Copyright 2022 The MathWorks, Inc.

% Strip out opts and fcn.
[opts, fcn, varargin] = ...
    matlab.bigdata.internal.util.stripOptions(opts, fcn, varargin{:});

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame; %#ok<NASGU>

checkIfKnownIncompatible(varargin);
[varargout{1:nargout}] = wrapUnderlyingMethod(@logicalElementfun, ...
        opts, {fcn}, varargin{:});
varargout = computeElementwiseSize(varargout, varargin);
end
