function [tf, P] = islocalmin(A, varargin)
%ISLOCALMIN   Detect local minima in data.
%
%  TF = ISLOCALMIN(A)
%  TF = ISLOCALMIN(A,DIM)
%  TF = ISLOCALMIN(...,Name,Value)
%  [TF,P] = ISLOCALMIN(...)
%
%  Limitations:
%  1) Tall timetables are not supported.
%  2) You must specify the 'ProminenceWindow' name-value pair.
%  3) The 'MaxNumExtrema', 'MinSeparation', and 'SamplePoints' name-value
%     pairs are not supported.
%  4) The value of 'DataVariables' cannot be a function_handle.
%
%  See also ISLOCALMIN, ISLOCALMAX, TALL/SMOOTHDATA, TALL/FILLMISSING

% Copyright 2018-2020 The MathWorks, Inc.

    [tf, P] = isLocalExtrema(A, 'islocalmin', varargin{:});

end
