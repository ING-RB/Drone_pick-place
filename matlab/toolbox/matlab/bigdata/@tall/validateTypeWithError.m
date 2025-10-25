function tX = validateTypeWithError(tX, methodName, argIdx, allowedTypes, err, recurseIntoTables)
%validateTypeWithError Possibly deferred check for allowed types
%
%   TX = validateTypeWithError(TX,METHODNAME,ARGIDX,ALLOWEDTYPES,ERR)
%   validates that TX is one of the specified types. If it is not then the
%   provided error is thrown.
%
%   TX = validateTypeWithError(...,RECURSETABLES) specifies whether to treat
%   tables as types or whether to recurse into their variables. Some math
%   functions support operating on table variables so only the type of the
%   underlying data matters for these checks. If not specified
%   RECURSETABLES is false and tables will be treated as a type in their
%   own right.
%
%   ALLOWEDTYPES can be a cellstr or string array listing the allowed set,
%     including meta-types such as "numeric", "integer", etc.
%
%   ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call

% Copyright 2017-2022 The MathWorks, Inc.
import matlab.bigdata.internal.util.isClassOneOf;
import matlab.bigdata.internal.util.isDataOfClass;

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, inf);
assert(nargout == 1, 'Assertion failed: validateTypeWithError expects output to be captured.');
if nargin < 6
    recurseIntoTables = false;
end

errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

% Call the hook function that allows logging of type checks.
tX = matlab.bigdata.internal.util.validateTypeHook(...
    tX, methodName, argIdx, allowedTypes, {});

% Deal with non-tall inputs directly
if ~istall(tX)
    if ~iIsAllowedData(tX, allowedTypes, recurseIntoTables)
        errFcn();
    end
    return;
end

% If recursing into tables we need to get the adaptors for all variables,
% no matter how deeply nested.
if recurseIntoTables && istabular(tX)
    adaptor = matlab.bigdata.internal.adaptors.getDataAdaptorsFromTable(tX);
    argClass = cellfun(@(x) string(x.Class), adaptor);
else
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    argClass = string(adaptor.Class);
end
classIsKnown = all(strlength(argClass) > 0);

% If all of the allowed types are those that must be known up front, then we can
% perform the check fully at the client even if the actual type is unknown.
strongTypes = matlab.bigdata.internal.adaptors.getStrongTypes();
classMustBeKnown = all(ismember(allowedTypes, strongTypes));
if classMustBeKnown && ~classIsKnown
    % If it were an allowed class we would know it, so it must be wrong
    errFcn();
end

% Take special care with cell inputs which must be cellstr - the difference
% between cell and cellstr can only be determined lazily
lazyCheckCellstr = (ismember("cellstr", allowedTypes) && ~ismember("cell", allowedTypes)) ...
    && any(ismember(argClass, ["", "cell"]));

% Now run the check immediately if we can, or lazily if we can't
if classIsKnown && ~lazyCheckCellstr
    if ~iIsAllowedType(argClass, allowedTypes)
        errFcn();
    end
else
    % Class is not known up front, must perform a lazy validation.
    tX = lazyValidate(tX, {@(x) iIsAllowedData(x, allowedTypes, recurseIntoTables), errFcn});
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsAllowedData(data, allowedTypes, recurseIntoTables)
% Return true if the specified data has a class that is one of the forbidden types.
% This examines the data itself to correctly detect cellstr.
import matlab.bigdata.internal.util.isDataOfClass;
if recurseIntoTables && istabular(data)
    % Loop over table variables
    tf = varfun(@(x) iIsAllowedData(x, allowedTypes, recurseIntoTables), data, ...
        "OutputFormat", "uniform");
    tf = all(tf);
else
    tf = isDataOfClass(data, allowedTypes);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsAllowedType(actualType, allowedTypes)
% Return true if the specified type is one of the forbidden types. ACTUALTYPE
% must not be empty.
import matlab.bigdata.internal.util.isClassOneOf;
assert(all(strlength(actualType)>0), "TYPE must be known");
tf = all(isClassOneOf(actualType, allowedTypes));
end
