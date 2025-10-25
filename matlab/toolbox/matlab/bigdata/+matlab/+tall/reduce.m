function varargout = reduce(fcn, reducefcn, varargin)
%REDUCE Reduce arrays by applying reduction algorithm to blocks of data.
% A = MATLAB.TALL.REDUCE(FCN,REDUCEFCN,X) applies the function FCN to each
% block of array X to generate partial results, then applies REDUCEFUN to
% the vertical concatenation of partial results to generate a single
% result, A. Both FCN and REDUCEFCN must accept one input and return one
% output. Each output of FCN and REDUCEFCN must be the same type as the
% input X.
%
% A block of a tall array X is a set of consecutive rows that can be held
% in memory at once. For example, one block of a 2-D array (such as a
% table) is X(N:M,:), for some subscripts N and M. For the purposes of
% MATLAB.TALL.REDUCE, a tall array is considered to be the vertical
% concatenation of many such blocks.
%
% MATLAB.TALL.REDUCE supports both tall arrays and in-memory arrays. If any
% input argument is tall, then all output arguments are also tall.
% Otherwise, all output arguments are in-memory arrays.
%
% A = MATLAB.TALL.REDUCE(FCN,REDUCEFCN,X,Y,...) specifies several input
% arrays X, Y, ... . FCN works on the same rows of each input, for example
% FCN(X(N:M,:),Y(N:M,:)). FCN must return one output. REDUCEFCN must accept
% one input and return one output. Each of X, Y, ... must have compatible
% heights. Two inputs have compatible height if they have the same height,
% or if one input is of height one. Inputs with a height of one are passed
% to every call of FCN. Each output of FCN and REDUCEFCN must be the same
% type as the first input X.
%
% [A,B,...] = MATLAB.TALL.REDUCE(FCN,REDUCEFCN,X,Y,...), where both FCN and
% REDUCEFCN return multiple outputs, returns arrays A, B, ..., each
% corresponding to one of the output arguments of FCN and REDUCEFCN. FCN
% must return the same number of outputs as were requested from REDUCE.
% REDUCEFCN must have the same number of inputs and outputs as the number
% of outputs requested from REDUCE. Each output of FCN and REDUCEFCN must
% be the same type as the first input X. Corresponding outputs of FCN and
% REDUCEFCN must have the same height.
%
% [A,B,...] = MATLAB.TALL.REDUCE(...,"OutputsLike",{PA,PB,...}) specifies
% that outputs A, B, ... have the same types as PA, PB, ..., respectively.
% You can use any of the input argument combinations in previous syntaxes.
% Corresponding outputs of FCN and REDUCEFCN must also have the same types
% as PA, PB, ..., respectively.
%
% Examples:
%   % Create a tall array
%   ds = tabularTextDatastore("airlinesmall.csv","TreatAsMissing","NA");
%   ds.SelectedVariableNames = ["ArrDelay", "DepDelay"];
%   tt = tall(ds);
%   tX = tt.ArrDelay;
%   tY = tt.DepDelay;
%
%   % Example 1: Count the number of elements.
%   tA = matlab.tall.reduce(@numel,@sum,tX);
%
%   % Example 2: Input data is a tall double, output is a table.
%   fcn = @(x) table(sum(x),numel(x),'VariableNames',["MySum","MyCount"]);
%   reducefcn = @(t) table(sum(t.MySum),sum(t.MyCount),'VariableNames',["MySum","MyCount"]);
%   exampleOfB = fcn(0);
%   tB = matlab.tall.reduce(fcn,reducefcn,tX,"OutputsLike",{exampleOfB});
%
%   See also: TALL, MATLAB.TALL.TRANSFORM

% Copyright 2018-2022 The MathWorks, Inc.

validateattributes(fcn, {'function_handle', 'string', 'char'}, {}, 'matlab.tall.reduce', 'FCN');
if ~isa(fcn, 'function_handle')
    fcn = str2func(fcn);
end
validateattributes(reducefcn, {'function_handle', 'string', 'char'}, {}, 'matlab.tall.reduce', 'REDUCEFCN');
if ~isa(reducefcn, 'function_handle')
    reducefcn = str2func(reducefcn);
end
numOutputs = max(nargout, 1);
[dataArguments, outputsLike, options] ...
    = parseInputs('matlab.tall.reduce', numOutputs, varargin{:});
try
    [varargout{1:numOutputs}] = iReduce(fcn, reducefcn, dataArguments, outputsLike, options);
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    rethrow(err);
end
end

function varargout = iReduce(fcn, reducefcn, dataArguments, outputsLike, options)
% Implementation of matlab.tall.reduce

% Ensure any error issued from reduce hides this internal frame and
% anything below.
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

% FCN is responsible for generating partial results, we need to enforce
% the like parameters here.
useLikeParameters = true;
fcn = wrapUserFunction(fcn, options, useLikeParameters);

% REDUCEFCN is responsible for reducing partial results together. The
% output type and size is the same as the input.
useLikeParameters = false;
reducefcn = wrapUserFunction(reducefcn, options, useLikeParameters);

% We pass like parameter as data arguments to allow support of tall like
% parameters.
inputArguments = [dataArguments, wrapNonTallAsBroadcast(outputsLike)];

varargout = cell(1, numel(outputsLike));
hasTallInputs = any(cellfun(@istall, inputArguments));
if hasTallInputs
    % Enable adaptor assertion check to unpack the tall arguments.
    prevState = matlab.bigdata.internal.util.enableAdaptorAssertion(true);
    inputArguments = matlab.bigdata.internal.util.unpackTallArguments(inputArguments);
    matlab.bigdata.internal.util.enableAdaptorAssertion(prevState);
    [varargout{:}] = aggregatefun(fcn, reducefcn, inputArguments{:});
    varargout = wrapTallLike(varargout, outputsLike);
else
    checkCompatibleHeight(dataArguments{:});
    fcn = matlab.bigdata.internal.lazyeval.TaggedArrayFunction.wrap(fcn);
    [varargout{:}] = feval(fcn, inputArguments{:});
    reducefcn = matlab.bigdata.internal.lazyeval.TaggedArrayFunction.wrap(reducefcn);
    [varargout{:}] = feval(reducefcn, varargout{:});
end
end
