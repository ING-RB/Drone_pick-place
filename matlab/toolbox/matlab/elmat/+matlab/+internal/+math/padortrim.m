function B = padortrim(allowPad,allowTrim,A,M,varargin)
%PADORTRIM   Pad or trim elements.
%
%   For use in resize, paddata, and trimdata.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023-2024 The MathWorks, Inc.

numNVs = numel(varargin);
if rem(numNVs,2) ~= 0
    throwAsCaller(MException(message('MATLAB:resize:KeyWithoutValue')));
end

if matlab.indexing.isScalarClass(A)
    throwAsCaller(MException(message('MATLAB:resize:ScalarClass',class(A))));
end

if isempty(M) || ~(isvector(M) && isnumeric(M) && isreal(M) && allfinite(M) && ...
        all(M >= 0) && all(M == fix(M)))
    throwAsCaller(MException(message('MATLAB:resize:InvalidLength')));
end

AisTabular = istabular(A);
if AisTabular && numel(M)>2
    throwAsCaller(MException(message('MATLAB:resize:DimOnTable')));
end
M = reshape(M,1,[]);

useDefaultDim = true;
fillval = []; % empty fillval indicates to use the default fill value
useDefaultFillVal = true;
fillvalIsSet = false;
patternIsSet = false;
indPattern = [true false false false false];
indSide = [true false false];
validPatterns = ["constant" "edge" "circular" "flip" "reflect"];
validSides = ["trailing" "leading" "both"];
if allowPad
    NVnames = ["Dimension" "Side" "FillValue" "Pattern"];
    errid = "MATLAB:resize:ParseFlagsPad";
else
    NVnames = ["Dimension" "Side"];
    errid = "MATLAB:resize:ParseFlagsTrim";
end

% Parse name-value arguments
for k = 1:2:numNVs
    NVind = matlab.internal.math.checkInputName(varargin{k},NVnames);
    if nnz(NVind) ~= 1
        error(message(errid));
    end
    if NVind(1) % Dimension
        dim = varargin{k+1};
        useDefaultDim = matlab.internal.math.checkInputName(dim,"auto");
        if ~useDefaultDim
            if isempty(dim) || ~(isvector(dim) && isnumeric(dim) && isreal(dim) && allfinite(dim) ...
                    && all(dim > 0) && all(dim == fix(dim)) && numel(unique(dim))==numel(dim))
                throwAsCaller(MException(message('MATLAB:resize:InvalidDim')));
            end
            if ~isscalar(M) && numel(dim)~=numel(M)
                throwAsCaller(MException(message('MATLAB:resize:WrongNumberVecDim')));
            end
            if AisTabular && any(dim > 2)
                throwAsCaller(MException(message('MATLAB:resize:DimOnTable')));
            end
        end
        dim = reshape(dim,1,[]);
    elseif NVind(2) % Side
        indSide = matlab.internal.math.checkInputName(varargin{k+1},validSides);
        if nnz(indSide) ~= 1
            throwAsCaller(MException(message('MATLAB:resize:InvalidSide')));
        end
    elseif NVind(3) % FillValue
        fillval = varargin{k+1};
        useDefaultFillVal = isDefaultFill(fillval);
        if ~useDefaultFillVal
            if AisTabular
                if isscalar(fillval) || (ischar(fillval) && isrow(fillval))
                    % fillval must be checked against each variable of A
                    fillval = repelem({fillval},width(A));
                    doCheck = true(1,width(A));
                elseif iscell(fillval) && isvector(fillval) && numel(fillval)==width(A)
                    % fillval{ii} only needs to be checked if it's not []
                    doCheck = ~cellfun(@isDefaultFill,fillval);
                else
                    throwAsCaller(MException(message('MATLAB:resize:InvalidFillValueTable',width(A))));
                end

                % Check type in each cell of fillval against each variable of A
                for ii = 1:width(A)
                    if doCheck(ii)
                        try
                            var = A.(ii);
                            fillval{ii} = checkConstantType(var,fillval{ii});
                        catch ME
                            varNames = A.Properties.VariableNames;
                            throwAsCaller(MException(message('MATLAB:resize:FillValueTypeForTableVariable',varNames{ii})));
                        end
                    end
                end
            else
                if ~(isscalar(fillval) || (ischar(fillval) && isrow(fillval)))
                    throwAsCaller(MException(message('MATLAB:resize:InvalidFillValueArray')));
                end
                try
                    fillval = checkConstantType(A,fillval);
                catch ME
                    throwAsCaller(MException(message('MATLAB:resize:FillValueType')));
                end
            end
        end
        fillvalIsSet = true;
    else % Pattern
        indPattern = matlab.internal.math.checkInputName(varargin{k+1},validPatterns);
        if nnz(indPattern) ~= 1
            throwAsCaller(MException(message('MATLAB:resize:InvalidPattern')));
        end
        if ~indPattern(1) && isempty(A)
            throwAsCaller(MException(message('MATLAB:resize:PatternMustBeConstant')));
        end
        patternIsSet = true;
    end
