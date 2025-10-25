function B = clip(A,LB,UB,varargin)
% Syntax:
%     B = clip(A,LB,UB)
%     B = clip(___,Name=Value)
%
%     Name-Value Arguments for tabular inputs:
%         DataVariables
%         ReplaceValues
%
% For more information, see documentation

%   Copyright 2023-2024 The MathWorks, Inc.

[LB,UB,AisTabular,tabularBounds,datavariables,varNames,replace] = parseInput(A,LB,UB,varargin);


if ~AisTabular
    B = clipToRange(A,LB,UB,AisTabular,tabularBounds);

    if ~isequal(size(B),size(A))
        error(message('MATLAB:clip:IncompatibleSizes'));
    end
else
    if tabularBounds
        selectedT = clipToRange(A(:,datavariables),LB(:,datavariables),UB(:,datavariables),...,
            AisTabular,tabularBounds);
    else
        selectedT = clipToRange(A(:,datavariables),LB,UB,AisTabular,tabularBounds);
    end

    for clippedVar = varNames
        % Preserve output size for each variable
        if ~isequal(size(A.(clippedVar)),size(selectedT.(clippedVar)))
            error(message("MATLAB:clip:IncompatibleSizes"));
        end
    end

    if replace
        B = A;
        B(:,datavariables) = selectedT;
    else
        B = matlab.internal.math.appendDataVariables(A,selectedT,"clipped");
    end
end

end

function B = clipToRange(A,LB,UB,AisTabular,tabularBounds)
try
    B = min(max(A,LB,"includemissing"),UB,"includemissing");
catch ME
    if (strcmp(ME.identifier,'MATLAB:sizeDimensionsMustMatch')) ||...
            (strcmp(ME.identifier,'MATLAB:table:math:ArrayWrongHeight'))
        cause = MException(message("MATLAB:clip:IncompatibleSizes"));
        ME = addCause(ME,cause);
    elseif AisTabular && ~tabularBounds && ~isscalar(unique(varfun(@class,A,'OutputFormat','cell')))
            cause = MException(message("MATLAB:clip:TabularBoundsRequired"));
            ME = addCause(ME,cause);
    end
    
    throw(ME);
end
end

function [LB,UB, AisTabular,tabularBounds,datavariables,varNames,replace] = parseInput(A,LB,UB,nvp)
datavariables = [];
replace = true;
dataVarsProvided = false;
AisTabular = istabular(A);
tabularBounds = istabular(LB) && istabular(UB);
varNames = "";

if ~AisTabular
    if ~isempty(nvp)
        % NV pairs are not supported for non-tabular inputs
        error(message('MATLAB:clip:InvalidInputTypeForNVArguments'))
    end

     if tabularBounds
        % tabular bounds are not supported for non-tabular inputs
        error(message('MATLAB:clip:InvalidBoundsForNontabularInputs'))
    end
    
    [LB,UB] = validateInputs(A,LB,UB);
else
    if ~isempty(nvp)
        % Parse NV pairs for tabular inputs
        inputlen = numel(nvp);
        if rem(inputlen,2) ~= 0
            error(message('MATLAB:clip:ArgNameValueMismatch'))
        end
        for ii = 1:2:inputlen
            name = nvp{ii};
            nameInd = matlab.internal.math.checkInputName(name,{'DataVariables','ReplaceValues'},1);
            if nameInd(1) % DataVariables
                datavariables = matlab.internal.math.checkDataVariables(A,nvp{ii+1},'clip');
                dataVarsProvided = true;
            elseif nameInd(2) % ReplaceValues
                replace = matlab.internal.datatypes.validateLogical(nvp{ii+1},'ReplaceValues');
            else
                error(message('MATLAB:clip:UnknownParameter'));
            end
        end
    end
    
    tnames = A.Properties.VariableNames;
    if tabularBounds
        lnames = LB.Properties.VariableNames;
        unames = UB.Properties.VariableNames;
        if dataVarsProvided
            % When both DataVariables and tabular bounds are specified,
            % make sure DataVariables are a subset of variable names in
            % the bounds.
            varNames = tnames(datavariables);

            if ~all(ismember(varNames,lnames)) || ~all(ismember(varNames,unames))
                error(message('MATLAB:clip:InvalidTabularBoundsWithDataVars'));
            end
        else
            % If DataVariables are not set and tabular bounds contain the same
            % subset of variables from the input. Use the variables in tabular
            % bounds as the selected DataVariables.
            if ~isempty(setxor(lnames,unames))
                error(message('MATLAB:clip:InvalidTabularBounds'));
            end
            try
                datavariables = matlab.internal.math.checkDataVariables(A, lnames, 'clip');
                dataVarsProvided = true;
            catch
                error(message('MATLAB:clip:InvalidTabularBoundsFirstInput'));
            end
        end
    end

    if ~dataVarsProvided
        datavariables = 1:width(A);
    end

    dataT = A(:,datavariables);
    varNames = string(tnames(datavariables));

    if ~tabularBounds
        if isempty(varNames)
            [LB,UB] = validateInputs([],LB,UB);
        else
            for tvar = varNames
                data = dataT.(tvar);
                [LB,UB] = validateInputs(data,LB,UB);
            end
        end
    else
        for tvar = varNames
            data = dataT.(tvar);
            [LB.(tvar),UB.(tvar)] = validateInputs(data,LB.(tvar),UB.(tvar));
        end
    end
