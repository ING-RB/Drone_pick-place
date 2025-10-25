function [tf, P] = islocalmax(A, varargin)
%ISLOCALMAX   Detect local maxima in data.
%
%  TF = ISLOCALMAX(A)
%  TF = ISLOCALMAX(A,DIM)
%  TF = ISLOCALMAX(...,Name,Value)
%  [TF,P] = ISLOCALMAX(...)
%
%  Limitations:
%  1) Tall timetables are not supported.
%  2) You must specify the 'ProminenceWindow' name-value pair.
%  3) The 'MaxNumExtrema', 'MinSeparation', and 'SamplePoints' name-value
%     pairs are not supported.
%  4) The value of 'DataVariables' cannot be a function_handle.
%
%  See also ISLOCALMAX, ISLOCALMIN, TALL/SMOOTHDATA, TALL/FILLMISSING

% Copyright 2018-2020 The MathWorks, Inc.

    [tf, P] = isLocalExtrema(A, 'islocalmax', varargin{:});

end
