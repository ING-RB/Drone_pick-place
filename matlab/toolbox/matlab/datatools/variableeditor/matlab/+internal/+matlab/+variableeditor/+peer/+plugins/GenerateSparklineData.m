function [packagedData, histCountsEdges] = GenerateSparklineData(data, originalMin, originalMax)
    arguments
        data
        originalMin
        originalMax
    end

    if height(data) < 1
        % There is nothing we can generate if there is no data.
        %
        % This occurs if these steps are taken:
        % 1. Generate sparkline data for a column that has, say, 100 rows.
        % 2. In a separate categorical column, filter away all 100 rows.
        % 3. Attempt to generate sparkline data for the same column. It is empty
        %    at this point, and so there is nothing to generate.

        % In this case, we generate dummy data. The purpose of this dummy data
        % is to correctly display the x-axis labels, rather than leaving
        % them blank. We cannot display the y-axis labels, as we do not
        % have that information.

        plotData = struct;
        plotData.type = 'histogram';
        plotData.isLinear = false;
        plotData.categoryDataType = 'discrete';

        % We create a handful of bins so that the client-side rendering puts the
        % x-axis labels farther apart. If we stuck with, say, 2 bins, the
        % labels would be too close to each other.
        numCategories = 6;
        plotData.categories = [repmat(originalMin, 1, numCategories/2), ...
            repmat(originalMax, 1, numCategories/2)];
        plotData.categoryMinMaxes = struct('min', num2cell(zeros(1, numCategories)), ...
            'max', num2cell(zeros(1, numCategories)));
        plotData.categoryCounts = zeros(1, numCategories);

        packagedData.sparklineProperties = plotData;
        histCountsEdges = [];
        return;
    end % -------------

    % Clean the data.
    %
    % g1788994: Inf or -Inf values in Columns need to be ignored
    % while creating the filtering visualizations
    isNotTimeData = ~(isdatetime(data.Values) || isduration(data.Values));
    if isNotTimeData
        cleanedData = data.Values(data.Values > -Inf & data.Values < Inf);
    else
        cleanedData = data.Values;
    end

    % # Prep
    plotData = struct;
    plotData.type = 'histogram';
    % If the data is datetime, we will need to send additional
    % JavaScript-compliant "Date" strings.
    % TODO: Stop generating this field. It is not used in the frontend.
    plotData.dtMinMaxJSFormat = [];

    % Determine the type of our data.
    % We check if it's of type time first to save on computing resources.
    allDatetimeValues = isdatetime(cleanedData(1));
    allDurationValues = isduration(cleanedData(1));

    if allDatetimeValues
        catDataType = 'datetime';
    elseif allDurationValues
        catDataType = 'duration';
    else
        allInts = all(int64(cleanedData) == cleanedData);
        if allInts
            catDataType = 'discrete';
        else
            catDataType = 'continuous';
        end
    end

    useIntBinning = false;

    % # Generate the sparkline data as well as their minimums and maximums.
    if (allDatetimeValues || allDurationValues)
        [counts, edges] = histcounts(cleanedData);
        minEdges = edges(1:end-1);
        maxEdges = edges(2:end);

        mins = string(minEdges);
        maxes = string(maxEdges);

        % Create JavaScript "Date"-compliant strings to send to the client.
        if allDatetimeValues
            % JSF = JavaScript Format
            JSF = 'yyyy-MM-dd''T''HH:mm:ss.sssZ';
            JSFMins = cellstr(minEdges, JSF);
            JSFMaxes = cellstr(maxEdges, JSF);

            plotData.dtMinMaxJSFormat = struct('min', JSFMins, 'max', JSFMaxes);
        end
    else
        % We set a maximum amount of bins we want to plot for integer data.
        % Due to the way the integer bin method works, the amount of bins
        % generated is the range of the data. I.e., if our data ranges from
        % 20 to 80, we will have 60 bins.
        %
        % If the range is too large, the bins will be drawn too small to
        % visually be useful to the user. In this case, we revert to
        % binning the data as normal.
        maxIntegerBins = 125;
        useIntBinning = allInts & ((max(cleanedData) - min(cleanedData)) <= maxIntegerBins);

        % g2953400: Add limits to histcounts based on the original data. We
        % want to display the true range of the data, even if a sizable amount
        % of the original data is excluded due to filtering from other columns in the table.
        limits = [originalMin originalMax];
        if useIntBinning 
            [counts, cats] = histcounts(cleanedData, 'BinLimits', limits, 'BinMethod', 'integers');
            % Correct the categories.
            cats(2:end) = cats(2:end) + 0.5;
            cats(end) = [];

            mins = cats;
            maxes = cats;

            % Categories are edges; the "edges" variable gets used later in this function.
            edges = cats;
        else % Continuous data or integer data with a range too large
            [counts, edges] = histcounts(cleanedData, 'BinLimits', limits);
            mins = edges(1:end-1);
            maxes = edges(2:end);
        end
    end

    catsMinMax = struct('min', num2cell(mins), 'max', num2cell(maxes));

    % # Create range labels for non-int binning histograms.
    if ~useIntBinning
        countsLength = length(counts);
        cats = [strings(1, countsLength-1)];
        createLabelFunc = @(min, max) min + " - " + max;

        % Create labels
        if countsLength > 0
            if (allDatetimeValues || allDurationValues)
                labelParts = string(edges);
            else
                labelParts = edges;
            end

            for i = 1:countsLength
                cats(i) = createLabelFunc(labelParts(i), labelParts(i+1));
            end
        end
    end

    plotData.isLinear = false;
    plotData.categories = cats;
    plotData.categoryMinMaxes = catsMinMax;
    plotData.categoryCounts = counts;
    plotData.categoryDataType = catDataType;

    histCountsEdges = edges;

    packagedData.sparklineProperties = plotData;
end