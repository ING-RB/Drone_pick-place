function callbackType = validateAndGetCallbackFcnType(aCallbackFcn, callBackTypeDescription)
%

%   Copyright 2019-2020 The MathWorks, Inc.

    if isempty(aCallbackFcn)
        callbackType = 'TYPE_UNDEF';
        return
    end

    if (size(aCallbackFcn) ~=1)% row dimension
        error(message('MATLAB:timer:incorrectCallbackInputForCallbackType', callBackTypeDescription));
    end

    theType = class(aCallbackFcn);
    switch theType
      case 'cell' % todo, should iscellstr(aCallbackFcn) be included.
        firstEntry  = aCallbackFcn{1};
        if ~(isa(firstEntry,'function_handle') || ischar(firstEntry))
            error(message('MATLAB:timer:incorrectCallbackInputForCallbackType', callBackTypeDescription));
        end
        callbackType = 'TYPE_FEVAL';
      case 'function_handle'
        callbackType = 'TYPE_FEVAL';
      case 'char'
        callbackType = 'TYPE_EVAL';
      otherwise
        error(message('MATLAB:timer:incorrectCallbackInputForCallbackType', callBackTypeDescription));
    end

end
