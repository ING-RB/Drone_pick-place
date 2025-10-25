function [TF,P] = islocalmax2(A,varargin)
% Syntax:
%     TF = islocalmax2(A)
%     TF = islocalmax2(A,Name=Value)
%     [TF,P] = islocalmax2(____)
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
    [TF,P] = matlab.internal.math.isLocalExtrema2(A, false, varargin{:});
else
    TF = matlab.internal.math.isLocalExtrema2(A, false, varargin{:});
end
end