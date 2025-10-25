function [tf,meanStep] = isuniform(tX)
%ISUNIFORM Check if tall array data is uniformly spaced.
%   TF = ISUNIFORM(A)
%   [TF,STEP] = ISUNIFORM(A)
%
%   See also ISUNIFORM.

%   Copyright 2024 The MathWorks, Inc.

% Use the local function to validate that the input type is supported.
tall.validateSyntax(@isuniform, {tX}, 'DefaultType', 'double');

% Must be numeric/logical and real.
tX = tall.validateTypeWithError(tX, "isuniform", 1, ...
    ["numeric","logical"], "MATLAB:isuniform:MustBeReal");

% Input must be vector (row or column are both fine) or empty.
tX = tall.validateVectorOrEmpty(tX, "MATLAB:isuniform:MustBeVector");

% If we know this is a row, scalar, or empty we can just use the in-memory
% function on the data.
xAdap = matlab.bigdata.internal.adaptors.getAdaptor(tX);
if xAdap.isKnownEmpty() || xAdap.isKnownScalar() || xAdap.isKnownRow()
    if nargout<=1
        tf = aggregatefun(@isuniform, @all, tX);
        tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
    else
        % We don't expect to actually combine anything so just supply a
        % default combiner function.
        [tf,meanStep] = aggregatefun(@isuniform, @iDummyCombine, tX);
        tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
        meanStep.Adaptor = iGetStepAdaptor(meanStep.Adaptor, tX.Adaptor.Class);
    end
    return
end

% The actual calculation requires two steps (and unfortunately two passes)
% 1. Get the end-points and determine the tolerance
% 2. Check each partition is uniform within tolerance, including check the
% gap to its neighbours.
% The second step is almost identical to ISREGULAR so we share some
% helpers.

% For step 1, reduce the data to determine the maximum and minimum values
% and the number of entries.
[firstVal, lastVal, numVals] = aggregatefun(@iGetBlockEndsAndCount, @iCombineBlockEndsAndCount, tX);

% Calculate the step size and tolerance
[meanStep, tol] = clientfun(@iCalculateStepSize, firstVal, lastVal, numVals);

% Now check each partition is uniform with this step-size and tolerance.
[~, ~, tf, meanStep, ~] = aggregatefun( ...
    @iGetIsBlockUniform, ...
    @iCombineIsBlockUniform, ...
    tX, matlab.bigdata.internal.broadcast(meanStep), matlab.bigdata.internal.broadcast(tol));

tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
if nargout>1
    meanStep.Adaptor = iGetStepAdaptor(meanStep.Adaptor, tX.Adaptor.Class);
end
end


function [firstVal, lastVal, numVals] = iGetBlockEndsAndCount(in)
% Determine the start, end and number of values in this partition
if isempty(in)
    firstVal = in([]);
    lastVal = in([]);
    numVals = 0;
else
    firstVal = in(1);
    lastVal = in(end);
    numVals = numel(in);
end
end

function [firstVal, lastVal, numVals] = iCombineBlockEndsAndCount(firstVal, lastVal, numVals)
% Helper to combine results from multiple calls to iGetBlockEndsAndCount.
if ~isempty(firstVal)
    firstVal = firstVal(1);
    lastVal = lastVal(end);
    numVals = sum(numVals);
end
end


function [firstVal, lastVal, tf, meanStep, tol] = iGetIsBlockUniform(in, meanStep, tol)
% Determine the start, end and whether the values in this block are uniform
if isempty(in)
    firstVal = in([]);
    lastVal = in([]);
    if isnan(meanStep)
        % If all blocks are empty the step will be NaN and we should return
        % false.
        tf = false;
    else
        % This block is empty but others aren't so return true.
        tf = true;
    end
else
    firstVal = in(1);
    lastVal = in(end);
    tf = iIsUniform(in, meanStep, tol);
end
end

function [firstVal, lastVal, tf, meanStep, tol] = iCombineIsBlockUniform(firstVal, lastVal, tf, meanStep, tol)
% Helper to combine results from multiple calls to ISUNIFORM with two
% outputs. The combination is uniform if all input parts are uniform and
% the distance between end of one block and start of next is also uniform.

