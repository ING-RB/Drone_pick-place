function [tf,lthresh,uthresh,center] = isoutlier(a,varargin)
% Syntax:
%   TF = isoutlier(A)
%   TF = isoutlier(A,METHOD)
%   TF = isoutlier(A,"percentiles",[LP UP])
%   TF = isoutlier(A,MOVMETHOD,WL)
%   TF = isoutlier(___,DIM)
%   TF = isoutlier(___,Name=Value)
%   [TF,LTHRESH,UTHRESH,CENTER] = isoutlier(___)
%
%   Name-Value Arguments:
%       SamplePoints
%       MaxNumOutliers
%       DataVariables
%       OutputFormat
%       ThresholdFactor
%
% For more information, see documentation

%   Copyright 2016-2024 The MathWorks, Inc.

[method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt] = matlab.internal.math.parseIsOutlierInput(a, 0, varargin);

if nargout > 1
    [tf,lthresh,uthresh,center] = matlab.internal.math.isoutlierInternal(a,method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt);
else
    tf = matlab.internal.math.isoutlierInternal(a,method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt);
end