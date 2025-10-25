function out = categoricalPiece(fcnName, tc, varargin)
%categoricalPiece Common implementation for tall categorical addcats, removecats etc.
%   out = categoricalPiece(fcnName, tdt, varargin)
%   * fcnName is 'addcats', 'removecats' etc.
%   * tc will be validated to be a tall categorical
%   * trailing varargin will be broadcast.
%
%   The calling function must call narginchk and nargoutchk.

% Copyright 2016-2023 The MathWorks, Inc.

name = upper(fcnName);
tc = tall.validateType(tc, name, {'categorical'}, 1);

vars = cellfun(@matlab.bigdata.internal.broadcast, varargin, 'UniformOutput', false);
% Call the underlying element-wise function
underlyingFcn = str2func(fcnName);
out = elementfun(underlyingFcn, tc, vars{:});
out.Adaptor = iSetOutputAdaptor(underlyingFcn, tc, varargin{:});
end

function adaptor = iSetOutputAdaptor(underlyingFcn, tc, varargin)
adaptor = tc.Adaptor;

% Propagate the categories to the adaptor adaptor if we know all the extra
% inputs provided.
allNonTallArgs = all(cellfun(@(x) ~istall(x), varargin));
if allNonTallArgs
    sample = tall.validateSyntax(underlyingFcn, [{tc}, varargin], 'DefaultType', 'categorical');
    adaptor = adaptor.resetCategories(categories(sample));
else
    adaptor = adaptor.resetCategories();
end
end
