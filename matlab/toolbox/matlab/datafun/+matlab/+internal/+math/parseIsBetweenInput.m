function [selectedT,LB,UB,datavariables,AisTabular,tabularBounds,defaultInterval,outputIsLogical] = parseIsBetweenInput(A,LB,UB,outputFormatAllowed,varargin)
% parseIsBetweenInput Helper function for isbetween, allbetween and mustBeBetween.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2024 The MathWorks, Inc.

selectedT = A;
datavariables = [];
dataVarsProvided = false;
AisTabular = istabular(A);
LBisTabular = istabular(LB);
UBisTabular = istabular(UB);
tabularBounds = LBisTabular && UBisTabular;
LBorUBIsTabular = LBisTabular || UBisTabular;
outputIsLogical = true;
defaultInterval = "closed";

if ~AisTabular && LBorUBIsTabular
    error(message("MATLAB:isbetween:InvalidBoundsForNontabularInputs"));
end

indStart = 1;
if nargin > 4
    validIntervalTypes = ["closed","open","openright","closedleft","openleft","closedright"];
    flag = varargin{indStart};

    % Parse intervalType
    intervalTypeIndx = matlab.internal.math.checkInputName(flag,validIntervalTypes,5);
    if nnz(intervalTypeIndx) > 1
        % 5 as length-to-match works for the values with "open", but
        % returns 3 trues if intervalType is "closed", so using 7 instead
        % when this happens.
        intervalTypeIndx = matlab.internal.math.checkInputName(flag,validIntervalTypes,7);
    end
    isflag = any(intervalTypeIndx);

    if isflag
        defaultInterval = validIntervalTypes(intervalTypeIndx);
        indStart = indStart + 1;
    elseif nargin == 5
        error(message("MATLAB:isbetween:InvalidIntervalType"));
    end

    % Parse name-value pairs
    nvp = varargin(indStart:end);
    if rem(numel(nvp),2) ~= 0
        error(message("MATLAB:isbetween:ArgNameValueMismatch"));
    end

    if outputFormatAllowed
        NVP = ["DataVariables","OutputFormat"];
    else
        NVP = "DataVariables";
    end
    if ~isempty(nvp)
        for ii = 1:2:numel(nvp)
            name = nvp{ii};
            nameIndx = matlab.internal.math.checkInputName(name,NVP);

            if isscalar(nameIndx)
                if nameIndx % DataVariables
                    if ~AisTabular
                        % DataVariables is only supported for tabular inputs
                        error(message("MATLAB:isbetween:InvalidInputTypeForNVArguments"));
                    end
                    datavariables = matlab.internal.math.checkDataVariables(A,nvp{ii+1},"isbetween");
                    dataVarsProvided = true;
                else
                    error(message("MATLAB:isbetween:UnknownParameterForAllbetween"));
                end
            else
                if nameIndx(1) % DataVariables
                    if ~AisTabular
                        % DataVariables is only supported for tabular inputs
                        error(message("MATLAB:isbetween:InvalidInputTypeForNVArguments"));
                    end
                    datavariables = matlab.internal.math.checkDataVariables(A,nvp{ii+1},"isbetween");
                    dataVarsProvided = true;
                elseif nameIndx(2) % OutputFormat
                    fmt = matlab.internal.math.checkInputName(nvp{ii+1}, {'logical','tabular'});
                    if ~any(fmt)
                        error(message("MATLAB:isbetween:InvalidOutputFormat"));
                    end
                    outputIsLogical = fmt(1);
                else
                    error(message("MATLAB:isbetween:UnknownParameter"));
                end
            end
        end
    end
end

if AisTabular && ~dataVarsProvided
    datavariables = 1:width(A);
end

if ~AisTabular && ~outputIsLogical
    error(message("MATLAB:isbetween:InvalidTabularOutputFormat"));
end

if LBorUBIsTabular
    tnames = A.Properties.VariableNames;
    if tabularBounds
        names = LB.Properties.VariableNames;
        unames = UB.Properties.VariableNames;
    elseif LBisTabular
        names = LB.Properties.VariableNames;
    elseif UBisTabular
        names = UB.Properties.VariableNames;
    end
    if dataVarsProvided
        varNames = string(tnames(datavariables));
        if ~all(matches(varNames,names)) || (tabularBounds && ~all(matches(varNames,unames)))
            % DataVariables must match the variable names in the bounds or is a subset.
            error(message("MATLAB:isbetween:InvalidTabularBoundsWithDataVars"));
        end
    else
        if tabularBounds && ~isempty(setxor(names,unames))
            % If DataVariables are not set and tabular bounds contain the same
            % subset of variables from the input. Use the variables in tabular
            % bounds as the selected DataVariables.
            error(message("MATLAB:isbetween:InvalidTabularBounds"));
        end
        try
            datavariables = matlab.internal.math.checkDataVariables(A,names);
            varNames = string(tnames(datavariables));
        catch
            error(message('MATLAB:isbetween:InvalidTabularBoundsFirstInput'));
        end
    end
end

if AisTabular
    if outputIsLogical
        % Table variables to operate on can't be multi-column or tabular
        % when OutputFormat is logical or when OutputFormat is not supported.
        % Same is true for tabular bounds.
        for jj = 1:numel(datavariables)
            varData = A.(datavariables(jj));
            if (~isempty(varData) && varIsNestedOrMultiColumn(varData))||...
                    (LBisTabular && varIsNestedOrMultiColumn(LB.(varNames(jj))))||...
                    (UBisTabular && varIsNestedOrMultiColumn(UB.(varNames(jj))))
                if outputFormatAllowed
                    error(message('MATLAB:isbetween:InvalidTableVars'));
                else
                    error(message('MATLAB:isbetween:InvalidTableVarsForAllbetween'));
                end
            end
        end
    end

    selectedT = selectedT(:,datavariables);

    if istimetable(A)
        if anymissing(A.Properties.RowTimes)
            % For timetables with missings in RowTimes, we cannot
            % combine two operations like tf = LB < tt & tt < UB since
            % tabular operations require matching row times (and
            % missing ~= missing). Convert to tables to allow the
            % isInRange operation. If we need tabular output,
            % appropriate metadata will be added back in later.
            selectedT = timetable2table(selectedT,'ConvertRowTimes',false);
        end
    end

    if LBisTabular
        LB = LB(:,varNames);
    end
    if UBisTabular
        UB = UB(:,varNames);
    end
end

end

function NestedOrMultiColumn = varIsNestedOrMultiColumn(input)
NestedOrMultiColumn = ~iscolumn(input) || istabular(input);
end