function meanX = mean(varargin)
%MEAN Average or mean value
%   S = MEAN(X)
%   S = MEAN(X,DIM)
%   S = MEAN(...,TYPE)
%   S = MEAN(...,MISSING)
%
%   Limitations:
%   1) The 'native' option is not supported for integer types.
%   2) The 'Weights' name-value argument is not supported.
%   See also MEAN, TALL.

%   Copyright 2015-2024 The MathWorks, Inc.

narginchk(1,inf);
tall.checkNotTall(upper(mfilename), 1, varargin{2:end});

% Weights are not supported for tall.
if ~isempty(find(cellfun(@(x) matlab.internal.math.checkInputName(x,'Weights'), varargin), 1))
    error(message('MATLAB:bigdata:array:WeightsUnsupported'));
end

% Use the in-memory version to check the arguments
outProto = tall.validateSyntax(@mean,varargin,'DefaultType','double');

[args, trailingArgs] = splitArgsAndFlags(varargin{:});
tall.checkIsTall(upper(mfilename), 1, args{1}); % we have checked that args 2:end are not tall.
x = args{1};

allowTabularMaths = true;
x = tall.validateType(x, mfilename, ...
                      {'numeric', 'logical', 'duration', 'datetime', 'char'}, ...
                      1, allowTabularMaths);
adaptor = args{1}.Adaptor;
[nanFlagCell, precisionFlagCell] = adaptor.interpretReductionFlags(upper(mfilename), trailingArgs);

% Integer inputs are not supported alongside the native flag.
if precisionFlagCell == "native"
    x = tall.validateTypeWithError(x, "mean", 1, ...
        ["double", "single", "logical", "duration", "datetime", "char"], ...
        'MATLAB:bigdata:array:MeanNativeIntegerUnsupported', allowTabularMaths);
end
assert(~isempty(nanFlagCell)); % We need the nan flag at the client to switch implementations.
nanFlag = nanFlagCell{1};

