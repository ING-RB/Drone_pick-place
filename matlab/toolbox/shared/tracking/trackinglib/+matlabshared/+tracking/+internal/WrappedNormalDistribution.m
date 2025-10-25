classdef WrappedNormalDistribution < matlabshared.tracking.internal.NormalDistribution
    %WrappedNormalDistribution Wrapped multivariate normal distribution
    %   A wrapped normal distribution results from wrapping the linear normal
    %   distribution around the unit circle.
    %
    %   OBJ = matlabshared.tracking.internal.WrappedNormalDistribution(NUMVARS) will create a
    %   NUMVARS-variate wrapped normal distribution.
    %
    %   Example:
    %      % Construct tri-variate wrapped normal distribution
    %      n = matlabshared.tracking.internal.WrappedNormalDistribution(3);
    %
    %      % Set mean and covariance
    %      n.Mean = [pi 0.1 0];
    %      n.Covariance = diag([pi/4 pi/4 pi/4]);
    %
    %      % Draw 20 random samples
    %      numSamples = 20;
    %      samples = n.sample(numSamples)
    %
    %      % Get maximum likelihood estimate of fitting distribution to samples
    %      [mu, covar] = matlabshared.tracking.internal.WrappedNormalDistribution.fitToSamples(samples, 1/numSamples*ones(numSamples,1))
    %
    %   Reference:
    %   [1] S.R. Jammalamadaka and A. Sengupta, Topics in Circular Statistics,
    %       vol. 5: World Scientific, 2001.
    
    %   Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen
    
    methods
        function obj = WrappedNormalDistribution(numVars)
            %WrappedNormalDistribution Construct a numVars-variate wrapped normal distribution
            obj@matlabshared.tracking.internal.NormalDistribution(numVars);
        end
        
        function samples = sample(obj, numSamples, orientation)
            %SAMPLE Draw random samples from the multivariate normal distribution
            %   SAMPLES = SAMPLE(OBJ, NUMSAMPLES, ORIENTATION) draws
            %   NUMSAMPLES random samples from the underlying distribution.
            %   NUMSAMPLES has to be a scalar value.
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
            %   For a description of the algorithm for wrapping of linear,
            %   stable distributions, see reference [1], page 54.
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                validatestring(orientation,{'row','column'},'sample','orientation');
            end
            
            % Get the unwrapped samples
            unwrappedSamples = sample@matlabshared.tracking.internal.NormalDistribution(obj, numSamples, orientation);
            
            % Wrap samples to unit circle
            samples = matlabshared.tracking.internal.wrapToPi(unwrappedSamples);
        end
    end
    
    methods (Static)
        function [sampleMean, sampleCovariance] = fitToSamples(samples, weights, orientation)
            %fitToSamples Fit a wrapped normal distribution to a set of weighted samples
            %
            %   [SAMPLEMEAN, SAMPLECOVARIANCE] = matlabshared.tracking.internal.WrappedNormalDistribution.fitToSamples(SAMPLES,
            %   WEIGHTS) fits the multivariate wrapped normal distribution with the
            %   parameters SAMPLEMEAN and SAMPLECOVARIANCE to the weighted
            %   input SAMPLES.
            %   SAMPLES is an array of N samples of a K-variate wrapped normal
            %   distribution (N-by-K array). WEIGHTS is an N-by-1 vector of
            %   weights for each sample. All values in WEIGHTS must be
            %   normalized (sum up to 1).
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                % Internal function. Skip validation for speed
                %validatestring(orientation,{'row','column'},'fitToSamples','orientation');
            end
            
            isStateOrientationRow = strcmp(orientation,'row');
            assert(isvector(weights));
            if isStateOrientationRow
                assert(size(samples,1) == size(weights,1));
                particlesDimension = 1;
                % Find weighted sum of all sine and cosine values
                % Specify summation as column-wise so that single samples are
                % treated correctly.
                %
                % Code below is equivalent of
                % sinsum = sum(bsxfun(@times, weights, sin(samples)), 1);
                % cossum = sum(bsxfun(@times, weights, cos(samples)), 1);
                sinsum = weights.' * sin(samples);
                cossum = weights.' * cos(samples);
            else
                assert(size(samples,2) == size(weights,2));
                particlesDimension = 2;
                sinsum = sin(samples) * weights.';
                cossum = cos(samples) * weights.';
            end
            
            % The mean resultant vector R is described by the column of [cossum; sinsum]
            % Calculate the length of the mean resultant vector. This
            % length is a measure of how concentrated the data is around
            % the mean.
            resultantLength = sqrt(sinsum.^2 + cossum.^2);
            
            % The circular mean is the direction of the resultant vector.
            % See formula (1.3.5) in reference [1].
            sampleMean = atan2(real(sinsum), real(cossum));
            
            % The circular variance is given by 1 - resultantLength, but it
            % has no direct relation to parameters of the wrapped normal distribution.
            
            % Instead, the length of the mean resultant vector is
            % equivalent to exp(-sigma^2/2) where sigma^2 is the variance
            % of the wrapped normal distribution.
            % See section (2.2.6) of reference [1].
            
            % We are only calculating variances here, since there is no crisp
            % definition of a circular covariance matrix.
            sampleCovariance = diag(-2 * log(resultantLength));
            
            % Handle degeneracies (if any)
            % If the resultant vector is of length 0, the data is spread
            % evenly over the circle, with no concentration towards any
            % direction (see definition 1.1 in [1])
            degenerate = resultantLength < sqrt( eps(class(samples)) );
            if any(degenerate)
                % Use standard weighted variance in this case
                sampleVariance = var(samples, weights, particlesDimension);                
                
                for kkD = 1:numel(degenerate)
                    if degenerate(kkD)
                        sampleMean(kkD) = cast(0,'like',samples); % Use mean value of 0 (result of atan2(0,0))
                        sampleCovariance(kkD,kkD) = sampleVariance(kkD);
                    end
                end
            end
        end
    end
end

