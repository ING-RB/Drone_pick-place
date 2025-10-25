% Checks for a uniform data type

% Copyright 2015-2023 The MathWorks, Inc.

function [isUniform, className] = uniformTypeData(data)
    % ignore all the empty data entries
    nonEmptyData = data(~cellfun('isempty',data));

    % parse the data to see if all entries are of the same data type
    if ~isempty(nonEmptyData)
        isUniform = all(cellfun('isclass',nonEmptyData,class(nonEmptyData{1,1})));
        if isUniform && isnumeric(nonEmptyData{1,1})
            isUniform = isUniform && all(cellfun('length',data) <= 1);
        end

        if isUniform
            className = class(nonEmptyData{1,1});
        else
            className = 'mixed';
        end
    else
        isUniform = true;
        className = class(data{1,1});
    end
end