% If no dimension specified, try to deduce it (will be empty if we can't).
if isscalar(args)
    dim = matlab.bigdata.internal.util.deduceReductionDimension(adaptor);
else
    dim = args{2};
    % DIM is allowed to be a column or row vector. We want a row vector.
    if iscolumn(dim)
        dim = dim';
    end
end

if strcmp(adaptor.Class, "datetime")
    meanX = iDatetimeMean(x, dim, nanFlag);
else
    % General version
    meanX = iGeneralMean(x, dim, nanFlag, precisionFlagCell, outProto, mfilename);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanX = iGeneralMean(x, dim, nanFlag, precisionFlagCell, outProto, methodName)
% Common code for computing the mean.

if isequal(dim, [])
    % Default dimension

    % Compute adaptors for results from reduceInDefaultDim
    sumXAdaptor = computeSumResultType(x, precisionFlagCell, methodName);
    szInRedDimAdaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();

    if ismember(nanFlag, ["includenan", "includenat", "includemissing"])
        % Mean including all elements
        [result, resolvedDimension] = ...
            reduceInDefaultDim(@(x, dim) sum(x, dim, 'includenan', precisionFlagCell{:}), x);
        result = tall(result, sumXAdaptor);
        % Note: we don't care about the type of resolvedDimension ...
        resolvedDimension = tall(resolvedDimension);
        szTv = size(x);
        
        % ... but we do care about the type of sizeInReductionDimension as we need it
        % for the type of 'result' to propagate through the RDIVIDE call.
        sizeInReductionDimension = clientfun(@iGetSizeinDim, szTv, resolvedDimension);
        sizeInReductionDimension.Adaptor = szInRedDimAdaptor;
        meanX = iRdivide(result, sizeInReductionDimension);
    else
        % Mean excluding NaNs
        result = reduceInDefaultDim(@(x, dim) sum(x, dim, 'omitnan', precisionFlagCell{:}), x);
        result = tall(result, sumXAdaptor);
        meanX = iRdivide(result, sum(~iIsnan(x)));
    end
else
    % Specified dimension - note that here we rely on SUM and RDIVIDE to propagate
    % adaptors correctly where necessary to deal with duration.
    if ismember(nanFlag, ["includenan", "includenat", "includemissing"])
        % Mean including all elements
        meanX = iRdivide(sum(x, dim, 'includenan', precisionFlagCell{:}), elementsPerResult(x, dim));
    else
        % Mean excluding NaNs
        meanX = iRdivide(sum(x, dim, 'omitnan', precisionFlagCell{:}), sum(~iIsnan(x), dim));
    end
end

if istabular(x)
    % Reduction has modified the table variables or updated the tabular
    % properties. For timetables, mean returns a table. Copy from the
    % in-memory prototype.
    outProtoAdap = matlab.bigdata.internal.adaptors.getAdaptor(outProto);
    meanX.Adaptor = copyTallSize(outProtoAdap, meanX.Adaptor);
    % We also need to force the variable names into the underlying partitions.
    meanX = subsasgn(meanX, substruct(".","Properties",".","VariableNames"), ...
        outProto.Properties.VariableNames);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nanMask = iIsnan(x)
% Special code to find the location of NaN values that also handles tabular
% data.
if istabular(x)
    nanMask = table2array(varfun(@isnan, x));
else
    nanMask = isnan(x);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iRdivide(x, y)
% Special call for rdivide to suppress the warning when x is tabular
if istabular(x)
    outAdaptor = divisionOutputAdaptor("rdivide", x, y);
    out = elementfun(@iRdivideWithoutWarning, x, y);
    out.Adaptor = copySizeInformation(outAdaptor, out.Adaptor);
else
    out = x./y;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iRdivideWithoutWarning(x, y)
% Disable warning for tabular inputs with variable units combined with
% tabular inputs without variable units or numeric inputs.
S = warning("off", "MATLAB:table:math:AssumeUnitless");
cleaner = onCleanup(@() warning(S));
out = x./y;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanX = iDatetimeMean(x, dim, nanFlag)
% Special version of MEAN for datetimes since SUM and RDIVIDE are not
% defined for datetimes. Instead we use MEAN on each block and combine
% using ratios.

% NB: Coding pattern copied from reduceInDefaultDim, but able to deal with
% reduction that returns two outputs instead of 1. We should try and fold
% back into reduceInDefaultDim.
if isequal(dim, [])
    % Default dimension. We calculate both reduction and slice-wise
    % versions in a single reduction then choose between them.
    [meanXReduced, ~, meanXSliced] = aggregatefun( ...
            @(y) iPerBlockDatetimeMeanUnknownDim(y, nanFlag), ...
            @(m,n,p) iCombineDatetimeMeansUnknownDim(m, n, p, nanFlag), ...
            x);
     meanXReduced.Adaptor = resetSizeInformation(x.Adaptor);
     meanXSliced.Adaptor = resetSizeInformation(x.Adaptor);
     
    meanX = clientfun(@iPickWhichOne, size(x), meanXReduced, meanXSliced);
    % In this case we can't tell the output size in advance. All we know is
    % that the result has tall size 1 either way.
    meanX.Adaptor = resetSizeInformation(x.Adaptor);
    meanX.Adaptor = setSizeInDim(meanX.Adaptor, 1, 1);
else
    % Dim is known
    if isnumeric(dim) && ~ismember(1,dim)
        % Not reducing tall dimension. Just call slicewise
        meanX = slicefun(@(y) mean(y, dim, nanFlag), x); 
    else
        % Tall reduction
        [meanX, ~] = aggregatefun( ...
            @(y) iPerBlockDatetimeMean(y, dim, nanFlag), ...
            @(m,n) iCombineDatetimeMeans(m, n, nanFlag), ...
            x);
    end
    meanX.Adaptor = x.Adaptor;
    meanX.Adaptor = computeReducedSize(meanX.Adaptor, x.Adaptor, dim, false);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanX, countX] = iPerBlockDatetimeMean(x, dim, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of controbuting elements.
meanX = mean(x, dim, nanFlag);
if ismember(nanFlag, ["omitnan", "omitnat", "omitmissing"])
    countX = sum(~ismissing(x), dim);
else
    countX = elementsPerResult(x, dim);
    % Expand the count to apply to all elements
    countX = repmat(countX, size(meanX));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanX, countX] = iCombineDatetimeMeans(meanX, countX, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of controbuting elements.
import matlab.bigdata.internal.util.indexSlices;

if size(meanX,1)<=1
    return;
end

if all(countX(1,:)==countX(2:end,:), "all")
    % Special case where all blocks had the same number of elements. We
    % can just take the mean
    meanX = mean(meanX, 1, nanFlag);
    countX = sum(countX, 1);
else
    % Blocks had different number of elements. For each row in turn, work
    % out the ratio for each output element then interpolate the results.
    assert(isequal(size(meanX), size(countX)), "Expected means and counts to be same size")
    mean1 = indexSlices(meanX, 1);
    count1 = indexSlices(countX, 1);
    
    for slice = 2:size(meanX,1)
        mean2 = indexSlices(meanX, slice);
        count2 = indexSlices(countX, slice);
        ratio = count2 ./ (count2 + count1);
        
        % METHOD 1: Add scaled (duration) difference
        % newMean = mean1 + ratio.*(mean2 - mean1);
        
        % METHOD 2: Interlace the rows and use INTERP1 (which *is* supported
        % for datetime) to calculate the intermediate value between each
        % pair of elements. This is more complex than method 1, but turns
        % out to be significantly more accurate than going via duration.
        interlaced = reshape([mean1;mean2], 1, [])';
        interlacedRatio = reshape(ratio, 1, []);
        query = interlacedRatio + ((1:numel(mean1))*2 - 1);
        newMean = interp1(1:numel(interlaced), interlaced, query);
        newMean = reshape(newMean, size(mean1));
        
        % To avoid NaN propagation, fix up values that didn't need interpolating
        newMean(interlacedRatio==0) = mean1(interlacedRatio==0);
        newMean(interlacedRatio==1) = mean2(interlacedRatio==1);
        
        % Finally, replace the original slice with the new mean
        mean1 = newMean;
        count1 = count1 + count2;
    end
    
    % The accumulated result is in mean1, count1
    meanX = mean1;
    countX = count1;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanXTall, countXTall, meanXSliced] = iPerBlockDatetimeMeanUnknownDim(x, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of contributing elements.

% Compute mean in tall dimension
[meanXTall, countXTall] = iPerBlockDatetimeMean(x, 1, nanFlag);

% Also compute mean as though tall dim is 1
if size(x, 1)==0
    % If empty, the tall version will have expanded the array for us into
    % all missing
    x = meanXTall;
elseif size(x, 1)>1
    x = matlab.bigdata.internal.util.indexSlices(x, 1);
end
meanXSliced = mean(x, nanFlag);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanXTall, countXTall, meanXSliced] = iCombineDatetimeMeansUnknownDim(meanXTall, countXTall, meanXSliced, nanFlag)
% If we have more than one row, we need to interpolate based on the number
% of controbuting elements.

