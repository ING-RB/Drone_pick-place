function w = unitPhaseFactor(a, b)
% UNITPHASEFACTOR Computes the value of a complex exponential on the unit
% circle whose angle is composed of the product of two scalars.  The
% computed phase factor is of the form exp(-1j*2*pi*a*b).
%
%   UNITPHASEFACTOR(A,B) computes the unit phase factors for scalar or
%   vector a and scalar b.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2019 The MathWorks, Inc.

a = a(:);
assert(isscalar(b), 'Second input should be scalar.');
w = cospi(a*b*2) - 1j*sinpi(a*b*2);
needsReduction = ~isfinite(w);
if any(needsReduction)
    a = double(a);
    b = double(b);
    % If a and b are both above flintmax, they are necessarily
    % integers, and so the phase factor is 1.
    integerFactors = (abs(a) > flintmax) & (abs(b) > flintmax);
    w(integerFactors) = 1;
    needsReduction(integerFactors) = false;
    if ~any(needsReduction)
        return;
    end
    % Re-balance to avoid overflow with the multiplication by 2.
    a = a(needsReduction);
    b = b*ones(numel(a), 1);
    areb = abs(a) > (realmax/2);
    a(areb) = a(areb) / 2;
    b(areb) = b(areb) * 2;
    if b(1) > (realmax/2)
        a = a * 2;
        b = b / 2;
    end
    % Both a and b can be written in the form v = vi + vf, where vi is
    % an integer and vf is a fraction.  This makes the angle 2*pi*a*b
    % equal to 2*pi*(ai+af)*(bi+bf) = 2*pi*ai*af + 2*pi*ai*bf +
    % 2*pi*af*bi + 2*pi*af*bf.
    % exp(-1j*2*pi*ai*bi) = 1 always, so we can ignore that factor.
    % |ai*bf| < realmax and |af*bi| < realmax, so none of the three
    % remaining angles can overflow.  Therefore, we can either sum them
    % together if the sum still doesn't overflow, or we can compute the
    % phase as a product of three complex unit exponentials.
    arem = rem(a,1);
    brem = rem(b,1);
    ang = [arem.*(b-brem), (a-arem).*brem, arem.*brem];
    % Compute the reduced angles.
    wreduced = zeros(numel(a), 1, 'like', a);
    % If the sum of the angles is finite, directly use the formula.
    angsum = 2*sum(ang, 2);
    finiteSums = isfinite(angsum);
    wreduced(finiteSums) = cospi(angsum(finiteSums)) - ...
        1j*sinpi(angsum(finiteSums));
    wreduced(~finiteSums) = prod(cospi(2*ang(~finiteSums)) - ...
        1j*sinpi(2*ang(~finiteSums)), 2);
    w(needsReduction) = wreduced;
end

