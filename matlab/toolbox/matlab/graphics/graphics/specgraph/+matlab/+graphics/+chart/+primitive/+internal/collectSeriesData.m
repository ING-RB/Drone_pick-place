function [x,y,map] = collectSeriesData(hObjs)
% This function is undocumented and may change in a future release.

% The collectSeriesData utility for the Area and Bar objects.
% Input:
%   hObjs: A vector of Area or Bar objects.
% Output:
%   x: An m-by-1 vector containing the x-values collected from all the objects.
%   y: An m-by-n matrix containing the y-values corresponding to each
%   x-value for each object. Missing values are represented by NaN.
%   map: An m-by-n matrix indicating the YData index that corresponds
%   to each value in the matrix y.

%   Copyright 2016-2019 The MathWorks, Inc.

% Find out how many individual objects are in the series.
numObjs = numel(hObjs);

% If we have just one object, then just grab the XData and YData.
if numObjs == 1
    xData = hObjs.XDataCache;
    yData = hObjs.YDataCache;
    
    % Make sure that number of X-values matches the number of Y-values. If
    % not, then return empty, as though all the data is invalid.
    if numel(xData) ~= numel(yData)
        x = zeros(0,1);
        y = zeros(0,1);
        map = y;
        return
    end
    
    % Sort the XData and YData based on the XData.
    [x,map] = sort(xData(:));
    y = yData(map)';
else
    xData = get(hObjs,'XDataCache');
    yData = get(hObjs,'YDataCache');
    
    xLen = cellfun(@numel,xData);
    yLen = cellfun(@numel,yData);
    
    % Make sure that number of X-values matches the number of Y-values for
    % each individual object. If not, replace the X-values and Y-values of
    % that object with NaNs the same size as the Y-values so that the data
    % from that object is basically ignored.
    mismatch = xLen ~= yLen;
    if any(mismatch)
        for a = find(mismatch')
            xData{a} = NaN(1,yLen(a));
            yData{a} = NaN(1,yLen(a));
        end
        xLen = yLen;
    end
    
    % First check if the XData is uniform across the series.
    if all(xLen == xLen(1)) && all(cellfun(@(xd) isequaln(xData{1},xd),xData(2:end)))
        % Uniform XData, so just collect the YData into a matrix and sort
        % everything based on the XData.
        [x,map] = sort(xData{1}(:));
        y = cat(1,yData{:})';
        y = y(map,:);
        map = map(:,ones(1,numObjs));
        
    % We have mismatching XData across the members of the series.
    else
        % The series will use all unique and finite values of X.
        x = unique(cat(2,xData{:}))';

        % The series will use NaN for YData whenever the corresponding
        % XData was not present in the individual object.
        y = NaN(numel(x),numObjs);
        map = NaN(numel(x),numObjs);
        
        % Find the Y-values that correspond to each X-value.
        for a = 1:numObjs
            [tf,loc] = ismember(x,xData{a});
            map(tf,a) = loc(tf);
            y(tf,a) = yData{a}(loc(tf));
        end
    end
end

% Keep only the finite X-values and cast to double.
isXValid = isfinite(x);
x = double(x(isXValid));
y = double(y(isXValid,:));
map = map(isXValid,:);

end
