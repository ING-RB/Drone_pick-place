function b = mean(a,dim,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isValidDimArg

omitMissing = false;
hasWeights = false;
if nargin == 1 % mean(a)
    haveDim = false;
else
    [haveDim,allFlag] = isValidDimArg(dim); % positive scalar or 'all'
    if haveDim % mean(a,dim) or mean(a,dim,missingFlag) or mean(a,dim,missingFlag,type) or mean(...,Weights=w)
        if allFlag
            a = reshape(a,[],1);
            dim = 1;
        end
        nopts = nargin - 2;
    elseif (nargin < 6) && isScalarText(dim) % might be mean(a,<anything but dim>)
        % dim input must actually be a flag.
        varargin = [{dim}, varargin];
        nopts = nargin - 1;
        dim = matlab.internal.math.firstNonSingletonDim(a);
    else % The 6-input syntax would have to have included dim, but it's not there or invalid.
        error(message('MATLAB:datetime:InvalidVecDim'));
    end

    % What remains must be flags or Weights parameter
    if nopts > 0
        % Look for Weights NV pair first. NV pairs must always follow positional
        % arguments/flags.
        idx = 1;
        while idx <= nopts
            if nopts > 1 && strncmpi(varargin{idx},'Weights',max(1,strlength(varargin{idx})))
                hasWeights = true;
                weights = varargin{idx+1}; % To be validated after determining omitMissing flag.
                nopts = nopts-2;
                varargin(idx:idx+1) = [];
            elseif ~isempty(varargin) && isScalarText(varargin{end}) && strncmpi(varargin{end},'Weights',max(1,strlength(varargin{end}))) % no weights values
                error(message("MATLAB:weights:ArgNameValueMismatch"))
            else
                idx = idx+1;
            end
        end

        if nopts > 0
            % Mean accepts 'native'/'default', but it has no effect, only need to
            % know that it was not 'double'.
            if haveDim % dim already found, don't suggest 'all'
                errID = "MATLAB:datetime:UnknownMeanOption";
            else
                errID = "MATLAB:datetime:UnknownMeanOptionAllFlag";
            end
            lookFor.missingFlag = true; lookFor.linearFlag = false; lookFor.outputFlag = true;
            [omitMissing,~,~,lookFor] = validateDatafunOptions(varargin{1},errID,lookFor);
            if nopts > 1
                % This is the second flag, never suggest 'all'.
                errID = "MATLAB:datetime:UnknownMeanOption";
                omitMissing2 = validateDatafunOptions(varargin{2},errID,lookFor);
                omitMissing = omitMissing || omitMissing2; % default is false, OR preserves existing non-default            
            end
            if nopts > 4
                error(message("MATLAB:TooManyInputs"))
            end
        end
        
        if hasWeights % After validateDatafunOptions so errors about flags get thrown first.
            weights = matlab.internal.datetime.validateWeights(weights,a,omitMissing,haveDim,allFlag,dim);
            % Normalize weights to reduce floating point errors
            % weights = weights./max(weights,[],dim);
            if omitMissing
                % Avoid NaN weights going into datetimeMean
                weights(ismissing(weights)) = 0;
            end
        end
    end
end

aData = a.data;
b = a;
if ~haveDim
    dim = []; % different empty behavior when dim not provided (represented as [])
elseif isempty(dim) % [] has already been dealt with. This is for 0x1 or 1x0
    return
end
if hasWeights
        b.data = matlab.internal.datetime.datetimeMean(aData,dim,omitMissing,weights);
else
    if numel(dim) > 1
        [aData,szOut] = permuteWorkingDims(aData,dim);    
        bData = matlab.internal.datetime.datetimeMean(aData,1,omitMissing);
        b.data = reshape(bData,szOut);
    else % scalar or []
        b.data = matlab.internal.datetime.datetimeMean(aData,dim,omitMissing);
    end
end
