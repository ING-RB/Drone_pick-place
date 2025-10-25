function val = isovalue(data)
%ISOVALUE  Isovalue calculator.
%   VAL = ISOVALUE(V) calculates an isovalue from data V using hist
%   function.  Utility function used by ISOSURFACE and ISOCAPS.

%   Copyright 1984-2017 The MathWorks, Inc.

% Only use about 10000 samples when calculating the isovalue.
r = 1;
num = numel(data);
if num > 20000
    r = floor(num/10000);
end

% Bin the values into 100 bins.
[n, ctrs] = hist(data(1:r:end),100);

% Remove the first two bins if they contain the largest value, and the
% largest value is more than 10 times the average bin size.
pos = find(n==max(n),1);
q = max(n(1:2));
if pos<=2 && q/mean(n) > 10
    n = n(3:end);
    ctrs = ctrs(3:end);
end

% Remove bins with fewer than 1/50th the largest bin.
smallBins = n<max(n)/50;
if sum(smallBins) < 90
    ctrs(smallBins) = [];
end

if sum(n == 0) == 99
    % If there is only one bin with any values, then the subsampled matrix
    % was all the same value, so just use that value as the isovalue.
    val = data(1);
else
    % Get the value of middle of the remaining bins.
    val = ctrs(floor(numel(ctrs)/2));
end
