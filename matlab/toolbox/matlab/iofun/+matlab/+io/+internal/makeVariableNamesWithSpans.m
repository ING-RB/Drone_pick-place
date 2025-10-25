function [names,wasEmpty]=makeVariableNamesWithSpans(names,preserve,mergedCellColumnRule)
% This function is undocumented and will change in a future release.

%   Copyright 2021 The MathWorks, Inc.

if mergedCellColumnRule=="placeright"
    names = fliplr(names);
end

% robustness
if ~isempty(names) && ismissing(names(1))
    names(1) = "";
end

% header cells under a colspan start with the same names,
% which will get numbers added down below; remember these
% for removing from selected variables below if empty data
spannedCells = ismissing(names);
for pos = find(spannedCells)
    if pos > 1
        names(pos) = names(pos-1);
    end
end

if mergedCellColumnRule=="placeright"
    names = fliplr(names);
    spannedCells = fliplr(spannedCells);
end

needName = strlength(names)<1;
names(needName) = "Var" + (1:sum(needName));

if ~preserve
    names = matlab.lang.makeValidName(names);
end

names = matlab.lang.makeUniqueStrings(names,{},namelengthmax);
wasEmpty = needName | spannedCells;

