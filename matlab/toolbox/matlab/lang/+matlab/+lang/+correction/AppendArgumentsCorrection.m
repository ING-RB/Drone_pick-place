%APPENDARGUMENTSCORRECTION  Correct error by appending missing input arguments.
%   AAC = matlab.lang.correction.AppendArgumentsCorrection(ARGUMENTS)
%   Creates a correction that will suggest appending input ARGUMENTS to
%   the function call from which the MException was thrown.
%   ARGUMENTS can be a string vector, character vector, or cell array of
%   character vectors.
%
%   Example:
%
%   % Suggest a fix when a function is called with too few input arguments.
%
%   function hello(audience)
%   if nargin < 1
%       me = MException('MATLAB:notEnoughInputs', 'Not enough input arguments.');
%       aac = matlab.lang.correction.AppendArgumentsCorrection('"world"');
%       me = me.addCorrection(aac);
%       throw(me);
%   end
%   fprintf("Hello, %s!\n", audience);
%   end
%
%   % When the HELLO function is called without input arguments, MATLAB
%   % suggests a fix.
%
%   >> hello
%   Error using hello (line 6)
%   Not enough input arguments.
%
%   Did you mean:
%   >> hello("world")
%
%   See also MException/addCorrection, Correction, 
%     ConvertToFunctionNotationCorrection, ReplaceIdentifierCorrection

%   Copyright 2018 The MathWorks, Inc.
%   Built-in function.

%{
properties
    %ARGUMENTS Input arguments to append to the original function call.
    %    The ARGUMENTS property contains the input argument text that will be
    %    appended to the original function call from which the MException was
    %    thrown.
    %
    %    See also AppendArgumentsCorrection.
    Arguments;
end
%}
