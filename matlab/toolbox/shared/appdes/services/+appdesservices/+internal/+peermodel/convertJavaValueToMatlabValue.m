function matlabValue = convertJavaValueToMatlabValue(javaValue)
% CONVERTJAVAVALUETOMATLABVALUE 
% Converts a Java value to a MATLAB value

% Copyright 2017 - 2020 The MathWorks, Inc.
    
    % Pre-finesse any values
    if(isa(javaValue, 'java.util.ArrayList'))
        % Convert ArrayLists to regular Java arrays for ease in processing
        javaValue = javaValue.toArray();
    end

    % Convert the value
    valueClass = class(javaValue);

    % Convert values
    matlabValue = javaValue;
    switch(valueClass)

        % Note about all array conversion below
        %
        % PeerNodes interpret 1D arrays as row vectors
        %
        % So when retrieving values from Peer Nodes / Java Events, the row
        % vectors here are explicitly reshaped to be 1xN vectors.
        case 'char'
            if isDateTimeValue(matlabValue)
                % NaT as the string, which represents a invalid datetime
                matlabValue = convertToDateTime(matlabValue);
            end
            
        case 'java.lang.Object[]'

            % Check for empty array
            %
            % Want to avoid creating things like 'Empty matrix: 1-by-0'
            if(matlabValue.length == 0)
                matlabValue = [];
                return;
            end

            % Go through each element, see if it is all doubles or a mix
            % of doubles and strings
            isAllDoubles = true;
            isAllStructs = true;
            isAllArrays = true;
            for jdx = 1:length(matlabValue)
                if(~isnumeric(matlabValue(jdx)))
                    isAllDoubles = false;
                end
                if(~isa(matlabValue(jdx), 'java.util.HashMap'))
                    isAllStructs = false;
                end
                if(~isa(matlabValue(jdx), 'java.lang.Object[]'))
                    isAllArrays = false;
                end
            end

            if(isAllDoubles)
                % homogenous data, such as array of doubles
                %
                % Ex: MajorTicks
                %
                %
                array = cell2mat(cell(matlabValue));
                matlabValue = reshape(array, 1, length(array));
            elseif(isAllArrays)
                % If the javaMap contains arrays as elements, then
                % convert the elements into doubles as well. This is
                % done by recursively calling the convertValue method.
                finalArray = [];
                for jdx = 1:numel(matlabValue)
                    finalArray(jdx,:) = convertValue(matlabValue(jdx));
                end
                matlabValue = finalArray;
            elseif(isAllStructs)
                % Structs with the same properties will produce an array of
                % structs
                % Structs with differeing properties will produce a cell
                % array of structs
                isUniform = true;

                for jdx = 1:length(matlabValue)
                    if(matlabValue(1).keySet ~= matlabValue(jdx).keySet)
                        isUniform = false;
                    end
                end
                if (isUniform)
                    for jdx = 1:length(matlabValue)
                        structArray(jdx) = ...
                            appdesservices.internal.peermodel.convertJavaMapToStruct(matlabValue(jdx));
                    end
                    matlabValue = structArray;
                else
                    matlabValue = cell(matlabValue);
                    for jdx = 1:length(matlabValue)

                        matlabValue{jdx} = ...
                            appdesservices.internal.peermodel.convertJavaMapToStruct(matlabValue{jdx});

                    end

                end


            else
                % heterogenous data, so use a cell
                %
                % Ex: MajorTickLabels, States
                cellArray = cell(matlabValue);
                matlabValue = reshape(cellArray, 1, length(cellArray));
                for jdx = 1:length(matlabValue)
                    valueType = class(matlabValue{jdx});
                    if strcmp(valueType, 'java.util.HashMap') || strcmp(valueType, 'java.util.HashMap[]')
                        matlabValue{jdx} = ...
                            appdesservices.internal.peermodel.convertJavaValueToMatlabValue(matlabValue{jdx});
                    end

                end

            end

        case 'java.lang.Object[][]'
            % The only use case for multi-dimensional data is for doubles,
            % so explicitly convert to doubles
            %
            % Ex: ScaleColorLimits
            %
            % - First to a cell of numbers
            % - Then to a regular array
            matlabValue = cell2mat(cell(matlabValue));

        case 'java.lang.Double[]'
            array = cell2mat(cell(matlabValue));
            matlabValue = reshape(array, 1, length(array));

        case 'java.lang.Double[][]'
            array = cell2mat(cell(matlabValue));
            matlabValue = array;

        case 'java.lang.String'
            % convert to a char
            matlabValue = char(matlabValue);
            if isDateTimeValue(matlabValue)
                % NaT as the string, which represents a invalid datetime
                matlabValue = convertToDateTime(matlabValue);
            end

        case 'java.lang.String[]'
            % convert to cell array of strings
            array = cell(matlabValue);
            matlabValue = reshape(array, 1, length(array));

        case 'java.lang.Boolean'
            matlabValue = cell(matlabValue);
            matlabValue = matlabValue{1};

        case 'java.lang.Boolean[]'
            array = cell2mat(cell(matlabValue));
            matlabValue = reshape(array, 1, length(array));

        case 'java.util.HashMap'
            % Recusively convert the map to a struct
            matlabValue = appdesservices.internal.peermodel.convertJavaMapToStruct(matlabValue);
            if isDateTimeValue(matlabValue)
                matlabValue =convertToDateTime(matlabValue);
            end

        case 'java.util.HashMap[]'            
            newValue = [];
            for index = 1:numel(matlabValue)
                convertedMatlabValue = appdesservices.internal.peermodel.convertJavaMapToStruct(matlabValue(index));
                if isDateTimeValue(convertedMatlabValue)
                    convertedMatlabValue = convertToDateTime(convertedMatlabValue);
                end

                newValue = [newValue convertedMatlabValue];
            end
            matlabValue = newValue;
        case 'double'
            % Turn double arrays into row vectors
            %
            % Ex: Size, Location

            if isvector(matlabValue)
                % Only translate values to row vectors if the property value is
                % a vector.
                matlabValue = reshape(matlabValue, 1, numel(matlabValue));
            end
            % An example of a property value that may be a double, but not a
            % vector is color order

    end

        function isDateTime = isDateTimeValue(matlabValue)
            isDateTime = false;

            if ischar(matlabValue) && strcmp(matlabValue, 'NaT')
                isDateTime = true;
            elseif isstruct(matlabValue) && numel(fieldnames(matlabValue)) == 3 && ...
                    isfield(matlabValue, 'Year') && isfield(matlabValue, 'Month') && ...
                    isfield(matlabValue, 'Day')
                isDateTime = true;
            end
        end
    
        function dateTimeValue = convertToDateTime(matlabValue)
            if ischar(matlabValue) && strcmp(matlabValue, 'NaT')
                % char value from client side for NaT datetime: 'NaT'
                dateTimeValue = NaT;
            elseif isstruct(matlabValue)
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
end
