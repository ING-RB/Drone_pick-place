function varargout = funfunCommon(funfun, userfun, validTypes, varargin)
%funfunCommon Common implementation for arrayfun and cellfun
%   VARARGOUT = funfunCommon(FUNFUN, USERFUN, VALIDTYPES, ARGS...) calls
%   FUNFUN(USERFUN,ARGS...). FUNFUN is expected to be @cellfun or
%   @arrayfun. USERFUN is the user-supplied function handle (or char-vector).
%   VALIDTYPES is a cell array of valid types for the data arguments, or
%   {} if no list of valid types is known.

%   Copyright 2016-2024 The MathWorks, Inc.

% Ensure any error issued from reduce hides this internal frame and
% anything below.
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

funfunName = func2str(funfun);
FUNFUNNAME = upper(funfunName);

if ~isa(userfun, 'function_handle')
    iThrowFunfunError(funfunName, 'MATLAB:iteratorClass:funArgNotHandle');
end

% ErrorHandler is not supported - error if set
[errHandler, otherArgs] = iStripPVPair('ErrorHandler', [], varargin);
if ~isempty(errHandler)
    error(message('MATLAB:bigdata:array:FunFunErrorHandlerNotSupported', FUNFUNNAME));
end

% Extract and validate UniformOutput flag (must be scalar logical or double)
defaultUniformOutput = true;
[isUniform, otherArgs] = iStripPVPair('UniformOutput', defaultUniformOutput, otherArgs);
if ~isValidUniformOutputValue(isUniform)
    iThrowFunfunError(funfunName, 'MATLAB:iteratorClass:NotAParameterPair', ...
                      length(otherArgs) + 3, 'logical', 'UniformOutput');
end

for idx = 1:numel(otherArgs)
    if ~istall(otherArgs{idx})
        error(message('MATLAB:bigdata:array:AllArgsTall', FUNFUNNAME));
    end
    
    if ~isempty(validTypes)
        % otherArgs start at position 2.
        otherArgs{idx} = tall.validateType(otherArgs{idx}, funfunName, validTypes, 1 + idx);
    end
end

% Just in case the user function samples random numbers, fix the RNG state.
opts = matlab.bigdata.internal.PartitionedArrayOptions('RequiresRandState', true);

if isUniform
    % Validate that all blocks are vertically concatenable in size and they
    % have the same type when UniformOutput is true.
    aggregateFcn = @(varargin) iCreateAndValidateEmptyPrototype(funfun, userfun, varargin{:});
    reduceFcn = @(varargin) validatePrototypeBetweenBlocks(func2str(funfun), varargin{:});
    [~, emptyProto{1:nargout}] = aggregatefun(aggregateFcn, reduceFcn, otherArgs{:});
    finalCheckFcn = @(varargin) iValidateFinalEmptyPrototype(funfun, varargin{:});
    [emptyProto{:}] = clientfun(finalCheckFcn, emptyProto{:});
    % Call funfun method and return emptyProto when the output is empty.
    for ii = 1:nargout
        emptyProto{ii} = matlab.bigdata.internal.broadcast(emptyProto{ii});
    end
    fcnWrapper = @(varargin) iCallFunFunUniform(funfun, userfun, varargin{:}, 'UniformOutput', true);
    [varargout{1:nargout}] = elementfun(opts, fcnWrapper, emptyProto{:}, otherArgs{:});
else
    % When UniformOutput is false, the output of each element is a scalar
    % cell. Do not perform validation on the output size and type, directly
    % get the results from the call to funfun.
    fcnWrapper = @(varargin) iCallFunFunNonUniform(funfun, userfun, varargin{:}, 'UniformOutput', false);
    [varargout{1:nargout}] = elementfun(opts, fcnWrapper, otherArgs{:});
    [varargout{:}] = setKnownType(varargout{:}, 'cell');
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% isValidUniformOutputValue - check that the input is a valid value for the
% UniformOutput flag
function tf = isValidUniformOutputValue(arg)

% valid if scalar logical, or scalar double with value 0 or 1
tf = (islogical(arg) && isscalar(arg)) ...
    || (isa(arg,'double') && isscalar(arg) && ismember(arg, [0 1]));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [wasEmpty, varargout] = iCreateAndValidateEmptyPrototype(funfun, userfun, varargin)
