classdef StatFunctionUtils
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class provides utility functions for
    % min/max/mean/median/mode/range/var/std. (Functions have been moved
    % from workspacefunc.m)

    % Copyright 2020-2024 The MathWorks, Inc.
    
    methods(Static)
        function m = computeMin(x)
            if isfloat(x)
                if anynan(x)
                    m = cast(NaN, class(x));
                else
                    m = min(x);
                end
            else
                m = min(x);
            end
        end
        
        function m = computeMax(x)            
            %Handling the input objects of subclass of Numeric classes with properties
            % Modified  the implementation same as Min
            if isfloat(x)
                if anynan(x)
                    m = cast(NaN, class(x));
                else
                    m = max(x);
                end
            else
                m = max(x);
            end
        end
        
        function m = computeRange(x)
            import internal.matlab.datatoolsservices.StatFunctionUtils;
            lm = StatFunctionUtils.computeMax(x);
            if isnan(lm)
                m = cast(NaN, class(x));
            else
                m = lm-StatFunctionUtils.computeMin(x);
            end
        end
        
        % TODO: Modify this to compute for Time column in timetables.
        function m = computeTsRange(x)
            m = max(x)-min(x);
        end
        
        
        function m = computeNaNRange(x)
            m = max(x)-min(x);
        end
        
        function m = computeNaNMean(x)
            % Find NaNs and set them to zero
            nans = isnan(x);
            x(nans) = 0;
            
            % Count up non-NaNs.
            n = sum(~nans);
            n(n==0) = NaN; % prevent divideByZero warnings
            % Sum up non-NaNs, and divide by the number of non-NaNs.
            m = sum(x) ./ n;
        end
        
        function y = computeNaNMedian(x)
            
            % If X is empty, return all NaNs.
            if isempty(x)
                y = nan(1, 1, class(x));
            else
                x = sort(x,1);
                nonnans = ~isnan(x);
                
                % If there are no NaNs, do all cols at once.
                if all(nonnans(:))
                    n = length(x);
                    if rem(n,2) % n is odd
                        y = x((n+1)/2,:);
                    else        % n is even
                        y = (x(n/2,:) + x(n/2+1,:))/2;
                    end
                    
                    % If there are NaNs, work on each column separately.
                else
                    % Get percentiles of the non-NaN values in each column.
                    y = nan(1, 1, class(x));
                    nj = find(nonnans(:,1),1,'last');
                    if nj > 0
                        if rem(nj,2) % nj is odd
                            y(:,1) = x((nj+1)/2,1);
                        else         % nj is even
                            y(:,1) = (x(nj/2,1) + x(nj/2+1,1))/2;
                        end
                    end
                end
            end
        end
        
        function y = computeNaNStd(varargin)
            import internal.matlab.datatoolsservices.StatFunctionUtils;
            y = sqrt(StatFunctionUtils.computeNaNVar(varargin{:}));
        end
        
        function y = computeNaNVar(x)
            import internal.matlab.datatoolsservices.StatFunctionUtils;
            % The output size for [] is a special case when DIM is not given.
            if isequal(x,[]), y = NaN(class(x)); return; end
            
            % Need to tile the mean of X to center it.
            tile = ones(size(size(x)));
            tile(1) = length(x);
            
            % Count up non-NaNs.
            n = sum(~isnan(x),1);
            
            % The unbiased estimator: divide by (n-1).  Can't do this when
            % n == 0 or 1, so n==1 => we'll return zeros
            denom = max(n-1, 1);
            denom(n==0) = NaN; % Make all NaNs return NaN, without a divideByZero warning
            
            x0 = x - repmat(StatFunctionUtils.computeNaNMean(x), tile);
            y = StatFunctionUtils.computeNaNSum(abs(x0).^2) ./ denom; % abs guarantees a real result
        end
        
        function y = computeNaNSum(x)
            x(isnan(x)) = 0;
            y = sum(x);
        end
        
        function y = computeMode(x)            
            y = mode(x);            
        end
    end
end

