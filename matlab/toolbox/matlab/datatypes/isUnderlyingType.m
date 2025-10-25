function tf = isUnderlyingType(obj, typename) %#codegen
%isUnderlyingType  Determine if input has specified underlying type.
%
%   isUnderlyingType(OBJ,"TypeName") returns TRUE if the underlying type of
%   OBJ is equal to "TypeName", as returned by underlyingType(OBJ).
%   Otherwise, the result is FALSE. TypeName must be a character vector or
%   string scalar.
%
%   Examples:
%   x = zeros(2,2,"single");
%   isUnderlyingType(x,"single")    % true - underlyingType(x) is single
%
%   x = gpuArray(eye(3,"uint8"));
%   isUnderlyingType(x,"single")    % false - underlyingType(x) is uint8
%
%   x = dlarray(gpuArray(rand(3)));
%   isUnderlyingType(x,"gpuArray")  % false - underlyingType(x) is double
%
%   x = {1,2,3};
%   isUnderlyingType(x,"double")    % false - underlyingType(x) is cell
%
%   x = table([1;2],[3;4]);
%   isUnderlyingType(x,"table")     % true - underlyingType(x) is table
%
%   See also: underlyingType, mustBeUnderlyingType, class.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(~iIsScalarText(typename), ...
    'MATLAB:string:MustBeStringScalarOrCharacterVector');
    
if strcmp(typename,"float")
    tf = isfloat(obj);
elseif strcmp(typename,"integer")
    tf = isinteger(obj);
elseif strcmp(typename,"numeric")
    tf = isnumeric(obj);
else
    tf = strcmp(underlyingType(obj), typename);
end
end

function tf = iIsScalarText(arg)
% Scalar text or ''
tf = (ischar(arg) && isrow(arg)) || isequal(arg,'') ...
    || (isstring(arg) && isscalar(arg));
end
