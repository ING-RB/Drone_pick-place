function Expression = createExpressionForTFModel(Model)
% Static function to compute expression given a dynamic system

%   Copyright 2014-2020 The MathWorks, Inc.

if isnumeric(Model)
    Expression = ['tf(' num2str(Model) ')'];
elseif isa(Model,'lti')
    ValueTF = tf(Model);
    [num,den] = tfdata(ValueTF,'v');
    num = mat2str(num(find(num~=0,1):end)); % remove initial zeros   
    den = mat2str(den(find(den~=0,1):end)); % remove initial zeros  
    Expression = ['tf(', num ,',',den ,')'];
elseif ischar(Model) % for string expression
    Value = evalin('base',Model);
    if ~isa(Value,'lti') % if not lti, make it lti by passing to tf
        Expression = ['tf(' Model ')'];
    else
        Expression = Model; % return the expression if lti string
    end   
else
    error('Unexpected Error');
end
end