end

if patternIsSet && fillvalIsSet
    throwAsCaller(MException(message('MATLAB:resize:PatternAndFillValue')));
end

if useDefaultDim
    if isscalar(M)
        if AisTabular
            dim = 1;
        else
            dim = matlab.internal.math.firstNonSingletonDim(A);
        end
    else
        dim = 1:numel(M);
    end
end

% Calculate total padding and trimming needed
szdimA = size(A,dim);
numNeeded = M - szdimA;
idxToTrim = numNeeded < 0;
idxToPad = numNeeded > 0;
if AisTabular && allowPad && any(dim(idxToPad)>1)
    throwAsCaller(MException(message('MATLAB:resize:PaddingVariables')));
end

% Determine length before (KLead) and after (KTrail) A
numNeeded = abs(numNeeded);
if indSide(1) % trailing
    KTrail = numNeeded;
    KLead = zeros(1,numel(numNeeded)); 
elseif indSide(2) % leading
    KLead = numNeeded;
    KTrail = zeros(1,numel(numNeeded));
else % both
    KTrail = round(0.5 .* numNeeded);
    KLead = numNeeded - KTrail;
end

% If we are just changing the length of a vector, we can simplify the indexing code.
doResizeVector = ~AisTabular && ((isrow(A) && isequal(dim,2)) || (iscolumn(A) && isequal(dim,1)));

% Padding has a special case when A is 0x0 and M is all nonzero. Store this info before trimming.
isEmptySpecialCase = isequal(size(A),[0 0]) && all(M);

% Trim data
if allowTrim && any(idxToTrim)
    dimToTrim = dim(idxToTrim);
    idxStart = KLead(idxToTrim) + 1;
    idxEnd = szdimA(idxToTrim) - KTrail(idxToTrim);

    if doResizeVector
        A = A(idxStart:idxEnd);
    else
        % r holds the input arguments for indexing into A. Dimensions that are not trimmed will be ':'.
        r(1:max([dimToTrim ndims(A)])) = {':'};
        for k = 1:numel(dimToTrim)
            % Set indexing expression for dimensions that need to be trimmed.
            r{dimToTrim(k)} = idxStart(k):idxEnd(k);
        end
        % Index
        A = A(r{:});
    end

    % Trim fill values if needed
    if AisTabular && ~useDefaultFillVal && isequal(dimToTrim,2)
        fillval = fillval(idxStart:idxEnd);
    end
end

