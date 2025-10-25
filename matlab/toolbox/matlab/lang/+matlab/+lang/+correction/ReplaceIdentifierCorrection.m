%REPLACEIDENTIFIERCORRECTION  Fix incorrect identifier error.
%   RIC = matlab.lang.correction.ReplaceIdentifierCorrection(IDENTIFIER, REPLACEMENT)
%   creates a correction that will replace IDENTIFIER with REPLACEMENT in
%   the function call from which the MException was thrown.
%   IDENTIFIER can be a string scalar or character vector and must be a valid
%   MATLAB identifier.
%   REPLACEMENT can be a string scalar or character vector.
%
%   Example:
%
%   % Suggest a fix when a function is called with an incorrect value.
%
%   function walk(speed)
%   if speed > 6.5
%       me = MException('walk:maxSpeed', 'Cannot walk faster than 6.5 km/h.');
%       ric = matlab.lang.correction.ReplaceIdentifierCorrection('walk', 'sprint');
%       me = me.addCorrection(ric);
%       throw(me);
%   elseif speed <= 0
%       error('walk:minSpeed', 'Speed must be greater than zero.');
%   end
%   fprintf('I am walking at a speed of %2.2f km/h.\n', speed);
%   end
%
%   function sprint(speed)
%   if speed <= 6.5
%       me = MException('sprint:minSpeed', 'Cannot sprint slower than 6.5 km/h.');
%       ric = matlab.lang.correction.ReplaceIdentifierCorrection('sprint', 'walk');
%       me = me.addCorrection(ric);
%       throw(me);
%   elseif speed > 20
%       error('sprint:maxSpeed', 'Cannot sprint faster than 20 km/h.');
%   end
%   fprintf('I am sprinting at a speed of %2.2f km/h.\n', speed);
%   end
%
%   % When the WALK function is called with a speed that is too fast, MATLAB
%   % suggests a fix.
%
%   >> walk(10)
%   Error using walk (line 6)
%   Cannot walk faster than 6.5 km/h.
%
%   Did you mean:
%   >> sprint(10)
%
%   See also MException/addCorrection, Correction, AppendArgumentsCorrection, 
%     ConvertToFunctionNotationCorrection, isvarname

%   Copyright 2018-2019 The MathWorks, Inc.
%   Built-in function.

%{
properties
    %IDENTIFIER Incorrect identifier.
    %    The IDENTIFIER property contains the identifier that will be replaced
    %    in the original function call from which the MException was thrown.
    %
    %    See also ReplaceIdentifierCorrection.
    Identifier;

    %REPLACEMENT Text to replace incorrect identifier.
    %    The REPLACEMENT property contains the text that will replace the
    %    identifier in the original function call from which the MException was
    %    thrown.
    %
    %    See also ReplaceIdentifierCorrection.
    Replacement;
end
%}
