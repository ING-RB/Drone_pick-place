function throwUnrecognizedPropertyError(this, propertyName)
%THROWUNRECOGNIZEDPROPERTYERROR Subscripting utility to throw an UnrecognizedProperty error with a correction.
%   THROWUNRECOGNIZEDPROPERTYERROR(THIS,PROPERTYNAME) throws an UnrecognizedProperty
%   error if PROPERTYNAME matches a property of THIS except for case, with a correction
%   suggesting the case-correct name. Otherwise, THROWUNRECOGNIZEDPROPERTYERROR throws
%   an UnrecognizedProperty error with no correction.
%
%   NOTE: THROWUNRECOGNIZEDPROPERTYERROR should only be used for datatypes
%   with a 'MATLAB:<datatype>:UnrecognizedProperty' error.

%   Copyright 2019-2020 The MathWorks, Inc.

import matlab.lang.correction.ReplaceIdentifierCorrection

propertyNames = properties(this);
match = matches(propertyNames,propertyName,'IgnoreCase',true);
if any(match) % a property name, but with wrong case
    match = propertyNames{match};
    errorId = sprintf('MATLAB:%s:UnrecognizedProperty',class(this));
    throwAsCaller(MException(message(errorId,propertyName)) ...
        .addCorrection(ReplaceIdentifierCorrection(propertyName,match)));
end
errorId = sprintf('MATLAB:%s:UnrecognizedProperty',class(this));
throwAsCaller(MException(message(errorId,propertyName)));