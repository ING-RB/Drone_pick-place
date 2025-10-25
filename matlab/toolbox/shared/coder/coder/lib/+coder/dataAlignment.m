function dataAlignment(varargin)
%DATAALIGNMENT Specify a data alignment value to attach to a variable.
%
%   CODER.DATAALIGNMENT('NAME', VALUE) Requests that the variable
%   named NAME should be aligned along the byte-boundary specified by 
%   VALUE. The first argument must be a constant character vector that has 
%   the variable's name. The second value must be an integral value in the
%   range [2, 128] , both included. The argument NAME must refer to a
%   global variable or an Input/Output variable declared in the function 
%   containing the CODER.DATAALIGNMENT specification.
%   
%   Example: 
%     Make global variable 'x' have a data alignment boundary of 8 bytes:
%
%     global x
%     coder.dataAlignment('x',8);
%    
%   This is a code generation function.  It has no effect in MATLAB.
%

%   Copyright 2016-2019 The MathWorks, Inc.
end
