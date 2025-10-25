function dateTimeValue = convertToDateTime(matlabValue)
    if isstruct(matlabValue)
        % datetime struct from client side, which could be an array
        % to hold multiple datetime values
        if isvector(matlabValue.Year) && numel(matlabValue.Year) > 0
            % A struct array with multiple datetime vlaues
            % two values: {Year:[2017 2018], Month:[11 12], Day:[28 29]}
            % one value: {Year:[2017], Month:[11], Day:[28]}
            % add numel check for tComponentCodeGenerationTest
            % since MATLAB sends empty date a [1x0] vector instead
            % of []
            dateTimeValue = [];
            for i = 1:numel(matlabValue.Year)
                dateTimeValue = [dateTimeValue datetime([matlabValue.Year(i) matlabValue.Month(i) matlabValue.Day(i)])];
            end
        else
            % A datetime struct with one value from client side
            % {Year:2017, Month:11, Day:28}
            if any(structfun(@isempty, matlabValue))
                % Empty datetime value
                dateTimeValue = datetime.empty();
            else
                dateTimeValue = datetime([matlabValue.Year, matlabValue.Month, matlabValue.Day]);
            end
        end
    end
end
