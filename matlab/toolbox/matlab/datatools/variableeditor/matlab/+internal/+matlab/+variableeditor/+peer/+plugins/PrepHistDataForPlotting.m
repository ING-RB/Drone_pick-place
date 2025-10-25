function [cats, counts] = PrepHistDataForPlotting(yData, plotWidth)
    arguments
        yData
        plotWidth
    end
    
    if isempty(yData)
        cats = [];
        counts = [];
        return;
    end

    % Fit as many bins as possible with a minimum of 5 pixels for each
    % bin
    allIntValues = (isnumeric(yData) && ~isenum(yData)) && all(floor(yData)==yData);
    isCats = iscategorical(yData) || isordinal(yData);
    isEnum = isenum(yData);
    ndata = rmmissing(yData);

    if isCats
        maxBars = inf;
    else
        minPixelsPerBar = 10;
        maxBars = floor(plotWidth/minPixelsPerBar);
    end

    if ~allIntValues
        % Assume all cateogies fit on screen
        
        newYData = yData;
        if ~isCats
            % Categorical will fail with the string "<missing>" so replace
            % them all with ##missing## then replace back at the end
            strYData = string(yData);
            strYData(strYData == "<missing>") = "##@@missing@@##";
            newYData = categorical(strYData); % Cast to string for enums
        end
        
        cats = categories(newYData);
        
        % Check for all blank strings g3052447
        if ~isempty(yData) && isempty(cats) || isstring(yData)
            if isempty(ndata)
                cats = string.empty;
                counts = [];
            else
                strNdata = regexprep(ndata, "(^ +| +$)", '${strrep(string($0), " ", "##@@space@@##")}');
                strNdata(strNdata == "<missing>") = "##@@missing@@##";
                strNdata(strNdata == "") = "##@@emptyString@@##";
                cats = unique(strNdata);
                % Categorical trims strings so we need to replace leading
                % and trailing spaces in order to get accurate histcounts
                counts = histcounts(categorical(strNdata), cats);
            end
        else
            [counts, cats] = histcounts(newYData);
        end
        
        % If you have two vectors of values, they need to align in direction
        % g2839960
        if ~iscolumn(cats)
            cats = cats';
        end
        
        if ~iscolumn(counts)
            counts = counts';
        end
        
        t = table(cats, counts);
        if ~isempty(ndata)
            if ~allIntValues
                t = sortrows(t, 'cats');
            else
                % Special case for all intger histogram don't sort by categories,
                % because they will be string representations and 1, 2, ..., 10, 11
                % will be sorted as 1, 10, 11, 2, 3, ..., 9
                [~,order] = sortrows(arrayfun(@str2double, t.cats));
                t = t(order,:);
            end
        end
        
        % If all bars don't fit group categories alphabetically
        if length(cats) > maxBars
            itemsPerBin = floor(height(t)/maxBars);
            remainder = height(t) - (maxBars * itemsPerBin);
        
            % Adjust bins to get even spread of # of categories per bin
            while remainder > itemsPerBin
                maxBars = maxBars - 1;
                itemsPerBin = floor(height(t)/maxBars);
                remainder = height(t) - (maxBars * itemsPerBin);
            end
        
            % Create the new bins, the new category name will be
            % <firstCategory> - <lastCategory>
            newCats = string.empty;
            for i=1:maxBars
                startIndex = (i-1)*itemsPerBin + 1;
                endIndex = startIndex + itemsPerBin - 1;
                if (startIndex ~= endIndex)
                    newCatName = string(t.cats{startIndex}) + " - " + string(t.cats{endIndex} + " (" + (endIndex - startIndex + 1) + ")");
                else
                    newCatName = string(t.cats{startIndex});
                end
                newCatCount = sum(t.counts(startIndex:endIndex));
                newCats = [newCats repmat(newCatName, 1, newCatCount)]; %#ok<AGROW>
            end
            if remainder > 0
                newCatCount = sum(t.counts(endIndex+1:end));
                if (endIndex+1 ~= length(t.cats))
                    newCatName = string(t.cats{endIndex+1}) + " - " + string(t.cats{end} + " (" + (length(t.cats) - endIndex+1 + 1) + ")");
                else
                    newCatName = string(t.cats{endIndex+1});
                end
                newCats = [newCats repmat(newCatName, 1, newCatCount)];
            end
            newYData = categorical(newCats);
        
            [counts, cats] = histcounts(newYData);
        end
    else
        % For integer values, if we're using the full range of data, we
        % need to potentially fill in gaps, tell histcounts to return all
        % values g3105646
        yData = double(yData);

        % Count -inf, and inf as separate bins
        hasNegInf = (sign(yData) < 0 & isinf(yData));
        hasPosInf = (sign(yData) < 0 & isinf(yData));
        yDataNoInf = yData(~isinf(yData));
        if ~any(yDataNoInf >= flintmax/2) && ~any(yDataNoInf <= -flintmax/2) % g3352742
            [counts] = histcounts(yDataNoInf, "BinWidth", 1, "BinMethod","integers");
        else
            % There are times that the integer values can be really large
            % and the BinMethod Integers can fail
            [counts] = histcounts(yDataNoInf, "BinWidth", 1);
        end
        maxY = max(yDataNoInf);
        minY = min(yDataNoInf);
        numBins = maxY - minY + 1;
        if numBins > maxBars
            step = double(ceil((maxY-minY)/maxBars));
            [counts,bins] = histcounts(yData, "BinWidth", step);
            cats = string(bins) + "-" + string(bins+(step-1));
            if length(cats) > length(counts)
                cats(end) = [];
            end
        elseif numBins ~= length(counts)
            % Cases with large distances in data with sparse bins
            nc = length(counts);
            step = double(ceil((max(yDataNoInf) - min(yDataNoInf))/nc));
            bins = minY:step:maxY;
            cats = string(bins) + "-" + string(bins+(step-1));
        else
            bins = string(min(yDataNoInf):max(yDataNoInf));
            cats = cellstr(bins);
        end
        if any(hasNegInf)
            cats = [string(-inf), cats];
            counts = [sum(hasNegInf), counts];
        end
        if any(hasPosInf)
            cats = [cats, string(inf)];
            counts = [counts, sum(hasPosInf)];
        end
    end
    
    if ~iscolumn(cats)
        cats = cats';
    end
    
    if ~iscolumn(counts)
        counts = counts';
    end
    
    t = table(cats, counts, 'VariableNames',{'cats','counts'});
    if ~isempty(ndata)
        if (isCats && ~allIntValues) || isEnum
            t = sortrows(t, {'counts', 'cats'}, ["descend", "ascend"]);
        elseif ~allIntValues
            t = sortrows(t, 'cats', "ascend");
        end
    end
    missingCount = sum(ismissing(yData));
    
    cats = t.cats;
    if isrow(cats)
        cats = cats';
    end
    cats(cats == "##@@missing@@##") = {'"<missing>"'};
    cats = strrep(cats, '##@@space@@##', ' ');
    cats(cats == "##@@emptyString@@##") = {""};
    if isstring(cats) && isscalar(cats)
        cats = cellstr(cats);
    end
    counts = t.counts;
    if isrow(counts)
        counts = counts';
    end
    
    if (missingCount > 0)
        missingCat = "<undefined>";
        if isstring(yData)
            missingCat = "<missing>";
        elseif isnumeric(yData)
            missingCat = "NaN";
        end
        if iscellstr(cats)
            cats{end + 1} = missingCat;
        elseif isstring(cats)
            cats(end + 1) = missingCat;
        end
        counts(end + 1) = missingCount;
    end
end

