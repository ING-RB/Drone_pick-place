function dCoeffs = polyCoeffsDerivative(coeffs)
%polyCoeffsDerivative Compute the coefficients of the first derivative of a piecewise polynomial given its coefficients
%   This function computes the first derivative of a polynomial
%   specified by input coefs, provided in the format used for pp-form,
%   where the columns are associated with the polynomial order
%   (decreasing from left to right), and the rows are associated with
%   different segments.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

% Initialize new coefficient matrix
dCoeffs = zeros(size(coeffs));

% Compute derivative coefficients by column
for i = 2:size(coeffs,2)
    lastPow = size(coeffs,2)-i+1;
    dCoeffs(:,i) = lastPow*coeffs(:,i-1);
end
end