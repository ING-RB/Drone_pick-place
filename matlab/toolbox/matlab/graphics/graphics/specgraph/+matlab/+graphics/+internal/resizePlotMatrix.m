function [] = resizePlotMatrix(hAxes, rows, cols)
% This undocumented function may be removed in a future release.

% This function updates the position value of the sub axes when the
% background axes position is updated.

% Copyright 2018-2020 The MathWorks, Inc.

validUserData = isa(hAxes, 'matlab.graphics.axis.Axes') && isvalid(hAxes);
userData = hAxes.UserData;

if numel(userData) >= 3 && iscell(userData)
    % Validate if dimensions are right and are valid axes
    validUserData = validUserData && isequal(size(userData{1}), [rows cols]) &&...
        isa(userData{1}, 'matlab.graphics.axis.Axes') && all(all(isvalid(userData{1})));
else
    validUserData = false;
end

if validUserData && ~isequal(hAxes.InnerPosition, userData{3})
    % Refactored code from plotmatrix when initially plotting axes
    units = get(hAxes,'Units');
    pos = get(hAxes,'InnerPosition');
    width = pos(3)/cols;
    height = pos(4)/rows;
    space = .02; % 2 percent space between axes
    pos(1:2) = pos(1:2) + space*[width height];
    for i=rows:-1:1
        for j=cols:-1:1
            axPos = [pos(1)+(j-1)*width pos(2)+(rows-i)*height ...
                width*(1-space) height*(1-space)];
            hAxes.UserData{1}(i,j).Units = units;
            hAxes.UserData{1}(i,j).InnerPosition = axPos;
            if i == j && ~isempty(hAxes.UserData{2}) &&...
                    isequal(size(userData{2}), [1 rows]) &&...
                    isa(userData{2}(i), 'matlab.graphics.axis.Axes') && isvalid(userData{2}(i))
                hAxes.UserData{2}(i).Units = units;
                hAxes.UserData{2}(i).InnerPosition = axPos;
            end
        end
    end
    hAxes.UserData{3} = hAxes.InnerPosition;
end
end