[meanXTall, countXTall] = iCombineDatetimeMeans(meanXTall, countXTall, nanFlag);

% For the slice-wise version, always keep just one
if size(meanXSliced, 1)>1
    meanXSliced = matlab.bigdata.internal.util.indexSlices(meanXSliced, 1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result, dim] = iPickWhichOne(sz, reducedResult, slicedResult)
% A helper to use in clientfun that can establish which of the results is
% correct, and return that along with the resolved reduction dimension.

nonSingletonDims = find(sz ~= 1);
if isequal(sz, [0 0])
    % Special case (as per g1361570) for [] empty input, MATLAB doesn't
    % apply the first-non-singleton dimension rule. We get the correct
    % result in slicedResult, so we set dim = 3 to force that.
    dim = 3;
elseif isempty(nonSingletonDims)
    % No non-singleton dimensions - scalar case
    dim = 1;
else
    dim = nonSingletonDims(1);
end

% Pick the result depending on the computed full size of the tall variable.
if dim == 1
    result = reducedResult;
else
    result = slicedResult;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sz = iGetSizeinDim(szVec, dim)
% Another special case as per g1364892. mean([]) returns NaN, which does not
% match any return that you get by specifying a dimension. Here we're working
% around yet another special case which is that sum([]) needs to return 0, and
% it does that by pretending that the reduction dimension is 3.
if isequal(szVec, [0 0])
    sz = 0;
else
    sz = szVec(dim);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper to work out how many input elements contributed to a given result
% element. Note that the output will be a tall scalar.
function n = elementsPerResult(data, dim)
if isnumeric(dim)
    % Take the product of the reduced dimension lengths. Note that this may
    % itself be a tall array as the sizes may not be known yet.
    n = prod(size(data, dim), 2);
else
    % all
    n = numel(data);
end
end