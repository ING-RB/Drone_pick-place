function [wasEmpty, varargout] = createEmptyPrototype(fcn, varargin)
%createEmptyPrototype Generates emptyPrototype of the result of fcn
% Generate an empty prototype based on the result of fcn for each block and
% track wich empty prototypes belong to empty blocks following the rules of
% cell2mat, cellfun, and arrayfun. Wrap empty prototypes into cells so that
% they are vertically concatenable in the framework.

%   Copyright 2019 The MathWorks, Inc.

numOutputs = nargout - 1;
try
    [varargout{1:numOutputs}] = fcn(varargin{:});
catch err
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end

% Mark those blocks that were double empty in varargout, treat them as
% special as they might represent an empty block without type information
% in cell2mat, cellfun, and arrayfun. Propagate this information forward.
wasEmpty = all(cellfun(@(x) size(x, 1) == 0 && isa(x, 'double'), varargout));

% Return empty prototype that matches in small sizes and type.
for ii = 1:numOutputs
    varargout{ii} = {matlab.bigdata.internal.util.indexSlices(varargout{ii}, [])};
end