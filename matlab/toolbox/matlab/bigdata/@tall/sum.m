function out = sum(x, varargin)
%SUM Sum of elements.
%
%   See also sum.

% Copyright 2016-2022 The MathWorks, Inc.

narginchk(1, 4);

% We need a specific overload for SUM to handle duration.
FCN_NAME = upper(mfilename);
allowTabularMaths = true;
x = tall.validateType(x, mfilename, ...
    {'numeric', 'logical', 'duration', 'char'}, ...
    1, allowTabularMaths);
tall.checkNotTall(FCN_NAME, 1, varargin{:});
% Use the in-memory version to check the arguments
outProto = tall.validateSyntax(@sum,[{x},varargin],'DefaultType','double');

[args, flags] = splitArgsAndFlags(varargin{:});

% Flags have already been validated, but we need the precisionFlagCell here
% for computing the output type.
[nanFlagCell, precisionFlagCell] = x.Adaptor.interpretReductionFlags(FCN_NAME, flags);
flags = [nanFlagCell, precisionFlagCell];

reduceFlags = flags;
reduceFlags(strcmpi("omitnan",flags) | strcmpi("omitmissing",flags)) = {'includenan'};
[out, dimUsed] = aggregateInDim(@sum, x, args, flags, reduceFlags);

out.Adaptor = computeSumResultType(x, precisionFlagCell, mfilename);

if istabular(x)
    % Reduction has modified the table variables or updated the tabular
    % properties. For timetables, sum returns a table. Copy from the
    % in-memory prototype.
    out.Adaptor = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(outProto), ...
        out.Adaptor);
end

if ~isempty(dimUsed)
    out.Adaptor = computeReducedSize(out.Adaptor, x.Adaptor, dimUsed, false);
end

end
