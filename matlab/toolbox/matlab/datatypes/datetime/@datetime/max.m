function [c,i] = max(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.minMaxBinary
import matlab.internal.datetime.minMaxUnary
import matlab.internal.datatypes.isValidDimArg

narginchk(1,5);

% Defaults
haveDim = false;
allFlag = false;
omitMissing = true;
missingFlag = "omitmissing";
linearFlag = false;

if nargin == 1 % max(a)
    isUnary = true;
    aData = a.data;
elseif nargin == 2 % max(a,b), including max(a,[]) treated as binary
    isUnary = false;
    if nargout > 1
        error(message('MATLAB:datetime:TwoInTwoOutCaseNotSupported', 'MIN'));
    end
    [aData,bData,c] = datetime.compareUtil(a,b);
else % nargin > 2
    for ii = 1:(nargin-2) % max(...,'ComparisonMethod',method) is not supported
        if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
            error(message('MATLAB:max:InvalidAbsRealType'));
        end
    end

    % Validate two data inputs before any flags
    isUnary = isnumeric(b) && isequal(b,[]);
    if isUnary
        aData = a.data;
    else
        if nargout > 1
            error(message('MATLAB:datetime:TwoInTwoOutCaseNotSupported', 'MIN'));
        end
        [aData,bData,c] = datetime.compareUtil(a,b);
    end

    nextArg = varargin{1};
    [haveDim,allFlag] = isValidDimArg(nextArg); % positive scalar or 'all'
    if isUnary
        if haveDim
            if allFlag
                if isempty(a)
                    % To match numeric, make non-zero dim
                    % singleton before passing through MIN
                    aData = reshape(aData,size(aData)>0);
                else
                    aData = reshape(aData,[],1);
                end
                dim = 1;
            else
                dim = nextArg;
            end
            varargin(1) = [];
        elseif isnumeric(nextArg) % but not a positive integer (or vector of)
            error(message('MATLAB:datetime:InvalidVecDim'));
        end
    elseif haveDim % error for dim in binary syntax regardless of what follows
        error(message('MATLAB:datetime:TwoInWithDimCaseNotSupported'));
    end

    % What remains must be flags
    nflags = length(varargin);
    if nflags > 0
        % Give a context-sensitive err msg for unrecognized flags, 'all' and
        % 'linear' are not always legal inputs.
        if isUnary % 
            % Suggest 'linear' for one-input syntax, and 'all' even if haveDim, to
            % mimic core. missingflag and 'linear' are always accepted as the first flag
            % for unary, but will need err IDs for those on the second flag.
            errIDs = ["MATLAB:datetime:UnknownNaNFlagAllLinearFlag" "MATLAB:min:repeatedFlagNaN" "MATLAB:min:repeatedFlagLinear"];
        else
            % Don't suggest 'linear' or 'all' for two-input syntax. missingflag is always
            % accepted as the first flag, but will need err ID for that on the second
            % flag. linearFlag is never accepted for binary.
            errIDs = ["MATLAB:datetime:UnknownNaNFlag" "MATLAB:min:repeatedFlagNaN" "MATLAB:min:linearNotSupported"];
        end

        lookFor.missingFlag = true; lookFor.linearFlag = isUnary; lookFor.outputFlag = false;
        flagOne = varargin{1};
        isMinMax = true; % tell validateDatafunOptions to use min/max defaults
        [omitMissing,missingFlag,linearFlag,lookFor] = validateDatafunOptions(flagOne,errIDs,lookFor,isMinMax);
        if nflags > 1
            flagTwo = varargin{2};
            [omitMissing2,missingFlag2,linearFlag2] = validateDatafunOptions(flagTwo,errIDs,lookFor,isMinMax);
            % Update whichever option was set from flagTwo
            omitMissing = omitMissing && omitMissing2; % omitMissing2 default is true, AND preserves existing non-default
            if ~omitMissing2, missingFlag = missingFlag2; end % update only if non-default in flagTwo
            linearFlag = linearFlag || linearFlag2; % linearFlag2 default is false, OR preserves existing non-default
        end
    end
end

if isUnary
    if allFlag
        % 'all' does not require the 'linear' flag, but behave as if it was passed in
        linearFlag = true;
    elseif ~haveDim
        dim = find(size(aData)~=1,1);
        if isempty(dim), dim = 1; end
    end

    c = a;
    if isreal(aData)
        if nargout <= 1
            c.data = max(aData,[],dim,missingFlag);
        else
            if linearFlag
                [c.data,i] = max(aData,[],dim,missingFlag,'linear');
            elseif isscalar(dim)
                [c.data,i] = max(aData,[],dim,missingFlag);
            else % Matching numeric: 2nd output supported for vector DIM only with linear indices
                error(message('MATLAB:max:secondOutputNotSupported'));
            end
        end
    else
        if isscalar(dim)
            if nargout <= 1
                c.data = minMaxUnary(aData,dim,omitMissing,true,linearFlag);
            else
                [c.data,i] = minMaxUnary(aData,dim,omitMissing,true,linearFlag);
            end
        else
            
            if linearFlag
                linInds = aData;
                linInds(:) = 1:numel(aData); % Keep track of original linear index positions
            end
            
            [aData,szOut] = permuteWorkingDims(aData,dim);
            if nargout <= 1
                cData = minMaxUnary(aData,1,omitMissing,true,linearFlag);
                c.data = reshape(cData,szOut);
            elseif linearFlag
                linInds = permuteWorkingDims(linInds,dim);
                [cData,i] = minMaxUnary(aData,1,omitMissing,true,linearFlag);
                c.data = reshape(cData,szOut);
                i = linInds(i);
                i = reshape(i,szOut);
            else % Matching numeric: 2nd output supported for vector DIM only with linear indices
                error(message('MATLAB:max:secondOutputNotSupported'));
            end
        end
    end
else % ~isUnary
    if nargout > 1
        error(message('MATLAB:datetime:TwoInTwoOutCaseNotSupported', 'MAX'));
    end

    if isreal(aData) && isreal(bData)
        c.data = max(aData,bData,missingFlag);
    else
        c.data = minMaxBinary(aData,bData,omitMissing,true);
    end
end
