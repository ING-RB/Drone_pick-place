classdef NormalDistribution < matlabshared.tracking.internal.ProbabilityDistribution
    %NormalDistribution Multivariate normal distribution
    %   A k-variate vector of random variables is normally distributed if every
    %   linear combination of its k components has a univariate normal
    %   distribution.
    %
    %   OBJ = matlabshared.tracking.internal.NormalDistribution(NUMVARS) will create a
    %   NUMVARS-variate normal distribution.    
    %
    %   Another name for this distribution is the multivariate Gaussian distribution.
    %
    %   Example:
    %      % Construct bi-variate normal distribution
    %      n = matlabshared.tracking.internal.NormalDistribution(2);
    %
    %      % Set mean and covariance
    %      n.Mean = [5 0.03];
    %      n.Covariance = diag([0.2 0.2]);
    %
    %      % Draw 20 random samples
    %      numSamples = 20;
    %      samples = n.sample(numSamples)
    %
    %      % Get maximum likelihood estimate of fitting distribution to samples
    %      [mu, covar] = matlabshared.tracking.internal.NormalDistribution.fitToSamples(samples, 1/numSamples*ones(numSamples,1))
    %
    %   Reference:
    %   [1] J.E. Gentle, Computational Statistics. New York: Springer, 2009
    
    %   Copyright 2015-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %Mean - Mean vector of the normal distribution
        %   This will be a vector of size 1-by-NumRandomVariables.
        %
        %   Default: zeros(1,NumRandomVariables)
        Mean
        
        %Covariance - The covariance matrix of the normal distribution
        %   This will be a matrix of size NumRandomVariables-by-NumRandomVariables.
        %   The covariance matrix has to be symmetric and positive
        %   semi-definite.
        %
        %   Default: eye(NumRandomVariables)
        Covariance
    end
    
    properties (Access = {?matlabshared.tracking.internal.NormalDistribution, ?matlab.unittest.TestCase})
        %InternalMean - Internal storage for mean vector
        InternalMean
        
        %InternalCovariance - Internal storage for covariance matrix
        InternalCovariance
        
        %InternalStandardDeviation - Internal storage for standard deviation matrix
        InternalStandardDeviation
    end
    
    methods
        function obj = NormalDistribution(numVars)
            %MultivariateNormalDistribution Construct a numVars-variate normal distribution
            obj@matlabshared.tracking.internal.ProbabilityDistribution(numVars);
            
            obj.reset(numVars);
        end
        
        function samples = sample(obj, numSamples, orientation)
            %SAMPLE Draw random samples from the multivariate normal distribution
            %   SAMPLES = SAMPLE(OBJ, NUMSAMPLES, ORIENTATION) draws
            %   NUMSAMPLES random samples from the underlying distribution.
            %   NUMSAMPLES has to be a scalar value. ORIENTATION is either
            %   'row' or 'column'.
            %
            %   If ORIENTATION is 'row', the SAMPLES output has NUMSAMPLES
            %   rows and >= 1 columns. The number of columns is equal to
            %   the number of state variables of the distribution. For
            %   example, for a bivariate probability distribution, SAMPLES
            %   has 2 output columns.
            %
            %   If ORIENTATION is 'column', the row and column
            %   dimensions of SAMPLES are swapped.
            %
            %   For a detailed description of the algorithm, see reference
            %   [1], pp. 315-316.
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                validatestring(orientation,{'row','column'},'sample','orientation');
            end
            
            assert(numSamples >= 1);
            
            % Draw samples from univariate normal distribution with zero
            % mean. Use Cholesky factor to specify the multi-variate standard
            % deviation.
            randData = randn(numSamples, size(obj.InternalStandardDeviation, 1));
            
            if strcmp(orientation,'row')
                % Scale the data to the sample space using mean and stdDev
                samples = matlabshared.tracking.internal.sampleGaussianImpl(randData, obj.Mean, obj.InternalStandardDeviation);
            else
                % Swap the order of the data, then scale to the sample space
                samples = matlabshared.tracking.internal.sampleGaussianImpl(randData, obj.Mean, obj.InternalStandardDeviation)';
            end
        end   
        
        function reset(obj, numVars)
            %reset Reset the distribution with a new number of random variables
            
            % Reset number of random variables. This will also take care of
            % input validation.
            obj.NumRandomVariables = numVars;
            
            % Re-initialize the mean and covariance            
            obj.Mean = zeros(1,obj.NumRandomVariables);
            obj.Covariance = eye(obj.NumRandomVariables);
        end
        
        function cObj = copy(obj)
            %COPY Create a copy of the distribution object
            %   COBJ = COPY(OBJ) creates a deep copy of the
            %   NormalDistribution object OBJ and returns it in COBJ. 
            %   OBJ has to be a scalar handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            
            coder.internal.errorIf(~isscalar(obj), 'shared_tracking:particle:PolicyCopyNotScalar', ...
                'NormalDistribution');
            
            % Call copy in the base class
            cObj = copy@matlabshared.tracking.internal.ProbabilityDistribution(obj);
            
            % Assign data that has not be copied by the base class
            cObj.InternalMean = obj.InternalMean;
            cObj.InternalCovariance = obj.InternalCovariance;
            cObj.InternalStandardDeviation = obj.InternalStandardDeviation;
        end
    end
    
    methods (Static)
        function [sampleMean, sampleCovariance] = fitToSamples(samples, weights, orientation)
            %fitToSamples Fit a normal distribution to a set of weighted samples
            %
            %   [SAMPLEMEAN, SAMPLECOVARIANCE] = matlabshared.tracking.internal.NormalDistribution.fitToSamples(SAMPLES,
            %   WEIGHTS) fits the multivariate normal distribution with the
            %   parameters SAMPLEMEAN and SAMPLECOVARIANCE to the weighted
            %   input SAMPLES. 
            %   SAMPLES is an array of N samples of a K-variate normal
            %   distribution (N-by-K array). WEIGHTS is an N-by-1 vector of
            %   weights for each sample. All values in WEIGHTS must be
            %   normalized (sum up to 1).
            %
            %   For a normal distribution, the maximum likelihood
            %   estimators are the sample mean and sample covariance.
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                % Internal function. Skip validation for speed
                % validatestring(orientation,{'row','column'},'fitToSamples','orientation');
            end            
            isStateOrientationRow = strcmp(orientation,'row');
            
            assert(isvector(weights));
            if isStateOrientationRow
                assert(size(samples,1) == size(weights,1));
                % Calculate weighted mean (assuming weights are normalized)
                %
                % sampleMean = sum(bsxfun(@times, samples, weights),1);
                sampleMean = weights.' * samples;
            else
                assert(size(samples,2) == size(weights,2));
                sampleMean = samples * weights.';
            end
            
            % Calculating the covariance matrix is about 3 times
            % as expensive as calculating the mean, so skip it if output
            % is not needed.
            if nargout <= 1
                return;
            end
            
            % Calculate unbiased, weighted covariance matrix
            % (assuming weights are normalized)
            weightSqr = sum(weights.*weights);
            if abs(weightSqr - 1.0) < sqrt( eps(class(samples)) )
                % To avoid NaN values, use factor of 1.0 if the sum of
                % squared weights is close to 1.0.
                % For example, this case can occur if there is only a
                % single particle in the input, or if all particles except
                % one have a weight of 0.
                % In this case, the covariance matrix will be all zeros,
                % which is the same behavior as the cov built-in.
                factor = cast(1.0,'like',samples);
            else
                factor = cast(1.0,'like',samples);
                factor = factor / (factor - weightSqr);
            end
            meanDiff = bsxfun(@minus, samples, sampleMean);
            
            if isStateOrientationRow
                sampleCovariance = factor * (bsxfun(@times, meanDiff, weights).' * meanDiff);
            else
                sampleCovariance = factor * (bsxfun(@times, meanDiff, weights) * meanDiff.');
            end
        end
    end
    
    methods
        function meanValue = get.Mean(obj)
            %get.Mean Getter for Mean property
            
            meanValue = obj.InternalMean;
        end
        
        function set.Mean(obj, meanValue)
            %set.Mean - Setter for Mean property
            
            validateattributes(meanValue, {'numeric'}, {'size', [1, obj.NumRandomVariables]}, ...
                'NormalDistribution', 'Mean');
            
            obj.InternalMean = double(meanValue);
        end
        
        function covariance = get.Covariance(obj)
            %get.Covariance Getter for Covariance property
            
            covariance = obj.InternalCovariance;
        end
        
        function set.Covariance(obj, covariance)
            %set.Covariance Setter for Covariance property
            
            validateattributes(covariance, {'numeric'}, {'size', [obj.NumRandomVariables, obj.NumRandomVariables]}, ...
                'NormalDistribution', 'Covariance');
            
            % Verify properties of covariance matrix. It's supposed to be
            % symmetric and positive semi-definite.
            % If that's the case, the number of negative eigenvalues,
            % numNegEigenValues, will be 0.
            % numNegEigenValues will be NaN if the input is not symmetric.
            [T,numNegEigenValues] = matlabshared.tracking.internal.cholcov(double(covariance));
            assert(numNegEigenValues == 0);
            
            % Store Cholesky factor to speed up subsequent sampling
            % operations.
            obj.InternalCovariance = double(covariance);
            obj.InternalStandardDeviation = real(T);
        end
    end
    
end

