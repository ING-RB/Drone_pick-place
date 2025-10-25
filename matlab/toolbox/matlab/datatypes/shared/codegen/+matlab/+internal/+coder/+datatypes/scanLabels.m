function index = scanLabels(varname, labels)  %#codegen
%SCANLABELS Find the first occurence of a varname in a list of labels.

%  Copyright 2019-2020 The MathWorks, Inc.

index = 0;
for i = 1:length(labels)
    if strcmp(varname, labels{i})
        index = i;
        break;
    end
end