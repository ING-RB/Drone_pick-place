function [newBreaks, newCoefs] = addFlatSegmentsToPPFormParts(oldbreaks, oldCoeffs, dim)
%addFlatEndSegmentToPPFormParts Augment pp-form so that all values are constant prior to initial value and after final value
%   The pp-form represents a piecewise polynomial in terms of the segments,
%   using a vector of the breaks (the bounds of the parameterized variable
%   that define each segment) and coefficients (a matrix of the
%   coefficients for each segment). If the polynomial is evaluated at a
%   point outside the breaks, it extrapolates using the coefficients
%   defined by the closest break. This helper function adds breaks to the
%   start and end and fills in polynomials that will hold the position
%   constant over these breaks. This has the consequence that the
%   polynomial is constant for all break values before the specified first
%   break and after the specified final break.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

[breaksWithFlatStart, coefsWithFlatStart] = addSegmentToStart(oldbreaks, oldCoeffs, dim);
[newBreaks, newCoefs] = addSegmentToEnd(breaksWithFlatStart, coefsWithFlatStart, dim);


end

function [newBreaks, newCoefs] = addSegmentToStart(breaks, coefs, dim)
%addSegmentToStart Add a flat segment prior to the first break

% Obtain key dimensions
[s1, s2] = size(coefs);

% Obtain the start value to hold flat. The coefficients at the start
% are evaluated for pp(t=0).
degree = size(coefs,2) - 1;
valueAtStart = coefs(1:dim,:)*[zeros(1,degree) 1]';

% Create coefficients for a new polynomial that holds the start value
% constant
newSegmentCoeffs = createConstantPolynomialCoeffs(dim, s2, valueAtStart);

% Add the new coefficients into the existing polynomial coefficient matrix
% at the start
newCoefs = zeros(s1 + dim, s2);
newCoefs(1:dim,:) = newSegmentCoeffs;
newCoefs(((dim+1):(s1+dim)), :) = coefs;

% Update the breaks to reflect that a segment has been added to the start
newBreaks = [breaks(1)-1 breaks];

end

function [newBreaks, newCoefs] = addSegmentToEnd(breaks, coefs, dim)
%addSegmentToEnd Add a flat segment after the last break

% Obtain key dimensions
[s1, s2] = size(coefs);

% Obtain the end value to hold flat. The coefficients at the end are
% evaluated at pp(t = tF) where tF is the offset from the penultimate
% break.
holdPoint = breaks(end)-breaks(end-1);
evalPointVector = ones(s2, 1);
for i = 1:s2
    evalPointVector(i) = holdPoint^(s2-i);
end
valueAtEnd = coefs((end-dim+1):end,:)*evalPointVector;

% Create coefficients for a new polynomial that holds the start value
% constant
newSegmentCoeffs = createConstantPolynomialCoeffs(dim, s2, valueAtEnd);

% Add the new coefficients into the existing polynomial coefficient matrix
% at the end
newCoefs = zeros(s1 + dim, s2);
newCoefs(1:s1,:) = coefs;
newCoefs(((s1+1):(s1+dim)), :) = newSegmentCoeffs;

% Update the breaks to reflect that a segment has been added to the end
newBreaks = [breaks breaks(end)+1];

end

function newSegmentCoeffs = createConstantPolynomialCoeffs(dim1, dim2, constValues)
%createConstantPolynomialCoeffs Create a matrix of coefficients that represent a constant polynomial with values specified by CONSTVALUES

newSegmentCoeffs = zeros(dim1, dim2);
newSegmentCoeffs(:, dim2) = constValues;
end