function tryThrowIllegalDotMethodError(this, methodName, NameValueArgs)
%TRYTHROWILLEGALDOTMETHODERROR Subscripting utility to throw an IllegalDotMethod error with a correction.
%   TRYTHROWILLEGALDOTMETHODERROR(THIS,METHODNAME) throws an IllegalDotMethod
%   error if METHODNAME is a method of THIS, with a correction suggesting the
%   supported functional syntax. Otherwise, no error is thrown.
%  
%   TRYTHROWILLEGALDOTMETHODERROR(...,'MethodsWithNoCorrection',METHODSWITHNOCORRECTION)
%   throws the error without adding a correction if METHOD is one of the
%   methods specified by the cellstr or string array METHODSWITHNOCORRECTION.
%
%   TRYTHROWILLEGALDOTMETHODERROR(...,'MessageCatalog',MESSAGECATALOG)
%   throws an IllegalDotMethod error using message catalog MESSAGECATALOG,
%   overriding the default message catalog "MATLAB:" + class(this).
%
%   e.g.
%       >> matlab.internal.datatypes.tryThrowIllegalDotMethodError(datetime(),'cat','MethodsWithNoCorrection',"cat")

%   Copyright 2019-2020 The MathWorks, Inc.

arguments
    this
    methodName
    NameValueArgs.MethodsWithNoCorrection = {}
    NameValueArgs.MessageCatalog = compose("MATLAB:%s",class(this))
end

import matlab.lang.correction.ConvertToFunctionNotationCorrection

methodNames = methods(this);
match = matches(methodNames,methodName,'IgnoreCase',true);
if any(match) % a method name, but invoked with dotMethod syntax
    match = methodNames{match};
    if matches(match,NameValueArgs.MethodsWithNoCorrection)
        % We don't suggest a correction for methods such as cat since the
        % correction would always be invalid because cat requires an
        % integer as its first argument.
        %
        % e.g.
        %     >> cat(duration(), ...) % always invalid
        errorId = compose("%s:IllegalDotMethodNoCorrection",NameValueArgs.MessageCatalog);
        throwAsCaller(MException(message(errorId,methodName,match)));
    end
    errorId = compose("%s:IllegalDotMethod",NameValueArgs.MessageCatalog);
    throwAsCaller(MException(message(errorId,methodName,match)) ...
        .addCorrection(ConvertToFunctionNotationCorrection(match)));
end