% meanstep, tol are broadcast so never empty. Keep just one value.
meanStep = meanStep(1);
tol = tol(1);
tf = all(tf);
% If the values are empty there is nothing more to do.
if isempty(firstVal)
    return
end

% If multiple blocks, check the spacing.
for ii=2:numel(firstVal)
    vals = [lastVal(ii-1) ; firstVal(ii)];
    tf = tf && iIsUniform(vals, meanStep(1), tol(1));
end

% If multiple blocks, update the end-points for the next reduction.
if numel(firstVal)>1
    firstVal = firstVal(1);
    lastVal = lastVal(end);
    meanStep = meanStep(1);
    tol = tol(1);
end

% If the result is not uniform then force the step to NaN
if ~isempty(firstVal) && ~tf
    meanStep = nan("like",meanStep);
end
end

function [tf, step] = iDummyCombine(tf, step)
% Combining results from empty, scalar, or row. Only one value will be
% valid so just keep that.
if numel(tf)>1
    tf = all(tf);
end
if numel(step)>1
    step = step(1);
end
end

function tf = iIsUniform(vals, meanStep, tol)
% Helper to check a block of values obeys the expected uniform spacing.

% If the values are integer and the step is not integer valued then
% definitely not uniform.
if isinteger(vals) && meanStep~=floor(meanStep)
    tf = false;
    return;
end

if numel(vals)>1
    % Uniform if difference between elements is within tolerance of the
    % expected step. We need to take care for unsigned integers in
    % descending order as they will return all zero as the diff!
    if meanStep<0 && isinteger(vals) && strncmp(class(vals), 'u', 1)
        % Calculate in reverse and compare to negative step.
        d = double(diff(flip(vals)));
        tf = all(abs(d+meanStep) <= tol);
    elseif isinteger(vals)
        % If step is >flintmax then error, otherwise do in double.
        if meanStep > flintmax
            error(message('MATLAB:isuniform:StepTooLarge'));
        end
        d = diff(double(vals));
        tf = all(abs(d-meanStep) <= tol);
    else
        % Floating point
        d = diff(vals);
        tf = all(abs(d-meanStep) <= tol);
    end
else
    % Scalar or empty is always uniform.
    tf = true;
end
end

function [meanStep, tol] = iCalculateStepSize(firstVal, lastVal, numVals)
% Calculate the expected step size between elements and the tolerance for
% comparison.

firstValF = iMustBeFullRealFloat(firstVal);
lastValF = iMustBeFullRealFloat(lastVal);

% Check for empty
if isempty(firstVal) || isempty(lastVal)
    meanStep = NaN(like=firstVal);
    tol = zeros(like=firstVal);
    return
end

numSteps = numVals-1;
meanStep = (lastValF - firstValF) ./ numSteps;
% Check if we overflowed
if ~isfinite(meanStep) && isfinite(firstValF) && isfinite(lastValF)
    meanStep = lastValF./numSteps - firstValF./numSteps; % Divide first to avoid overflow
end
% Set tolerance as per in-memory code
maxAbsEps = eps(max(abs(firstValF), abs(lastValF)));
absMeanStep = abs(meanStep);
tol = 4*maxAbsEps;
if absMeanStep < tol
    % Special cases for very small step sizes
    tol = max(absMeanStep, maxAbsEps);
end

end


function val = iMustBeFullRealFloat(val)
% Helper to ensure an input is full, real, and floating-point
if ~isfloat(val)
    val = double(val);
end
val = real(val);
end

function stepAdap = iGetStepAdaptor(stepAdap, inClz)
% Help to set the adaptor for the step output - always scalar and
% double unless the input is single.
if isempty(inClz)
    % Unkown so leave adaptor as unknown scalar
    stepAdap = setKnownSize(stepAdap, [1 1]);
elseif inClz == "single"
    stepAdap = setKnownSize(matlab.bigdata.internal.adaptors.getAdaptorForType("single"), [1 1]);
else
    % All others go to double
    stepAdap = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
end
end