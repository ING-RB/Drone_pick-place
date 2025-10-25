function likelihood = fullStateMeasurement(pf, predictParticles, measurement)
%fullStateMeasurement Compute likelihood of a full state measurement.
%   All state variables are assumed to be non-circular.

%   Copyright 2015 The MathWorks, Inc.

%#codegen

validateattributes(measurement, {'double'}, {'vector', 'numel', pf.NumStateVariables}, ...
    'fullStateMeasurement', 'measurement');

% Assume that measurements are subject to normal-distributed noise
% Specify noise as covariance matrix
measurementNoise = 0.5 * eye(pf.NumStateVariables);
  
% The measurement contains all state variables
measurementModel = eye(pf.NumStateVariables);
  
% Expected measurements for each particle (based on predicted state)
predictMeasurement = predictParticles * measurementModel';

% Calculate error between predicted and actual measurement
measurementError = bsxfun(@minus, predictMeasurement, measurement(:)');

% Use measurement noise and take inner product
measurementErrorProd = dot(measurementError, measurementError * inv(measurementNoise)', 2);

% Convert error norms into likelihood measure. 
% Evaluate the PDF of the multivariate normal distribution. A measurement
% error of 0 results in the highest possible likelihood.
likelihood = 1/sqrt((2*pi).^pf.NumStateVariables * det(measurementNoise)) * exp(-0.5 * measurementErrorProd);

end