end
end

function [LB,UB] = validateInputs(data,LB,UB)

if ischar(data)
    error(message('MATLAB:clip:CharInputsNotSupported'));
end

if anymissing(LB) || anymissing(UB)
    error(message('MATLAB:clip:InvalidBounds'));
end

numericInputs = isnumeric(data) && isnumeric(LB) && isnumeric(UB);
if numericInputs
    if ~isreal(data) || ~isreal(LB) || ~isreal(UB)
        error(message("MATLAB:clip:ComplexNumbersNotSupported"));
    end
else
    if ~isequal(class(LB),class(UB))
        % Only numeric inputs can have mixed types
        error(message("MATLAB:clip:BoundsDatatypesMismatch"));
    end
end

% Validate bounds before casting
if istabular(LB)
     [LB, UB] = validateNestedBounds(LB,UB);
else
    [LB, UB] = validateNumericBounds(LB,UB);
end

if numericInputs && (~isequal(class(LB),class(data)) || ~isequal(class(UB),class(data)))
    % Preserve type of the first input
    LBNew = castLowerBound(LB,data);
    UBNew = castUpperBound(UB,data);

    if any(isfinite(LB) & ~isfinite(LBNew),'all')
        % For cases like clip(single(1),1e40,1e50),
        % fail to clip data to the specified range
        % since bounds are greater than max value of the input type
        error(message("MATLAB:clip:BoundsPrecisionLoss"));
    end

    if any(isfinite(UB) & ~isfinite(UBNew),'all')
        % For cases like clip(single(1),-1e50,-1e40),
        % fail to clip data to the specified range
        error(message("MATLAB:clip:BoundsPrecisionLoss"));
    end
    LB = LBNew;
    UB = UBNew;
end
end

function LBNew = castLowerBound(LB,data)
LBNew = cast(LB,"like",data);
if all(LBNew >= LB,'all')
    return
end
if isfloat(LBNew)
    finiteIdx = isfinite(LBNew);
    % For cases like clip(single([-inf 100]),-1e300,0)
    % LBNew is single -Inf, round up LB
    LBNew(~finiteIdx) = -realmax("like",data);

    % For cases like clip(-single(0.1),0.01,0.4), round up LB so that
    % LBNew + eps is closer to the first input
    LBNew(finiteIdx) = LBNew(finiteIdx) + eps(LBNew(finiteIdx));
else
    if any(LBNew == intmax("like",data),'all')
        % For cases like clip(uint8(255),260,270),
        % fail to clip data to the specified range
        error(message("MATLAB:clip:BoundsPrecisionLoss"));
    end
    % For cases like clip(uint8(5),4.1,7), round up LB
    LBNew = LBNew + 1; 
end
end

function UBNew = castUpperBound(UB,data)

UBNew = cast(UB,"like",data);
if all(UBNew <= UB,'all')
    return
end
if isfloat(UBNew)
    finiteIdx = isfinite(UBNew);

    % For cases like clip(single([100 inf]),0,1e300),
    % UBNew is single Inf, round down UB
    UBNew(~finiteIdx) = realmax("like",data);
    % For cases like clip(-single(0.1),0,0.1), round down UB
    UBNew(finiteIdx) = UBNew(finiteIdx) - eps(UBNew(finiteIdx));
else
    if any(UBNew == intmin("like",data),'all')
        % For cases like clip(uint8(5),-10,-5), 
        % fail to clip data to the specified range 
        error(message("MATLAB:clip:BoundsPrecisionLoss"));
    end
    % For cases like clip(uint8(5),4,6.9), round down UB
    UBNew = UBNew - 1; 
end
end

function [LB, UB] = validateNestedBounds(LB,UB)

if ~isequal(size(LB),size(UB))
    error(message('MATLAB:clip:InvalidSizesInTabularBounds'));
end

for ii = 1:width(LB)
    if istabular(LB.(ii))
        [LB.(ii), UB.(ii)] = validateNestedBounds(LB.(ii),UB.(ii));
    else
        [LB.(ii), UB.(ii)] = validateNumericBounds(LB.(ii),UB.(ii));
    end
end

end

function [LB, UB] = validateNumericBounds(LB,UB)
try
    if any(LB > UB,'all')
        error(message('MATLAB:clip:InvalidLowerBound'));
    end
catch ME
    if (strcmp(ME.identifier,'MATLAB:sizeDimensionsMustMatch'))
        cause = MException(message("MATLAB:clip:IncompatibleBounds"));
        ME = addCause(ME,cause);
    end
    throw(ME);
end
end