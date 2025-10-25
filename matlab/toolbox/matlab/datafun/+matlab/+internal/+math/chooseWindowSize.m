function winsz = chooseWindowSize(A, dim, t, tau, dvars)
%chooseWindowSize Determine a heuristic tuning size based on a tuning factor.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

% Copyright 2018-2023 The Mathworks, Inc.


    % TAU indicates roughly how much energy we should preserve.
    if ~isempty(t)
        [t,tIsUniform,scaleFactor,tgrid] = matlab.internal.math.scaleSamplePoints(t);
    else
        tIsUniform = true;
    end

    if ~isempty(t) && tIsUniform
        % Tune on uniform nodes, scale the window size
        winsz = matlab.internal.math.chooseWindowSize(A, dim, [], tau, dvars);
        winsz = winsz * scaleFactor;
        winsz = clipWindowValue(winsz, class(t));
        return;
    end

    if (dim <= ndims(A)) && (size(A,dim) > 1)
        % Convert the whole table to double for FFT
        if isa(A, 'tabular')
            A = tabular2double(A,dvars);
        elseif isobject(A)
            if isa(A, 'single') || isequal(underlyingType(A), 'single')
                A = single(A);
            else
                A = double(A);
            end
        end
        % Non-trivial cases.
        if ~isempty(t)
            % Limiting cases.
            if tau == 0
                winsz = (t(end) - t(1));
                winsz = clipWindowValue(winsz, class(t));
                return;
            elseif tau == 1
                winsz = min(diff(t))/2;
                winsz = clipWindowValue(winsz, class(t));
                return;
            end
            
            % Interpolate onto a uniform grid
            Ai = A;
            if dim ~= 1
                Ai = permute(Ai, [dim, 1:(dim-1), (dim+1):ndims(A)]);
            end
            
            % Have to convert integer/logical data to double.
            if isinteger(Ai) || islogical(Ai)
                if (max(Ai(:)) > flintmax)
                    Ai = rescaleIntegerData(Ai);
                else
                    Ai = double(Ai);
                end
            end
            Ai = fillmissing(Ai, 'pchip', 'SamplePoints', t, ...
                'EndValues', 'extrap');
            Ai = interp1(t, Ai, tgrid, 'pchip');
            
            % Use uniform tuning and scale
            winsz = matlab.internal.math.chooseWindowSize(Ai, 1, [], tau);
            winsz = winsz * scaleFactor;
            winsz = clipWindowValue(winsz, class(t));
            return;
        else
            if tau == 0
                winsz = size(A, dim);
                return;
            elseif tau == 1
                winsz = 1;
                return;
            end

            % Get an estimate of the average cutoff frequency below which
            % most of the input's energy is contained
            if ~isfloat(A)
                Ac = double(A);
                if dim ~= 1
                    Ac = permute(Ac, [dim, 1:(dim-1), (dim+1):ndims(A)]);
                end
            else
                Ac = A;
                if dim ~= 1
                    Ac = permute(A, [dim, 1:(dim-1), (dim+1):ndims(A)]);
                end
                if anynan(Ac)
                    Ac = fillmissing(Ac, 'pchip');
                end
            end

            % Re-center the values
            Ac = Ac - mean(Ac);
            N = size(Ac, 1);
            Ac = abs(fft(Ac, 2*N)).^2 / (2*N);
            if ~isreal(A)
                % Average the negative and positive frequencies for complex
                Ac(2:end,:) = 0.5*(Ac(2:end, :) + flipud(Ac(2:end,:)));
            end
            Ac = Ac(1:N,:);

            % Compute normalized cumulative sum, average it over columns
            Ac = Ac ./ sum(Ac);
            Ac = cumsum(Ac, 'omitnan');
            Ac = mean(Ac(:, :), 2);

            % Determine cutoff bandwidth
            rho = find(Ac > tau, 1, 'first');
            % Columns are constant -- nothing to do
            if isempty(rho)
                winsz = 1;
            else
                % Convert to moving average filter width
                winsz = ceil(sqrt((0.44294*2*N/max(rho-1,1))^2+1));
            end
            winsz = clipWindowValue(winsz);
        end
    else
        % Trivial cases.
        if ~isempty(t)
            if isdatetime(t) || isduration(t)
                winsz = milliseconds(1);
            else
                winsz = cast(1, 'like', t);
            end
        else
            winsz = 1;
        end
    end
    
end

%--------------------------------------------------------------------------
function td = rescaleIntegerData(t)
% Rescale int64/uint64 sample points

    if isa(t, 'int64')
        % Convert the int64 to uint64
        % The values will change but the subtracting min(t) afterwards will
        % compensate for that
        t = matlab.internal.math.convertToUnsignedWithSameSpacing(t);
    end
    td = t - min(t);
    if max(td) > flintmax
        % Approximate sample points if we can't get things aligned
        % exactly
        td = (double(td) / double(max(td)));
    else
        td = double(td);
    end

end

%--------------------------------------------------------------------------
function winsz = clipWindowValue(winsz, cls)
    if winsz == 0
        if strcmp(cls, 'duration')
            winsz = milliseconds(realmin);
        else
            winsz = realmin(cls);
        end
        return;
    end
    if isfinite(winsz)
        return;
    end
    if strcmp(cls, 'duration')
        winsz = milliseconds(realmax);
    else
        winsz = realmax(cls);
    end
end

%--------------------------------------------------------------------------
function A = tabular2double(T,dataVars)
    warnState = warning('off','MATLAB:table:ModifiedVarnamesLengthMax');
    warnCleanup = onCleanup(@() warning(warnState));
    T = varfun(@double, T, 'InputVariables', dataVars);
    A = full(T{:, 1:width(T)});
end