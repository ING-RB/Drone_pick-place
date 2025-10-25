function [TF,P] = islocalmin2(A,varargin)
% Syntax:
%     TF = islocalmin2(A)
%     TF = islocalmin2(A,Name=Value)
%     [TF,P] = islocalmin2(____)
%
%     Name-Value Arguments:
%         FlatSelection
%         MaxNumExtrema
%         MinProminence
%         MinSeparation
%         ProminenceWindow
%         SamplePoints
%
% For more information, see documentation

%   Copyright 2023 The MathWorks, Inc.

if nargout == 2
    [TF,P] = matlab.internal.math.isLocalExtrema2(A, true, varargin{:});
else
    TF = matlab.internal.math.isLocalExtrema2(A, true, varargin{:});
end
end