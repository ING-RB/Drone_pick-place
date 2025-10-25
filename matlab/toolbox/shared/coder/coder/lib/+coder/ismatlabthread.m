function y = ismatlabthread
%CODER.ISMATLABTHREAD Returns true if inside a thread where MATLAB Coder 
% can communicate with MATLAB, for example via extrinsic calls.
% 
%  if CODER.ISMATLABTHREAD
%
%  This is a code generation function.  In MATLAB, this will
%  always return true.

%   Copyright 2007-2019 The MathWorks, Inc.
  y = true;
