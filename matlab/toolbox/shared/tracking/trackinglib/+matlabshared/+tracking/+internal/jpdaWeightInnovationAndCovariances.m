function [y,yy] = jpdaWeightInnovationAndCovariances(z,zEstimated,beta,wrapping)
    % weightInnovationCovariances weights the measurements and
    % computes the covariance-like term SUM(beta_i*y_i*y_i')
    % Inputs:
    %         z           - matrix of columns measurements
    %         zEstimated  - column vector of predicted measurement
    %         beta        - column vector of jpda coefficients
    %         wrapping    - measurement bounds to wrap the innovation
    % Outputs:
    %         y           - weighted innovation
    %         yy          - weighted covariance like term

    % No validation is done at this level. Any additional input
    % validation should be done in a function or object that uses
    % this function. 
    
    %#codegen
            
    % Copyright 2016-2021 The MathWorks, Inc.
   
    if nargin < 4
        nz = coder.internal.indexInt(numel(z));
        wrapping = matlabshared.tracking.internal.defaultWrapping(nz,class(z));
    end
    beta_col = beta(:);
    innovations = matlabshared.tracking.internal.wrapResidual(z - zEstimated(:), wrapping, 'correctjpda');
    y = innovations * beta_col;
    yy = bsxfun(@times,beta_col',innovations) * innovations';
end