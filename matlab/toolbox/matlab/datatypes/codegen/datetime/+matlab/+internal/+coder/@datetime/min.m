function [c,iout] = min(a,b,dim,flagone,flagtwo) %#codegen
%MIN Find minimum of datetimes.

%   Copyright 2020-2023 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;
% Defaults
haveDim = false;
omitNan = true;
nanFlag = 'omitnan';
allFlag = false;
linearFlag = false;

if nargin == 1 % min(a)
    isUnary = true;
elseif nargin == 2 % min(a,b), including min(a,[])
    isUnary = false;
    coder.internal.errorIf(nargout>1,'MATLAB:datetime:TwoInTwoOutCaseNotSupported', 'MIN');
elseif nargin == 3
    isUnary = isnumeric(b) && isequal(b,[]);
    if isnumeric(dim) % min(a,[],dim) or invalid min(a,b,dim)
        coder.internal.assert(matlab.internal.coder.datatypes.isValidDimArg(dim),'MATLAB:datetime:InvalidVecDim');
        haveDim = true;
    else % min(a,[],'all'), min(a,[],natFlag), min(a,b,natFlag), or min(a,[],'linear')
        coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(dim,{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');
        [omitNan,nanFlag,allFlag,linearFlag] = validateMissingOptionAllFlag(dim,isUnary,isUnary);
        if allFlag, haveDim = true; end
    end
else % min(a,[],dim,natFlag), min(a,[],dim,natFlag,'linear'), min(a,[],dim,'linear',natFlag), or invalid min(a,b,...)
    isUnary = isnumeric(b) && isequal(b,[]);
    
    % Validate the dim argument.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(dim,{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');
    [validDim,allFlag] = matlab.internal.coder.datatypes.isValidDimArg(dim,false);
    coder.internal.assert(validDim,'MATLAB:datetime:InvalidVecDim');
    haveDim = true;

    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(flagone,{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');
    
    if nargin == 5
        coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(flagtwo,{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');

        % Check if the last input is 'linear'.
        linearFlag = strncmpi(flagtwo,{'linear'},max(length(flagtwo),1));
        if linearFlag
            % If the last input is 'linear', we need to check the second to
            % last input for the natFlag
            [omitNan,nanFlag] = validateMissingOption(flagone,isUnary);
        elseif strncmpi(flagone,{'linear'},max(length(flagone),1))
            % If the last input is not 'linear' and the number of inputs is
            % 5, then second to last input must be 'linear'.
            linearFlag = true;
            [omitNan,nanFlag] = validateMissingOption(flagtwo,isUnary);
        else
            if isUnary
                coder.internal.assert(false,'MATLAB:datetime:UnknownNaNFlagAllLinearFlag');
            else
                coder.internal.assert(false,'MATLAB:datetime:UnknownNaNFlag');
            end
        end
    elseif strncmpi(flagone,{'linear'},max(length(flagone),1)) % min(a,[],dim,'linear')
        linearFlag = true;
    else % min(a,[],dim,nanFlag)
        [omitNan,nanFlag] = validateMissingOption(flagone,isUnary);
    end
end



if haveDim
    coder.internal.assert(coder.internal.isConst(dim),'MATLAB:datetime:DimFlagConstCodegen');
end

if ~isUnary
    % If either a or b was passed in as a duration, give a specific error.
    coder.internal.errorIf((isa(a,'duration') || isa(b,'duration')),'MATLAB:datetime:CompareTimeOfDay');
end

coder.internal.assert(isUnary, 'MATLAB:datetime:BinaryMinMaxCodegen','min')
coder.internal.errorIf(linearFlag,'MATLAB:datetime:LinearFlagCodegen')


if ~haveDim && ~linearFlag && (~coder.internal.isConst(isvector(a)) || ~isvector(a))
    dimProcessed = coder.internal.nonSingletonDim(a.data);
    aProcessed = a;
elseif allFlag || (coder.internal.isConst(isvector(a)) && isvector(a) && ~haveDim)

    if ~(coder.internal.isConst(isempty(a)) && isempty(a))
        aProcessed = reshape(a,[],1);
    else
        aProcessed = a;
    end
    dimProcessed = 1;
else
    aProcessed = a;
    dimProcessed = dim;
end


if (coder.internal.isConst(isempty(a)) && isempty(a))
    if nargout > 1
        [templateData, iout] = min(a.data,[],dimProcessed,nanFlag);
    else 
        [templateData] = min(a.data,[],dimProcessed,nanFlag);
    end
    c = datetime.fromMillis(complex(templateData),a.fmt);
    return
end

c = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
c.fmt = a.fmt;
aData = aProcessed.data;
needsReshape = false;
if ~ischar(dimProcessed) && ~all(dimProcessed ==1)
    coder.internal.assert(all(size(aData,dimProcessed)), ...
        'Coder:toolbox:eml_min_or_max_varDimZero');
    [aDataPerm,szOut] = permuteWorkingDims(aData,dimProcessed);
    needsReshape = true;
else
    aDataPerm = aData;
    szOut = size(aData);
end

[cData,i] = matlab.internal.coder.datetime.minMaxUnary(aDataPerm,omitNan,false,linearFlag);
if needsReshape
    c.data = reshape(cData,szOut);
    iout = reshape(i,szOut);
else
    c.data = cData;
    iout = i;
end

end
