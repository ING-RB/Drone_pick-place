function out = anyallop(fcn, x, dim)
%ANYALLOP Common implementation for both ANY and ALL.

% Copyright 2018 The MathWorks, Inc.

narginchk(2, 3);
FCN_NAME = upper(func2str(fcn));

x = tall.validateType(x, FCN_NAME, {'numeric', 'logical', 'char'}, 1);
if nargin>2
    tall.checkNotTall(FCN_NAME, 1, dim);
end

try
    % Call the reduction function
    if nargin<3
        [out, dim] = reduceInDim(fcn, x);
    else
        out = reduceInDim(fcn, x, dim);
    end
    % Now try and update the reduced dimension. Output is always logical.
    allowEmpty = false;
    out.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('logical');
    out.Adaptor = computeReducedSize(out.Adaptor, x.Adaptor, dim, allowEmpty);
catch E
    matlab.bigdata.internal.throw(E);
end
end