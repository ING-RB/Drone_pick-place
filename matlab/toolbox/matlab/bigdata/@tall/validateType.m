function varargout = validateType(varargin)
%validateType Possibly deferred argument type validation
%   [TX1,TX2,...] = validateType(TX1,TX2,...,METHOD,VALIDTYPES,ARGIDXS)
%   validates that each of TX1, TX2, ... is one of the types VALIDTYPES. ARGIDXS
%   describes the positions of TX1,TX2 in the original call to METHOD - i.e. a
%   numeric vector. If possible, the validation is done immediately; otherwise,
%   the validation is done lazily.
%
%   [...] = validateType(...,RECURSETABLES) specifies whether to treat
%   tables as types or whether to recurse into their variables. Some math
%   functions support operating on table variables so only the type of the
%   underlying data matters for these checks. If not specified
%   RECURSETABLES is false and tables will be treated as a type in their
%   own right.
%
%   Note that if the required types and forbidden types are all types that must
%   be known at the client (aka a "strong" type) the validation is always
%   performed immediately. 
%
%   Examples:
%   >> a = [1 2 3]; b = 'hello';
%   >> [a,b] = tall.validateType(a, b, "foo", ["float", "~char"], [1 2])
%
%   See also: tall.validateTypeWithError, tall.validateNotTypeWithError.

% Copyright 2016-2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

% If the optional table recursion flag is specified strip it from the input
% list.
if islogical(varargin{end}) && isscalar(varargin{end}) ...
        && isnumeric(varargin{end-1})
    recurseTables = varargin{end};
    varargin(end) = [];
else
    recurseTables = false;
end

dataArgs   = varargin(1:end-3);
methodName = varargin{end-2};
types      = varargin{end-1};
argIdxs    = varargin{end};
assert(numel(argIdxs) == numel(dataArgs) && ...
       matlab.internal.datatypes.isScalarText(methodName) && ...
       (iscellstr(types) || isstring(types)) && ...
       isnumeric(argIdxs), ...
       'Invalid inputs to validateType.');

% Forbidden types start with "~"
isForbiddenType = strncmp('~', types, 1);
forbiddenTypes = types(isForbiddenType);
forbiddenTypes = strrep(forbiddenTypes, '~', '');
allowedTypes = types(~isForbiddenType);

msgArgsFcn = @(idx) message('MATLAB:bigdata:array:InvalidArgumentType', idx, ...
                    upper(methodName), strjoin(allowedTypes, ' '));
forbiddenMsgArgsFcn = @(idx) message('MATLAB:bigdata:array:UnsupportedArgumentType', idx, ...
                    upper(methodName), strjoin(forbiddenTypes, ' '));

% It's a mistake not to capture all the outputs since they might be modified.
nData = numel(dataArgs);
nargoutchk(nData, nData);
varargout = cell(1, nData);

for idx = 1:nData
    dataArgs{idx} = matlab.bigdata.internal.util.validateTypeHook(...
        dataArgs{idx}, methodName, argIdxs(idx), allowedTypes, forbiddenTypes);
    try
        varargout{idx} = iValidateArg(dataArgs{idx}, methodName, argIdxs(idx), ...
                                      allowedTypes, forbiddenTypes, ...
                                      msgArgsFcn(argIdxs(idx)), forbiddenMsgArgsFcn(argIdxs(idx)), ...
                                      recurseTables);
    catch err
        if recurseTables && istabular(dataArgs{idx})
            baseError = MException("MATLAB:bigdata:array:TabularMathInvalidType", ...
                message("MATLAB:bigdata:array:TabularMathInvalidType", upper(methodName)));

            % Create BigDataException to remove internal stack
            err = matlab.bigdata.BigDataException.build(err);
            err = addCause(baseError, err);
        end
        throwAsCaller(err);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper to perform both allowed and forbidden type checks
function arg = iValidateArg(arg, methodName, argIdx, ...
                            allowedTypes, forbiddenTypes, ...
                            allowedMsg, forbiddenMsg, ...
                            recurseTables)

if isempty(forbiddenTypes)
    % No types forbidden, no point checking.
else
    arg = tall.validateNotTypeWithError(arg, methodName, argIdx, forbiddenTypes, forbiddenMsg, recurseTables);
end
                        
if isempty(allowedTypes)
    % All types allowed, no point checking.
else
    arg = tall.validateTypeWithError(arg, methodName, argIdx, allowedTypes, allowedMsg, recurseTables);
end

end
