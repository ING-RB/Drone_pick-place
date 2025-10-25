%CONVERTTOFUNCTIONNOTATIONCORRECTION  Convert dot notation method call to function syntax.
%   CFNC = matlab.lang.correction.ConvertToFunctionNotationCorrection(METHOD)
%   creates a correction that will suggest the function notation equivalent of
%   the dot notation invocation from which the MException was thrown.
%   METHOD can be a string scalar or character vector and must be a valid
%   MATLAB identifier.
%
%   Example:
%
%   % Suggest a fix when a method is invoked by dot notation.
%
%   classdef myClass < handle
%       properties
%           myProperty;
%       end
%       methods (Hidden)
%           function ref = subsref(obj, idx)
%           firstSubs = idx(1).subs;
%           if idx(1).type ~= "." || any(string(firstSubs) == properties(obj))
%               % Smooth paren, curly paren, or property indexing.
%               try
%                   ref = builtin('subsref', obj, idx);
%                   return;
%               catch me
%               end
%           elseif any(string(firstSubs) == methods(obj))
%               % Valid method called via dot notation.
%               me = MException('myClass:useFunctionForm', ...
%                               'Use function syntax to call the ''%s'' method.', ...
%                               firstSubs);
%               cfnc = matlab.lang.correction.ConvertToFunctionNotationCorrection(firstSubs);
%               me = me.addCorrection(cfnc);
%           else
%               % Invalid method, property, or field called via dot notation.
%               me = MException('MATLAB:noSuchMethodOrField', ...
%                               'Unrecognized method, property, or field ''%s'' for class ''%s''.', ...
%                               firstSubs, class(obj));
%           end
%           throwAsCaller(me);
%           end
%       end
%   end
% 
%
%   % When the ISVALID method is called via dot notation, MATLAB suggests a
%   % fix.
%
%   >> myObject = myClass;
%   >> myObject.isvalid;
%   Use function syntax to call the 'isvalid' method.
%
%   Did you mean:
%   >> isvalid(myObject)
%
%   See also MException/addCorrection, Correction, AppendArgumentsCorrection, 
%     ReplaceIdentifierCorrection, isvarname

%   Copyright 2018-2019 The MathWorks, Inc.
%   Built-in function.

%{
properties
    %METHODTOCONVERT Name of method to convert to function notation form.
    %    The METHODTOCONVERT property contains the name of the method call from
    %    which the MException was thrown.
    %
    %    See also ConvertToFunctionNotationCorrection.
    MethodToConvert;
end
%}
