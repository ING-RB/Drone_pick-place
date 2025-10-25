function varargout = transform(fcn, varargin)
%TRANSFORM Transform array by applying function handle to blocks of data
% A = MATLAB.TALL.TRANSFORM(FCN,X) applies the function FCN to each block
% of array X and returns the result in array A. Each output of FCN must be
% the same type as the input X.
%
% A block of a tall array X is a set of consecutive rows that can be held
% in memory at once. For example, one block of a 2-D array (such as a
% table) is X(N:M,:), for some subscripts N and M. For the purposes of
% MATLAB.TALL.TRANSFORM, a tall array is considered to be the vertical
% concatenation of many such blocks.
%
% MATLAB.TALL.TRANSFORM supports both tall arrays and in-memory arrays. If
% any input argument is tall, then all output arguments are also tall.
% Otherwise, all output arguments are in-memory arrays.
%
% A = MATLAB.TALL.TRANSFORM(FCN,X,Y,...) specifies several input arrays
% X, Y, ... . FCN works on the same rows of each input, for example
% FCN(X(N:M,:),Y(N:M,:)). Each of X, Y, ... must have compatible heights.
% Two inputs have compatible height if they have the same height, or one
% input is of height one. Inputs with a height of one are passed to every
% call of FCN. Each output of FCN must be the same type as the first input
% X.
%
% [A,B,...] = MATLAB.TALL.TRANSFORM(FCN,X,Y,...), where FCN is a function
% handle that returns multiple outputs, returns arrays A, B, ..., each
% corresponding to one of the output arguments of FCN. FCN must return the
% same number of output arguments as were requested from TRANSFORM. Each
% output of FCN must be the same type as the first input X. All outputs of
% FCN must have the same height.
%
% [A,B,...] = MATLAB.TALL.TRANSFORM(...,"OutputsLike",{PA,PB,...})
% specifies that outputs A, B, ... have the same types as PA, PB, ...,
% respectively. You can use any of the input argument combinations in
% previous syntaxes. Each output of FCN must be the same type as
% PA, PB, ..., respectively.
%
% Examples:
%   % Create a tall array
%   ds = tabularTextDatastore("airlinesmall.csv","TreatAsMissing","NA");
%   ds.SelectedVariableNames = ["ArrDelay", "DepDelay"];
%   tt = tall(ds);
%   tX = tt.ArrDelay;
%   tY = tt.DepDelay;
%
%   % Example 1: Multiply by two.
%   tA = matlab.tall.transform(@(x) x .* 2, tX);
%
%   % Example 2: Filter out NaNs.
%   tB = matlab.tall.transform(@(x) x(~isnan(x)), tX);
%
%   % Example 3: Add two arrays together.
%   tC = matlab.tall.transform(@plus,tX,tY);
%
%   % Example 4:  Input data is a tall double, output is a tall table.
%   fcn = @(x) table(x,'VariableNames',"MyVar");
%   exampleOfD = fcn(0);
%   tD = matlab.tall.transform(fcn,tX,"OutputsLike",{exampleOfD});
%
%   See also: TALL, MATLAB.TALL.REDUCE

% Copyright 2018-2022 The MathWorks, Inc.

validateattributes(fcn, {'function_handle', 'string', 'char'}, {}, 'matlab.tall.transform', 'FCN');
if ~isa(fcn, 'function_handle')
    fcn = str2func(fcn);
end
numOutputs = max(nargout, 1);
[dataArguments, outputsLike, options] ...
    = parseInputs('matlab.tall.transform', numOutputs, varargin{:});
try
    [varargout{1:numOutputs}] = iTransform(fcn, dataArguments, outputsLike, options);
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    rethrow(err);
end
end

function varargout = iTransform(fcn, dataArguments, outputsLike, options)
% Implementation of matlab.tall.transform

% Ensure any error issued from transform hides this internal frame and
% anything below.
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

useLikeParameters = true;
fcn = wrapUserFunction(fcn, options, useLikeParameters);

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
    opts = matlab.bigdata.internal.PartitionedArrayOptions('RequiresRandState', true);
    [varargout{:}] = chunkfun(opts, fcn, inputArguments{:});
    varargout = wrapTallLike(varargout, outputsLike);
else
    checkCompatibleHeight(dataArguments{:});
    fcn = matlab.bigdata.internal.lazyeval.TaggedArrayFunction.wrap(fcn);
    [varargout{:}] = feval(fcn, inputArguments{:});
end
end
