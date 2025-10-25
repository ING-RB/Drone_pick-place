function y = rhsSubsref(rhs,varargin)
%MATLAB Code Generation Private Function

% Helper to index into rhs which deals with MATLAB rules regarding when to
% dispatch to parenReference

%   Copyright 2016-2018 The MathWorks, Inc.
%#codegen
coder.inline('always');
y = rhs(varargin{:});

%--------------------------------------------------------------------------
