function checkValidSubstruct(S)
%checkValidSubstruct Check a substruct input has the right fields etc.

% Copyright 2019 The MathWorks, Inc.

if isempty(S) || ~isstruct(S)
    error(message("MATLAB:subsArgNotStruc"));
end
if numel(fieldnames(S)) ~= 2
    error(message("MATLAB:subsMustHaveTwo"));
end
if ~isfield(S,"type") || ~isfield(S,"subs")
    error(message("MATLAB:subsMustHaveTypeSubs"));
end
% If we have a struct array we have to check each type entry
for ii=1:numel(S)
    if ~matlab.internal.datatypes.isScalarText(S(ii).type)
        error(message("MATLAB:subsTypeMustBeChar"));
    end
    if ~ismember(S(ii).type, ["()", "{}", "."])
        error(message("MATLAB:subsTypeMustBeSquigglyOrSmooth"));
    end
    if strcmp(S(ii).type, "()") && ~iscell(S(ii).subs)
        error(message("MATLAB:subsSmoothTypeSubsMustBeCell"));
    end
end
end