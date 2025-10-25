function tf = iscategory(a,s)
%ISCATEGORY Test for categorical array categories.
%   TF = ISCATEGORY(A,CATEGORIES)
%
%   See also ISCATEGORY, TALL.

%   Copyright 2017-2023 The MathWorks, Inc.

narginchk(2,2);

a = tall.validateType(a, mfilename, {'categorical'}, 1);
s = tall.validateTypeWithError(s, mfilename, 2, {'string','char','cellstr','pattern'}, ...
    {'MATLAB:categorical:InvalidNamesCharOrPattern','CATEGORIES'});

% Make sure chars get wrapped as strings so that dimensions are treated
% correctly later.
if ~isa(s,'pattern')
    s = string(strtrim(s));
end
catList = categories(a);

if istall(s)
    % The result is elementwise in s, but we must broadcast the categories
    % list so that all partitions receive the same list.
    tf = elementfun( @ismember, s, matlab.bigdata.internal.broadcast(catList) );
    
else
    % Categories on a tall categorical always returns a small result, so if the
    % strings to compare are in-memory we can just use clientfun. We make
    % an empty in-memory categorical to do the work for us.
    tf = clientfun( @(x) iscategory(categorical(x), s), catList );
end

% Result is always a logical array with the same size as S
outAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('logical');
if istall(s)
    sAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(s);
    tf.Adaptor = outAdaptor.copySizeInformation(sAdaptor);
else
    tf.Adaptor = outAdaptor.setKnownSize(size(s));
end

end

