function y = setwarningflag
%CODER.SETWARNINGFLAG Notifies the runtime system that a warning has
% occurred inside a parallel region. Returns true if this has happened
% inside a parallel thread. 
% 
%  CODER.SETWARNINGFLAG
%
%  This is a code generation function.  In MATLAB, this will always 
%  return false.

%   Copyright 2007-2019 The MathWorks, Inc.
  y = false;
