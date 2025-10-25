classdef WrappedUniformDistribution < matlabshared.tracking.internal.ProbabilityDistribution
    %WrappedUniformDistribution Wrapped multivariate uniform distribution
    %   A wrapped uniform distribution results from wrapping the linear
    %   uniform distribution around the unit circle. 
    %
    %   OBJ = matlabshared.tracking.internal.WrappedUniformDistribution(NUMVARS) will create a
    %   NUMVARS-variate wrapped uniform distribution.    
    %
    %   Reference:
    %   [1] S.R. Jammalamadaka and A. Sengupta, Topics in Circular Statistics, 
    %       vol. 5: World Scientific, 2001.
    %       See section 2.2.1
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %RandomVariableLimits - Lower and upper limits for each of the random variables
        %    Each row of this NumRandomVariables-by-2 array corresponds 
        %    to the lower and upper limits of a single random variable. If
        %    the underlying distribution is k-variate, the array has k
        %    rows.
        %
        %    Since the wrapped distribution is defined on the unit circle,
        %    the limits will be interpreted in counter-clockwise order. For
        %    example, the limit [pi-0.1 -pi+0.1] will be interpreted as the
        %    0.2 radian segment around pi.
        %
        %    All inputs to RandomVariableLimits will be wrapped to the
        %    closed [-pi,pi] interval.
        %
        %    Default: [-pi * ones(NumRandomVariables, 1) pi * ones(NumRandomVariables, 1)]
        RandomVariableLimits
    end 
    
    properties (Access = private)
        %LinearUniformDistribution - Linear uniform distribution with same dimensions as wrapped distribution
        LinearUniformDistribution
        
        %InternalRandomVariableLimits - Internal storage for dependent RandomVariableLimits data
        InternalRandomVariableLimits
    end
    
    methods
        function obj = WrappedUniformDistribution(numVars)
            %WrappedUniformDistribution Construct a numVars-variate wrapped uniform distribution
            obj@matlabshared.tracking.internal.ProbabilityDistribution(numVars);
            
            obj.LinearUniformDistribution = matlabshared.tracking.internal.UniformDistribution(numVars);
            
            obj.reset(numVars);
        end
        
        function samples = sample(obj, numSamples, orientation)
            %SAMPLE Draw random samples from the multivariate uniform distribution
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
            %   For a description of the algorithm for wrapping of linear,
            %   stable distributions, see reference [1], page 54.            
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                validatestring(orientation,{'row','column'},'sample','orientation');
            end
            
            % Get the unwrapped samples
            unwrappedSamples = obj.LinearUniformDistribution.sample(numSamples,orientation);
            
            % Wrap samples to unit circle
            samples = matlabshared.tracking.internal.wrapToPi(unwrappedSamples);
        end    
        
        function reset(obj, numVars)
            %reset Reset the distribution with a new number of random variables
            
            % Reset number of random variables. This will also take care of
            % input validation.
            obj.NumRandomVariables = numVars;
            
            % Initialize underlying linear uniform distribution first,
            % since the RandomVariableLimits setter depends on it.
            obj.LinearUniformDistribution.reset(numVars);
            obj.RandomVariableLimits = [-pi * ones(numVars, 1) ...
                pi * ones(numVars, 1)];            
        end
        
        
        function cObj = copy(obj)
            %COPY Create a copy of the distribution object
            %   COBJ = COPY(OBJ) creates a deep copy of the
            %   WrappedUniformDistribution object OBJ and returns it in COBJ. 
            %   OBJ has to be a scalar handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            
            coder.internal.errorIf(~isscalar(obj), 'shared_tracking:particle:PolicyCopyNotScalar', ...
                'WrappedUniformDistribution');
            
            % Call copy in the base class
            cObj = copy@matlabshared.tracking.internal.ProbabilityDistribution(obj);
            
            % Assign data that has not be copied by the base class
            cObj.InternalRandomVariableLimits = obj.InternalRandomVariableLimits;
            cObj.LinearUniformDistribution = obj.LinearUniformDistribution.copy;
        end        
    end
    
    methods
        function varLimits = get.RandomVariableLimits(obj)
            varLimits = obj.InternalRandomVariableLimits;
        end
            
        function set.RandomVariableLimits(obj, varLimits)
            %set.RandomVariableLimits Setter for RandomVariableLimits property
            
            validateattributes(varLimits, {'numeric'}, {'ncols', 2, 'nrows', obj.NumRandomVariables, ...
                'nonnan', 'finite', 'real'}, 'WrappedUniformDistribution', 'RandomVariableLimits');
            
            wrappedLimits = matlabshared.tracking.internal.wrapToPi(varLimits);
            obj.InternalRandomVariableLimits = double(wrappedLimits);
            
            % Scale limits so that minimum value is smaller than maximum
            % value, so that linear uniform distribution does not complain.
            linearLimits = double(wrappedLimits);
            switchOrder = linearLimits(:,1) > linearLimits(:,2);
            
            % Add a small epsilon in the case that we are converting from
            % single to double, because after conversion, the difference
            % might be bigger than 2*pi
            if isa(varLimits, 'single')
                epsilon = eps('single');
            else
                epsilon = 0;
            end
            linearLimits(switchOrder,2) = linearLimits(switchOrder,2)+2*pi+epsilon;
            obj.LinearUniformDistribution.RandomVariableLimits = linearLimits;
        end
    end
    
    methods (Access = ?matlab.unittest.TestCase)
        function linearLimits = getLinearLimits(testCase)
            %getLinearLimits For testing, return linear limits used for sampling
            
            linearLimits = testCase.LinearUniformDistribution.RandomVariableLimits;
        end
    end
end

