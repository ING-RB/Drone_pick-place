function B = isbetweenInternal(A,convertedA,LB,UB,datavariables,AisTabular,tabularBounds,intervalType,outputIsLogical,outputFormatAllowed)
% isbetweenInternal Helper function for isbetween and allbetween
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

if ~AisTabular
    B = isInRange(A,A,LB,UB,intervalType,tabularBounds,AisTabular);
else
    selectedT = isInRange(A(:,datavariables),convertedA,LB,UB,intervalType,tabularBounds,AisTabular);

    if ~outputFormatAllowed % allbetween: OutputFormat not supported
        B = selectedT.Variables;
    elseif ~outputIsLogical % isbetween: tabular output format
        B = selectedT;
    else % isbetween: logical output format
        B = false(size(A));
        B(:,datavariables) = selectedT.Variables;
    end
end
end

function tf = isInRange(A,convertedA,LB,UB,intervalType,tabularBounds,AisTabular)
try
    % When convertedA is a table converted from a timetable A, all metadata is
    % preserved by doing the left comparion on the original timetable and the
    % right on the converted table.
    switch intervalType
        case "closed"
            tf = LB <= A & convertedA <= UB;
        case "open"
            tf = LB < A  & convertedA < UB;
        case {"closedleft","openright"}
            tf = LB <= A & convertedA < UB;
        case {"openleft","closedright"}
            tf = LB < A  & convertedA <= UB;
    end

catch ME
    if strcmp(ME.identifier,"MATLAB:dimagree") || strcmp(ME.identifier,"MATLAB:sizeDimensionsMustMatch")
        ME = MException(message("MATLAB:isbetween:IncompatibleSizes"));
    elseif strcmp(ME.identifier,"MATLAB:math:mustBeNumericCharOrLogical")
        ME = MException(message("MATLAB:isbetween:InvalidObjects"));
    elseif AisTabular && ~tabularBounds && ~isscalar(unique(varfun(@class,A,'OutputFormat','cell')))
        ME = MException(message("MATLAB:isbetween:TabularBoundsRequired"));
    end
    throw(ME);
end
end