% Pad data
if allowPad && any(idxToPad)
    dim = dim(idxToPad);
    szdimA = szdimA(idxToPad);
    KLead = KLead(idxToPad);
    KTrail = KTrail(idxToPad);

    if indPattern(1) % constant
        if ~isscalar(M)
            M = M(idxToPad);
        end
        if AisTabular
            % dim is 1, and M is a scalar number of rows
            B = lengthenVar(A,M);
            if KLead>0 || ~useDefaultFillVal
                for ii = 1:width(A)
                    if useDefaultFillVal
                        fv = [];
                    else
                        fv = fillval{ii};
                    end
                    var = A.(ii);
                    if istabular(var)
                        % Nested table
                        try
                            B.(ii) = matlab.internal.math.padortrim(allowPad,allowTrim,var,M,...
                                Side=validSides(indSide),FillValue=fv);
                        catch ME
                            varNames = A.Properties.VariableNames;
                            throwAsCaller(addCause(MException(message('MATLAB:resize:PadFailedForTableVariable',varNames{ii})),ME));
                        end
                    else
                        B.(ii) = fillArrayWithConstant(var,M,dim,szdimA,KLead,fv,iscolumn(var),isEmptySpecialCase);
                    end
                end
            end
        else
            B = fillArrayWithConstant(A,M,dim,szdimA,KLead,fillval,doResizeVector,isEmptySpecialCase);
        end
    elseif indPattern(2) % edge
        if doResizeVector
            B = A([repelem(1,KLead) 1:szdimA repelem(szdimA,KTrail)]);
        else
            % s holds the input arguments for indexing into A. Dimensions that are not padded will be ':'.
            s(1:max([dim ndims(A)])) = {':'};
            for k = 1:numel(dim)
                % Set indexing expression for dimensions that need to be padded.
                lengthA = szdimA(k);
                idx = [repelem(1,KLead(k)) 1:lengthA repelem(lengthA,KTrail(k))];
                s{dim(k)} = idx;
            end
    
            % Index
            B = A(s{:});
        end
    else
        % s holds the input arguments for indexing into A. Dimensions that are not padded will be ':'.
        s(1:max([dim ndims(A)])) = {':'};
        for k = 1:numel(dim)
            lengthA = szdimA(k);

            % Set the mask according to the specified pattern.
            if indPattern(3) % circular
                mask = 1:lengthA;
            elseif indPattern(4) % flip
                mask = [1:lengthA lengthA:-1:1];
            else % reflect
                % Edge values are not duplicated
                mask = [1:lengthA (lengthA-1):-1:2];
            end

            % Calculate the indices for the output.
            % First, get the sequence for the desired length.
            idx = -KLead(k):(lengthA + KTrail(k) - 1);

            % Then, index into the mask. Use mod to repeat the pattern as needed.
            idx = mask(mod(idx, numel(mask)) + 1);

            % Set indexing expression for dimensions that need to be padded.
            s{dim(k)} = idx;
        end
        
        % Index
        B = A(s{:});
    end
    if AisTabular
        B = adjustRowLabels(A,B,KLead);
    end
else
    B = A;
end
end
%--------------------------------------------------------------------------
function B = fillArrayWithConstant(A,M,dim,szdimA,KLead,V,doResizeVector,isSpecialCase)
szB = size(A);
ndimsA = ndims(A);
if isSpecialCase
    % Special case 0x0 returns Nx1, rather than Nx0
    szB = szB + 1;
end

% pad szB with trailing 1s if the specified dim > ndims(A)
szB = [szB ones(1,max(dim)-ndimsA)];

% Preallocate output
szB(dim) = M;
if isempty(V)
    % We know the default fill value should be used due to input checking.
    B = defaultArray(A,szB);
else
    % We know V has the same type as A due to input checking.
    B = repmat(V,szB);
end

% Index
if doResizeVector
    r = (1:szdimA) + KLead;
    B(r) = A;
else
    r(1:max([dim ndimsA])) = {':'};
    for k = 1:numel(dim)
        r{dim(k)} = (1:szdimA(k)) + KLead(k);
    end
    B(r{:}) = A;
end
end
%--------------------------------------------------------------------------
function B = defaultArray(A,szB)
%      Array Class            Fill Value
%      ---------------------------------------------
%      double, single         0
%      duration               0
%      calendarDuration       0
%      datetime               NaT
%      int8, ..., uint64      0
%      logical                false
%      categorical            <undefined>
%      char                   char(0)
%      cellstr                {[]}
%      cell                   {[]}
%      string                 <missing>
%      struct                 struct with [] in fields
%      enumeration            first enumeration value listed in class definition
%      other                  the default value

n = szB(1);
p = prod(szB(2:end));
if (isnumeric(A) || islogical(A)) && ~isenum(A)
    B = zeros(szB,'like',A);
elseif iscategorical(A) || isdatetime(A) || isstring(A)
    B = A(1:0); % preserve attributes
    if n*p > 0
        B(n,p) = missing; % automatically in-fills with missing
    end
    B = reshape(B,szB);
