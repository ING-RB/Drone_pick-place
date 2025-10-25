function writetable(varargin)
%WRITETABLE Write table to file.
%
% This function is not supported for tall arrays.

%   Copyright 2018 The MathWorks, Inc.

error(message('MATLAB:bigdata:array:WritetableNotSupported'));
