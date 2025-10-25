%RUNWITHCAPTURE single function to run, along with any name-value pairs.

%   As with evalc, display text will be captured and returned 
%   in the first output position. Exceptions occurring in fun 
%   are caught by runWithCapture and returned in the second output 
%   position. Outputs from fun are returned in the subsequent 
%   output positions.

%   [T,E,output1,...,outputN] = 
%       matlab.lang.internal.runWithCapture(fun,Name,Value)

%   fun - the function handle or function name to evaluate
%   Name, Value - optional arguments to runWithCapture
%   T - the string of text displayed from fun (defaults to a 0x1 string)
%   E - the MException that is thrown in fun (defaults to a 0x1 MException)
%   output1,...,outputN - the outputs from fun (defaults to [ ])


%   In terms of name-value pairs, for now it only supports  
%   PreserveHyperlinks (a boolean option that controls 
%   whether displayed hyperlinks are preserved in the output
%   or converted to plain text).

%   See also FEVAL and EVALC
%   Built-in function.

%   Copyright 2020-2023 The MathWorks, Inc. 
