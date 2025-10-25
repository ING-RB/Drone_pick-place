function [tf, lowerbound, upperbound, center, b] = locateoutliers(a, method, ...
    wl, p, sp, maxoutliers, replace, lowup)
% locateoutliers Shared computation function for isoutlierInternal and
% filloutliers
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2016-2024 The MathWorks, Inc.

if islogical(method)
    % manual specification of outlier location
    tf = method;
    asiz = size(a);
    % propage sparsity of a using 'like'
    lowerbound = NaN([1 asiz(2:end)], 'like', a);
    upperbound = lowerbound;
    center = lowerbound;
else
    switch method
        case 'grubbs'
            asiz = size(a);
            ncols = prod(asiz(2:end));
            lowerbound = zeros([1 asiz(2:end)],'like',a);
            upperbound = lowerbound;
            center = lowerbound;
            aflat = a(:,:);
            
            tf = false(asiz);
            for i=1:ncols
                atemp = aflat(:,i);
                indvec = (i-1)*size(aflat,1)+1:i*size(aflat,1); % linear indices
                indvec(isnan(atemp)) = [];
                atemp(isnan(atemp)) = [];
                while true
                    n = length(atemp);                    
                    [astd,center(i)] = std(atemp);                    
                    adiff = abs(atemp - center(i));
                    [amax, loc] = max(adiff);
                    
                    t = matlab.internal.math.datafuntinv(p/(2*n),n-2);
                    threshold = ((n-1)/sqrt(n))*abs(t)/sqrt(n-2+t^2);
                    
                    if amax/astd > threshold
                        atemp(loc) = [];
                        tf(indvec(loc)) = true;
                        indvec(loc) = [];
                    else
                        break;
                    end
                end
                lowerbound(i) = center(i) - astd*threshold;
                upperbound(i) = center(i) + astd*threshold;
            end
        case 'gesd'
            if isempty(maxoutliers)
                % Simply pick 10% of data size as maximum number of outliers
                maxoutliers = ceil(size(a,1)*0.1);
            end
            asiz = size(a);
            ncols = prod(asiz(2:end));
            lowerbound = NaN([1 asiz(2:end)],'like',a);
            upperbound = lowerbound;
            center = lowerbound;
            aflat = a(:,:);
            
            for j=1:ncols
                indvec = (j-1)*size(aflat,1)+1:j*size(aflat,1); % linear indices
                atemp = aflat(:,j);
                indvec(isnan(atemp)) = [];
                atemp(isnan(atemp)) = [];
                n = numel(atemp);
                if n > 0
                    amean = zeros(maxoutliers,1);
                    astd = zeros(maxoutliers,1);
                    lambda = zeros(maxoutliers,1);
                    R = zeros(maxoutliers,1);
                    Rloc = zeros(maxoutliers,1);
                    
                    for i = 1:min(n,maxoutliers)
                        [astd(i),amean(i)] = std(atemp);
                        [amax,loc] = max(abs(atemp - amean(i)));
                        R(i) = amax/astd(i);
                        atemp(loc) = [];
                        Rloc(i) = indvec(loc);
                        indvec(loc) = [];
                        
                        % compute lambda
                        pp = 1 - p / (2*(n-i+1));
                        t = matlab.internal.math.datafuntinv(pp,n-i-1);
                        lambda(i) = (n-i)*t/sqrt((n-i-1+t.^2)*(n-i+1));
                    end
                    
                    lastindex = find(R > lambda, 1, 'last');
                    
                    if isempty(lastindex)
                        tindex = 1;
                    else
                        tindex = min(lastindex+1,maxoutliers);
                    end
                    center(j) = amean(tindex);
                    lowerbound(j) = amean(tindex) - astd(tindex)*lambda(tindex);
                    upperbound(j) = amean(tindex) + astd(tindex)*lambda(tindex);
                end
            end
            
        case 'median'
            madfactor = -1 /(sqrt(2)*erfcinv(3/2));  %~1.4826
            center = median(a,1,'omitnan');
            amad = madfactor*median(abs(a - center), 1, 'omitnan');
            
            lowerbound = center - p*amad;
            upperbound = center + p*amad;
        case 'mean'
            center = mean(a,1,'omitnan');
            astd = std(a,0, 1,'omitnan');
            
            lowerbound = center - p*astd;
            upperbound = center + p*astd;
        case 'movmedian'
            madfactor = -1 /(sqrt(2)*erfcinv(3/2));  %~1.4826
            if isempty(sp) && isnumeric(sp)
                center = movmedian(a, wl, 1, 'omitnan');
                amovmad = madfactor*movmad(a, wl, 1, 'omitnan');
            else
                center = movmedian(a, wl, 1, 'omitnan', 'SamplePoints', sp);
                amovmad = madfactor*movmad(a, wl, 1, 'omitnan', 'SamplePoints', sp);
            end
            
            lowerbound = center - p*amovmad;
            upperbound = center + p*amovmad;
        case 'movmean'
            if isempty(sp) && isnumeric(sp)
                center = movmean(a, wl, 1, 'omitnan');
                amovstd = movstd(a, wl, 0, 1, 'omitnan');
            else
                center = movmean(a, wl, 1, 'omitnan','SamplePoints',sp);
                amovstd = movstd(a, wl, 0, 1, 'omitnan', 'SamplePoints', sp);
            end
            
            lowerbound = center - p*amovstd;
            upperbound = center + p*amovstd;
        case 'percentiles'
                lowup = double(lowup');
                apercentiles = prctile(a,lowup,1);
                center = mean(apercentiles, 1);  % used for replacement
                asiz = size(a);
                lowerbound = reshape(apercentiles(1,:),[1,asiz(2:end)]);
                upperbound = reshape(apercentiles(2,:),[1,asiz(2:end)]);
        otherwise %'quartiles'
                [aiqr, aquartiles] = iqr(a,1);    
                center = mean(aquartiles, 1);  % used for replacement
                asiz = size(a);
                lquartile = reshape(aquartiles(1,:),[1,asiz(2:end)]);
                uquartile = reshape(aquartiles(2,:),[1,asiz(2:end)]);

                lowerbound = lquartile - p*aiqr;
                upperbound = uquartile + p*aiqr;
    end
    
    tf = (a > upperbound | a < lowerbound);
end

if nargout > 4
    % compute b
    b = a;
    if ischar(replace) || isstring(replace)
        switch replace
            case 'center'
                if ismember(method, {'movmedian', 'movmean'})
                    b(tf) = center(tf);
                else
                    b(tf) = center(ceil(find(tf)/size(a,1)));
                end
            case 'clip'
                b = min(max(b,lowerbound,'includenan'),upperbound,'includenan');
            otherwise  % 'previous', 'next', 'nearest', 'linear', 'spline', 'pchip', 'makima'
                % loop through columns
                b = b(:,:);  % flatten
                usingSP = true;
                if isempty(sp)
                    sp = transpose(1:size(b,1));
                    usingSP = false;
                end
                isfloatsp = isfloat(sp);
                for colindex = 1:size(b,2)
                    % cast to full since GriddedInterpolant does not
                    % support sparse
                    bcol = full(b(:,colindex));                                                 
                    tfcol = tf(:,colindex);
                    nonOutliers = ~tfcol & ~isnan(bcol);
                    numNonOutliers = sum(nonOutliers);
                    if numNonOutliers > 1  % interpolation requires at least 2 data points
                        if strcmp(replace, 'linear') && isfloatsp && isfloat(bcol)
                            bcol = matlab.internal.math.linearInterpExtrap(sp, bcol, tfcol, nonOutliers, usingSP);
                        elseif isfloatsp
                            G = griddedInterpolant(sp(nonOutliers),bcol(nonOutliers),replace);
                            bcol(tfcol) = G(sp(tfcol)); % faster than interp1
                        else  % sp is datetime or duration
                            bcol(tfcol) = interp1(sp(nonOutliers),bcol(nonOutliers),sp(tfcol),replace,'extrap');
                        end
                    elseif numNonOutliers == 1  
                        % With one data point, we can replace for next,
                        % previous, or nearest. For the rest, do nothing.
                        nonOutlierIndex = find(nonOutliers);
                        if strcmp(replace, 'nearest')
                            bcol(tfcol) = bcol(nonOutlierIndex);
                        elseif strcmp(replace, 'next')
                            bcol(1:nonOutlierIndex-1) = bcol(nonOutlierIndex);
                        elseif strcmp(replace, 'previous')
                            bcol(nonOutlierIndex+1:end) = bcol(nonOutlierIndex);
                        end
                    end
                    b(:,colindex) = bcol;
                end
                b = reshape(b, size(a));
        end
    else % isscalar(replace)
        b(tf) = replace;
    end
end