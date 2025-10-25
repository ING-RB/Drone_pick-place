function t = parenAssign(t,rhs,varargin)  %#codegen
%PARENASSIGN Subscripted assignment to a table using parentheses.

%   Copyright 2019-2021 The MathWorks, Inc.

t = parenAssignImpl(t,rhs,false,[],varargin{:});


