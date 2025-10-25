function zeroSignalDelayFcn = makeIIRFilterUpdateFunction(isSingleChannel, b, a)
%MAKEIIRFILTERUPDATEFUNCTION  Make function handle for parallel IIR filters
%
%   Evaluates the provided filter coefficients and selects the appropriate
%   solver for the delay state propagation step in the data parallel IIR
%   filter algorithm.  A linear recurrence solver is used when possible and
%   falls back to iteratively evaluating the IIR filter using a zero-signal
%   input.  This hybrid scheme allows supporting a broader class of inputs
%   than relying on only the linear recurrence solver.

%   Copyright 2020 The MathWorks, Inc.

dim = 1;
zeroSignalDelayFcn = @(nx, zi) zfx0IterativeFilter(b, a, nx, zi, dim);

% Work out if the more optimal linear-recurrence solver can be used instead
% currently limited to cases where:
%   * The input signal is a column vector
%   * The a coefficients are all real floating point numbers.
%   * |a| > |b| otherwise the linear system defined by the initial
%     conditions for the recurrence is overdetermined.
%   * The polynomial defined by the a coefficients has unique roots.
if isSingleChannel && isfloat(a) && isreal(a) && length(a) > length(b)
    r = roots(a);
    hasUniqueRoots = numel(unique(r)) == numel(a)-1;
    
    if hasUniqueRoots
        zeroSignalDelayFcn = @(nx, zi) zfx0LinearRecurrence(b, a, r, nx, zi, dim);
    end
end
end

%--------------------------------------------------------------------------
function zZeroSignal = zfx0IterativeFilter(b, a, numDataSlices, prevDelay, dim)
% Calculate the zero-signal delay using filter iteratively.
NUM_CHUNK_SLICES = 2e4;
delaySize = size(prevDelay);

while numDataSlices ~=0
    numSlices = min(numDataSlices, NUM_CHUNK_SLICES);
    zeroSignal = zeros(numSlices, delaySize(2:end));
    [~, zZeroSignal] = filter(b, a, zeroSignal, prevDelay, dim);
    
    % update for next iteration
    prevDelay = zZeroSignal;
    numDataSlices = numDataSlices - numSlices;
end

end

%--------------------------------------------------------------------------
function zZeroSignal = zfx0LinearRecurrence(b, a, r, numDataSlices, prevDelay, dim)
numStates = length(prevDelay);

if numDataSlices < numStates
    % Simpler to just use the iterative solver instead.
    zZeroSignal = zfx0IterativeFilter(b, a, numDataSlices, prevDelay, dim);
    return;
end

yi = filter(b, a, zeros(numStates,1), prevDelay, dim);
n = (numDataSlices-numStates+1):numDataSlices;

% Solve the linear recurrence from the initial conditions.
A = (r.^(0:numel(r)-1)).';
c = A \ yi;
y = sum( c .* r.^(n-1), 1).';
y = real(y);

zZeroSignal = conv(y, -a.', 'full');
zZeroSignal = zZeroSignal(end-numStates+1:end);
end
