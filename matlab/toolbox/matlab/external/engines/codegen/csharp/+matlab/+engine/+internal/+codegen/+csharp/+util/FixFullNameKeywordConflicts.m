% Copyright 2023 The MathWorks, Inc.
function [correctedMethodName] = FixFullNameKeywordConflicts(fullMethodName)
%   FIXFULLNAMEKEYWORDCONFLICTS Fix keyword conflicts within a fully qualified
%   name of a method or function
    arguments(Input)
        fullMethodName (1,1) string
    end
    arguments(Output)
        correctedMethodName (1,1) string
    end
    fullMethodNameArray = split(fullMethodName, ".");
    % Transpose is needed because the returned array has dimensions N x 1
    % while a MATLAB for loop requires dimensions 1 X N
    fullMethodNameArray = transpose(fullMethodNameArray);
    fullMethodNameArray = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(fullMethodNameArray);
    correctedMethodName = join(fullMethodNameArray, ".");
end