elseif isduration(A) || iscalendarduration(A)
    B = A(1:0); % preserve the format
    if n*p > 0
        B(n,p) = 0;
    end
    B = reshape(B,szB);
elseif iscell(A)
    B = A(1:0); % preserve attributes
    if n*p > 0
        B(n,p) = {[]};
    end
    B = reshape(B,szB);
elseif ischar(A)
    B = A(1:0); % preserve attributes
    if n*p > 0
        B(n,p) = char(0);
    end
    B = reshape(B,szB);
elseif isenum(A)
    B = repmat(matlab.lang.internal.getDefaultEnumerationMember(A),szB);
elseif isstruct(A)
    fnames = fieldnames(A);
    B = repmat(cell2struct(cell(size(fnames)),fnames),szB);
else % fallback for unrecognized types
    % Create an empty version of the input, then assign off the end to let the
    % class decide how it wants to fill in default values. That may or may not
    % be the same as what the class constructor returns for no inputs.
    B = A(1:0);
    if n*p > 0
        % If the output is non-empty, get a scalar value of the template array type.
        if isempty(A)
            % There's no existing value to get, so get one from the ctor if possible.
            % This does not copy any metadata from A that should be preserved.
            try
                x0 = feval(class(A));
            catch ME
                throwAsCaller(addCause(MException(message('MATLAB:resize:ObjectConstructorFailed',class(A))),ME));
            end
            if isempty(x0)
                % If the ctor's default behavior returns an empty, there's no way to
                % create a non-empty instance.
                throwAsCaller(MException(message('MATLAB:resize:ObjectConstructorReturnedEmpty',class(A))));
            end
        else
            x0 = A(1);
        end
        % Assign the value just past the desired end to fill the previous elements with
        % their default values. That scalar value will be thrown away, so it doesn't
        % matter what it is.
        B(n*p+1) = x0;
    end
    % Reshape the default elements to the output size
    B = reshape(B(1:n*p),szB); % fails if the class does not support reshape
end
end
%--------------------------------------------------------------------------
function fillval = checkConstantType(X,c)
% Cast constant c to match X's type
if istabular(X)
    % The input data is a nested table, and X is a tabular variable.
    % c will be checked later when we recursively pad each nested tabular variable.
    fillval = c;
else
    fillval = X(1:0); % preserve the type
    fillval(1) = c;
end
end
%--------------------------------------------------------------------------
function B = adjustRowLabels(A,B,KLead)
if istimetable(A)
    if ismissing(A([],[]).Properties.TimeStep)
        % Input has explicit row times. Fill the padded row times with NaN/NaT.
        rowLabels = A.Properties.RowTimes(1:0); % preserve the format and/or time zone
        rowLabels(1:height(B),1) = missing;
        rowLabels(KLead+1:KLead+height(A)) = A.Properties.RowTimes;
        B.Properties.RowTimes = rowLabels;
    else
        B.Properties.StartTime = A.Properties.StartTime - KLead*A.Properties.TimeStep;
        B.Properties.TimeStep = A.Properties.TimeStep;
    end 
elseif ~isempty(A.Properties.RowNames)
    % Create labels, such as "Row1" in English
    prefix = getString(message('MATLAB:table:uistrings:DfltRowNamePrefix'));
    leadingRowLabels = matlab.internal.datatypes.numberedNames(prefix,(1:KLead)',false);
    trailingRowLabels = matlab.internal.datatypes.numberedNames(prefix,(KLead+height(A)+1:height(B))',false);
    rowLabels = [leadingRowLabels; ...
        A.Properties.RowNames; ...
        trailingRowLabels];
    B.Properties.RowNames = matlab.lang.makeUniqueStrings(rowLabels,[1:KLead KLead+height(A)+1:height(B)]);
end

% Adjust labels of nested tables
for ii = 1:width(B)
    if istabular(B.(ii))
        B.(ii) = adjustRowLabels(A.(ii),B.(ii),KLead);
    end
end
end
%--------------------------------------------------------------------------
function TF = isDefaultFill(fillval)
TF = isempty(fillval) && isa(fillval,'double');
end