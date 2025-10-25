function ideal = findIdealAccelValues(data, grav)
%   This function is for internal use only. It may be removed in the future. 

%FINDIDEALACCELVALUES Find closest ideal accelerometer values to data
%   FINDIDEALACCELVALUES(DATA,GRAV) takes the N-by-3 matrix DATA of noisy
%   accelerometer data and the scalar GRAV and returns an N-by-3 matrix
%   IDEAL which are the row-by-row ideal values of the an accelerometer.
%   The scalar GRAV is the ideal value of gravity.


%   Copyright 2023 The MathWorks, Inc.


%#codegen

% This function is separated out for testing purposes
    idealbasis = grav.*cast([0 0 1; 0 0 -1; 0 1 0; 0 -1 0; 1 0 0; -1 0 0], 'like', data);
    difference = data - permute(idealbasis, [3 2 1]);
    dist = vecnorm(squeeze(difference), 2, 2);
    [~, closestidx] = min(squeeze(dist), [], 2);

    % Check if all 6 ideals have data assigned to them:
    theOne = ones(1,1, 'like', data);
    z = zeros(1,6, 'like', data);
    for ii=1:numel(closestidx)
        c = closestidx(ii);
        z(c) = z(c) + theOne;
    end

    theZero = zeros(1,1, 'like', data);
    coder.internal.assert(all(z > theZero), 'shared_positioning:accelcal:UseExplicit', ...
        "accelcal(xup,xdown,yup,ydown,zup,zdown)")

    % use closestindex to expand and assign ideal
    ideal = idealbasis(closestidx,:);
end
