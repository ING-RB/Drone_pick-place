function c = colon(a,d,b) %#codegen
%COLON Create equally-spaced sequence of datetimes.

%   Copyright 2020 The MathWorks, Inc.

% calendarDuration not supported.
coder.internal.errorIf(nargin<3,'MATLAB:datetime:ColonInputsCodegen');

if isa(d,'duration')
    % Step by a duration.
    dstep = milliseconds(d);
else
    % Numeric input interpreted as a number of fixed-length days.
    [dstep,validConversion] = matlab.internal.coder.timefun.datenumToMillis(d);
    coder.internal.assert(validConversion,'MATLAB:datetime:colon:NonNumericStep');
end


[a_data,b_data,c] = datetime.compareUtil(a,b);

if ~isscalar(a_data) || ~isscalar(b_data) || ~isscalar(d)
    coder.internal.assert(coder.internal.isConst(size(a)) && ...
        coder.internal.isConst(size(d)) && ...
        coder.internal.isConst(size(b)),'MATLAB:datetime:colon:NonScalarInputs');
    coder.internal.errorIf(numel(a_data)>1 || numel(b_data)>1 || numel(dstep)>1,'MATLAB:datetime:colon:NonScalarInputs');
    % Either a_data, b_data or d is empty at this point (non-empty ones
    % are scalar), colon returns 1x0 datetime consistent with builtin
    c.data = colon([],[]);
    return;
end

c_data = matlab.internal.coder.doubledouble.plus(a_data,colon(0,dstep,matlab.internal.coder.doubledouble.minus(b_data,a_data,false)));
c.data = c_data;

end


