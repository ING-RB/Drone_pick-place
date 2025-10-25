function varargout = smallTallComparison(opts, fcn, smallOperand, isTallFirstArg, varargin)
%SMALLTALLCOMPARISON Helper that calls the underlying smallTallComparison
%
%   SMALLTALLCOMPARISON(fcn, smallOperand, isTallFirstArg, arg1, ...)
%   SMALLTALLCOMPARISON(opts, fcn, smallOperand, isTallFirstArg, arg1, ...)

%   Copyright 2022 The MathWorks, Inc.

% Strip out opts, fcn and smallOperand.
[opts, fcn, smallOperand, isTallFirstArg, varargin] = ...
    matlab.bigdata.internal.util.stripOptions(opts, fcn, smallOperand, isTallFirstArg, varargin{:});

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame; %#ok<NASGU>

checkIfKnownIncompatible(varargin);
[varargout{1:nargout}] = wrapUnderlyingMethod(@smallTallComparison, ...
        opts, {fcn}, smallOperand, isTallFirstArg, varargin{:});
varargout = computeElementwiseSize(varargout, varargin);
end
