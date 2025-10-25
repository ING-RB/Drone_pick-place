function out = ismissing(in, varargin)
%ISMISSING  Find missing entries
%
%   TF = ISMISSING(A)
%   TF = ISMISSING(A,INDICATORS)
%   TF = ISMISSING(...,'OutputFormat',FORMAT)
%
%   See also: ISMISSING, TALL/STANDARDIZEMISSING.

% Copyright 2015-2021 The MathWorks, Inc.

tall.checkIsTall(upper(mfilename), 1, in);
tall.checkNotTall(upper(mfilename), 1, varargin{:});
narginchk(1, inf);

% Use the in-memory function to validate the syntax and also tell us
% whether the output is going to be logical or tabular.
outProto = tall.validateSyntax(@ismissing, [{in},varargin], 'DefaultType', 'double');

% We get back a tall logical or tall table with the same size as the input
out = elementfun(@(t) ismissing(t, varargin{:}), in);
out.Adaptor = matlab.bigdata.internal.adaptors.getAdaptor(outProto);
out.Adaptor = out.Adaptor.copySizeInformation(in.Adaptor);
end
