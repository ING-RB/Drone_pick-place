function [y, x, xInd] = thinDataForPlotting(yData, NVPairs)
    % thinDataForPlotting returns a subset of data optimized for
    % visualizations.  Takes in a y-vector and optionally the x vector,
    % max number of elements, and method.

    % Copyright 2021-2023 The MathWorks, Inc.

    arguments
        yData {mustBeVector}
        NVPairs.XData {mustBeVector} = 1:length(yData)
        NVPairs.MaxElements (1,1) double = 10000
        NVPairs.Method (1,1) string {mustBeMember(NVPairs.Method, ["minMax", "outliers"])} = "minMax"
    end

    h = height(yData);
    x = NVPairs.XData;
    y = yData;

    if isduration(yData) || isdatetime(yData) || iscalendarduration(yData)
        y = dateDurToDouble(yData);
    elseif isnumeric(yData) && ~isreal(yData)
        x = real(yData);
        y = imag(yData);
    end

    if issparse(yData)
        x = find(yData);
        y = nonzeros(yData);
    end

    % If the length of the vector is shorter than the max elements just
    % return the new "fixed" data
    if length(y) <= NVPairs.MaxElements
        if ~isrow(x)
            x = x';
        end
        if ~isrow(y)
            y = y';
        end

        xInd = 1:length(x);

        x = dateDurToDouble(x);

        return;
    end

    if NVPairs.Method == "minMax"
        [y, x, xInd] = thinDataMinMaxInOut(y, x, NVPairs.MaxElements);
    else
        [y, x, xInd] = thinDataOutliers(y, x, NVPairs.XData, NVPairs.MaxElements);
    end

    % Make sure timestamps are laid out correctly
    x = dateDurToDouble(NVPairs.XData(xInd));

    if ~isrow(x)
        x = x';
    end
    if ~isrow(y)
        y = y';
    end
end

function numTime = dateDurToDouble(data)
    numTime = data;
    if isduration(data) || isdatetime(data) || iscalendarduration(data)
        if isdatetime(data)
            numTime = datenum(data);
        elseif isduration(data)
            numTime = milliseconds(data);
        elseif iscalendarduration(data)
            numTime = calToDatenum(data);
        end

        % Shift x to start at 0
        numTime = numTime - min(numTime);
    end
end


function [y, x, xInd] = thinDataOutliers(yData, x, origXData, maxElements)
    % Uses min, max, and outlier detection to optimize the thinned data in
    % order to keep interesting points in the subset, as well as missing
    % data.

    outlierData = [];
    missingData = [];
    [~, minX] = min(yData);
    [~, maxX] = max(yData);

    l = height(yData);

    % Make sure to keep interesting data (e.g. outliers, missing)
    outlierData = zeros(1,l);
    if ~isduration(yData) && ~isdatetime(yData) && ~iscalendarduration(yData)
        if isduration(origXData) || isdatetime(origXData) || iscalendarduration(origXData)
            t = timetable(origXData,yData);
            outlierData = isoutlier(t,'DataVariables','yData','OutputFormat','logical'); % Make sure to keep outlier data
            missingData = ismissing(t,'OutputFormat','logical'); % Make sure to keep missing data
        else
            try
                outlierData = isoutlier(y); % Make sure to keep outlier data
            catch
                % Some datatypes may error here (complex data for
                % instance)
            end
            try
                missingData = ismissing(y); % Make sure to keep missing data
            catch
                % Some datatypes may error here (complex data for
                % instance)
            end
        end
    else
        missingData = ismissing(y); % Make sure to keep missing data
    end

    % Sample down outliers and missing if more than 10% of
    % maxElements
    outlierX = x(outlierData);
    if (length(outlierX) > (0.1 * maxElements))
        sampleStep = ceil(length(outlierX)/(maxElements * 0.1));
        outlierX = outlierX(1:sampleStep:length(outlierX));
    end

    missingX = x(missingData);
    if (length(missingX) > (0.1 * maxElements))
        sampleStep = ceil(length(missingX)/(maxElements * 0.1));
        missingX = missingX(1:sampleStep:length(missingX));
    end

    sampleStep = ceil(l/maxElements);
    xInd = unique([find(outlierData'), find(missingData'), 1:sampleStep:l, minX, maxX, 1, l]);
    x = x(xInd);

    y = yData(xInd);
end


function [y, x, xInd] = thinDataMinMaxInOut(yData, xData, maxElements)
    % Uses min, max, first and last elements, along with missing values to
    % subset the data.
    arguments
        yData {mustBeVector}
        xData {mustBeVector}
        maxElements (1,1) double {mustBePositive}
    end

    l = length(yData);

    numSamples = 5;
    maxPoints = ceil(maxElements / numSamples);
    pointsPerBin = ceil(l / maxPoints);

    x = zeros(1, numSamples * maxPoints);

    for bin = 1:maxPoints
        binIndex = (bin-1) * numSamples + 1;
        binStart = min((bin-1) * pointsPerBin + 1, l);
        binEnd = min(binStart + pointsPerBin - 1, l);
        binData = yData(binStart:binEnd);
        y(binIndex) = binData(1);
        x(binIndex) = binStart;
        [~, minI] = min(binData);
        [~, maxI] = max(binData);
        if (minI < maxI)
            x(binIndex+1) = minI+binStart-1;
            x(binIndex+2) = maxI+binStart-1;
        else
            x(binIndex+1) = maxI+binStart-1;
            x(binIndex+2) = minI+binStart-1;
        end
        x(binIndex+3) = binEnd;

        x(binIndex+4) = nan;
        try
            md = find(ismissing(binData));
            if ~isempty(md)
                x(binIndex+4) = md(1);
            end
        catch
            % Some datatypes may error here (complex data for
            % instance)
        end
    end

    in = isnan(x);
    x(in) = [];
    x = unique(x);
    xInd = x;
    if ~isempty(xData)
        x = xData(x);
    end
    y = yData(xInd);
end

function dn = calToDatenum(c)
    [y,m,d,t] = split(c, {'years', 'months', 'day', 'time'});
    dn = datenum(datetime(y,m,d) + t);
end
