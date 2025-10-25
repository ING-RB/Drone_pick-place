function val = evalin(this,expr) 
% EVALIN Evaluate an expression in the workspace
%
 
% Copyright 2012-2014 The MathWorks, Inc.

val = this.Data.(matlab.lang.makeValidName(expr));
end
