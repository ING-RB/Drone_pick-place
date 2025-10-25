function M = validateCovariance(M,enforceStrictPosDef,Np,dataType,fieldName)
% validateCovariance Validate the P0, Q and R widgets of EKF/UKF/PF blocks
%
%   M = localValidateCovarianceMatrix(M,enforceStrictPosDef,Np,dataType,fieldName)
%
%   M must be in one of the following three formats:
%     scalar - M must be non-negative or positive, per enforceStrictPosDef. 
%              An [Np Np] diagonal matrix M is generated from the scalar.
%     vector - All elements in M must be positive or nonnegative per
%              enforceStrictPosDef. An [Np Np] diagonal matrix is 
%              generated with the elements of M on the diagonals.
%     matrix - M must be of size [Np Np] and symmetric-positive-(semi)definite.
%
%   Inputs:
%     M                   - Covariance matrix/vector/scalar
%     enforceStrictPosDef - boolean flag
%     Np                  - Number of expected elements. -1 if unknown
%     fieldName           - Display name of the widget in block dialog
%     dataType            - Final desired data type

%   Copyright 2017 The MathWorks, Inc.

% Common checks, independent of size
if isempty(M)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isfloat(M)
    error(message('shared_tracking:blocks:errorExpectedFloat', fieldName, class(M)));
end
if ~isreal(M)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~ismatrix(M)
    error(message('shared_tracking:blocks:errorMustBeScalarVectorMatrix',fieldName));
end
if ~all(all(isfinite(M)))
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if issparse(M)
    error(message('shared_tracking:blocks:errorExpectedNonsparse', fieldName));
end

% Begin size and positive-(semi)definiteness checks
if Np==-1
    % Expected dimensions are unknown. Cannot scalar expand. Set Np so that
    % following size checks just pass
    if isscalar(M) || isvector(M)
        Np = numel(M);
    else % elseif ismatrix(M), ensured by the ismatrix check above
        Np = size(M,1);
    end
end

if isscalar(M)
    if enforceStrictPosDef && M<=0
        error(message('shared_tracking:blocks:errorExpectedPositive', fieldName));
    elseif ~enforceStrictPosDef && M<0
        error(message('shared_tracking:blocks:errorExpectedNonnegative', fieldName));
    end
    M = M*eye(Np);
elseif isvector(M)
    if numel(M)~=Np
        error(message('shared_tracking:blocks:errorIncorrectNumel', fieldName, Np, numel(M)));
    end
    if enforceStrictPosDef && any(M<=0)
        error(message('shared_tracking:blocks:errorExpectedPositive', fieldName));
    elseif ~enforceStrictPosDef && any(M<0)
        error(message('shared_tracking:blocks:errorExpectedNonnegative', fieldName));
    end
    M = diag(M);
else %ismatrix(M), ensured by the ismatrix check above
    if ~isequal(size(M),[Np Np])
        error(message('shared_tracking:blocks:errorIncorrectSize', ...
            fieldName, sprintf('%d %d',Np,Np), mat2str(size(M)) ));
    end
    matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite(fieldName,M);
end

% Ensure M has the right data type
M = cast(M,dataType); 
end