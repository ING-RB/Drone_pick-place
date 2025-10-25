function tX = validateNotTypeWithError(tX, methodName, argIdx, forbiddenTypes, err, recurseIntoTables)
%validateNotTypeWithError Possibly deferred check for forbidden types
%
%   TX = validateNotTypeWithError(TX,METHODNAME,ARGIDX,FORBIDDENTYPES,ERR)
%   validates that TX is not one of the specified types. If it is then the
%   provided error is thrown.
%
%   TX = validateNotTypeWithError(...,RECURSETABLES) specifies whether to treat
%   tables as types or whether to recurse into their variables. Some math
%   functions support operating on table variables so only the type of the
%   underlying data matters for these checks. If not specified
%   RECURSETABLES is false and tables will be treated as a type in their
%   own right.
%
%   FORBIDDENTYPES can be a cellstr or string array listing the forbidden set,
%     including meta-types such as "numeric", "integer", etc.
%
%   ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call

% Copyright 2018-2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, inf);
assert(nargout == 1, 'Assertion failed: validateNotTypeWithError expects output to be captured.');
if nargin < 6
    recurseIntoTables = false;
end

errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

% Call the hook function that allows logging of type checks.
tX = matlab.bigdata.internal.util.validateTypeHook(...
    tX, methodName, argIdx, {}, forbiddenTypes);

% Deal with non-tall inputs directly
if ~istall(tX)
    if iIsForbiddenData(tX, forbiddenTypes, recurseIntoTables)
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

% If all of the forbidden types are those that must be known up front, then we
% can perform the check fully at the client even if the actual type is unknown.
strongTypes = matlab.bigdata.internal.adaptors.getStrongTypes();
classMustBeKnown = all(ismember(forbiddenTypes, strongTypes));
if classMustBeKnown && ~classIsKnown
    % If it were a forbidden class we would know it, so it must be OK
    return;
end

% Take special care with cell inputs which must be cellstr - the difference
% between cell and cellstr can only be determined lazily
lazyCheckCellstr = (ismember("cellstr", forbiddenTypes) && ~ismember("cell", forbiddenTypes)) ...
    && any(ismember(argClass, ["", "cell"]));

% Now run the check immediately if we can, or lazily if we can't
if classIsKnown && ~lazyCheckCellstr
    if iIsForbiddenType(argClass, forbiddenTypes)
        errFcn();
    end
else
    % Class is not known up front, must perform a lazy validation.
    tX = lazyValidate(tX, {@(x) ~iIsForbiddenData(x, forbiddenTypes, recurseIntoTables), errFcn});
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsForbiddenData(data, forbiddenTypes, recurseIntoTables)
% Return true if the specified data has a class that is one of the forbidden types.
% This examines the data itself to correctly detect cellstr.
import matlab.bigdata.internal.util.isDataOfClass;
if recurseIntoTables && istabular(data)
    % Loop over table variables
    tf = varfun(@(x) iIsForbiddenData(x, forbiddenTypes, recurseIntoTables), data, ...
        "OutputFormat", "uniform");
    tf = any(tf);
else
    tf = ~isempty(forbiddenTypes) && isDataOfClass(data, forbiddenTypes);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsForbiddenType(actualType, forbiddenTypes)
% Return true if the specified type is one of the forbidden types. ACTUALTYPE
% must not be empty.
import matlab.bigdata.internal.util.isClassOneOf;
assert(all(strlength(actualType)>0), "TYPE must be known");
if isempty(forbiddenTypes)
    tf = false;
else
    tf = any(isClassOneOf(actualType, forbiddenTypes));
end
end