% Generate an empty prototype and validate that the output type matches
% with valid types for this funfun. This allows missing for this
% intermediate step because those missings might vanish.

[wasEmpty, varargout{1:nargout - 1}] = createEmptyPrototype(funfun, userfun, varargin{:});

% createEmptyPrototype returns the prototype of each output wrapped into a
% cell array. Since the contract of funfun methods states that userfun must
% return a scalar output, each cell inside varargout will be a 1x1 cell.
outTypes = cellfun(@(x) class(x{1}), varargout, 'UniformOutput', false);
allowedTypes = matlab.bigdata.internal.adaptors.getAllowedTypes();
if any(~ismember(outTypes, allowedTypes) & outTypes ~= "missing")
    % Got disallowed types
    forbiddenTypes = setdiff(outTypes, allowedTypes);
    iThrowFunfunError(func2str(funfun), ...
        'MATLAB:iteratorClass:UnimplementedOutputArrayType', ...
        forbiddenTypes{1});
end

% Forbid outputs that aren't: numeric, logical, char, cell or missing (the
% "classic" list of allowed uniform output types - strictly speaking, we
% only need to forbid "strong" types - but what if we change that list?)
isOkOutputFcn = @(x) isnumeric(x{1}) || islogical(x{1}) || ischar(x{1}) || iscell(x{1}) || isa(x{1}, "missing");
outputOkFlag  = cellfun(isOkOutputFcn, varargout);
if any(~outputOkFlag)
    firstBadOutput = find(~outputOkFlag, 1, 'first');
    firstBadClass  = outTypes{firstBadOutput};
    error(message('MATLAB:bigdata:array:FunFunInvalidOutputType', ...
                  upper(func2str(funfun)), firstBadClass));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [varargout] = iValidateFinalEmptyPrototype(funfun, varargin)
% Funfun does not support the case where every output is an instance of class
% missing, as we cannot hold "missing" as an underlying type.
varargout = varargin;
isOkFinalOutputFcn = @(x) ~isa(x{1}, "missing");
finalOutputOkFlag  = cellfun(isOkFinalOutputFcn, varargout);
if any(~finalOutputOkFlag)
    error(message("MATLAB:bigdata:array:FunFunInvalidOutputType", ...
                  upper(func2str(funfun)), "missing"));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iCallFunFunUniform - wrap call to funfun with uniform output
function varargout = iCallFunFunUniform(funfun, userfun, varargin)
% Take as many empty prototypes as nargout from the begining of varargin
[emptyProto{1:nargout}] = varargin{1:nargout};
varargin(1:nargout) = [];

% Call funfun method
[varargout{1:nargout}] = funfun(userfun, varargin{:});

% For those outputs whose type is not known, use the empty prototype to
% mark this empty block.
for ii = 1 : nargout
    if size(varargout{ii}, 1) == 0 && isa(varargout{ii}, 'double')
        varargout{ii} = emptyProto{ii}{:};
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iCallFunFunNonUniform - wrap call to funfun with non uniform output
function varargout = iCallFunFunNonUniform(funfun, userfun, varargin)

% Call funfun method. The output of funfun is always a cell array.
[varargout{1:nargout}] = funfun(userfun, varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Throw a cellfun/arrayfun error. iteratorClassID should be a message from the
% MATLAB:iteratorClass catalog.
function iThrowFunfunError(funfunName, iteratorClassID, varargin)
msgStr = getString(message(iteratorClassID, varargin{:}));
funfunID = strrep(iteratorClassID, 'iteratorClass', funfunName);
error(funfunID, '%s', msgStr);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [value, remainingArgs] = iStripPVPair(propName, defaultValue, args)

% Here, we happen to know that the property arguments to all funfuns are unique,
% so we only need to check to see if the putative property name starts with the
% correct sequence of characters.

if length(args) > 2 ...
    && isNonTallScalarString(args{end-1}) ...
    && iMatches(args{end-1}, propName)
    value = args{end};
    remainingArgs = args(1:end-2);
else
    value = defaultValue;
    remainingArgs = args;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRUE if name (as char or string) matches propName
function tf = iMatches(name, propName)
if isstring(name)
    name = char(name);
end
tf = strncmpi(name, propName, numel(name));
end

