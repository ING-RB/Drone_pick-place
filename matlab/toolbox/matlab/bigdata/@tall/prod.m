function out = prod(x, varargin)
%PROD Product of elements.
%
%   See also prod.

% Copyright 2016-2023 The MathWorks, Inc.

narginchk(1, 4);

% We need a specific overload for SUM to handle duration.
FCN_NAME = upper(mfilename);
allowTabularMaths = true;
x = tall.validateType(x, mfilename, ...
    {'numeric', 'logical'}, ...
    1, allowTabularMaths);
tall.checkNotTall(FCN_NAME, 1, varargin{:});
% Use the in-memory version to check the arguments
outProto = tall.validateSyntax(@prod,[{x},varargin],'DefaultType','double');

[args, flags] = splitArgsAndFlags(varargin{:});

% Flags have already been validated, but we need the precisionFlagCell here
% for computing the output type.
[nanFlagCell, precisionFlagCell] = x.Adaptor.interpretReductionFlags(FCN_NAME, flags);
flags = [nanFlagCell, precisionFlagCell];

reduceFlags = flags;
reduceFlags(strcmpi("omitnan",flags) | strcmpi("omitmissing",flags)) = {'includenan'};
[out, dimUsed] = aggregateInDim(@prod, x, args, flags, reduceFlags);

out.Adaptor = computeSumResultType(x, precisionFlagCell, mfilename);

if istabular(x)
    % Reduction has modified the table variables or updated the tabular
    % properties. For timetables, prod returns a table. Copy from the
    % in-memory prototype.
    out.Adaptor = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(outProto), ...
        out.Adaptor);
end

if ~isempty(dimUsed)
    out.Adaptor = computeReducedSize(out.Adaptor, x.Adaptor, dimUsed, false);
end

end
