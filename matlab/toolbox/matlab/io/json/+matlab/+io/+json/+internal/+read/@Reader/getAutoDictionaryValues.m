function values = getAutoDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    if ~r.containsNestedValues() && r.homogenizableValueTypes()
        switch max(r.valueTypes)
          case JSONType.Null
            values = repmat(missing, r.numValues, 1);
          case JSONType.False
            values = false(r.numValues, 1);
            values(r.valueTypes == JSONType.True) = true(sum(r.valueTypes == JSONType.True), 1);
          case JSONType.True
            values = false(r.numValues, 1);
            values(r.valueTypes == JSONType.True) = true(sum(r.valueTypes == JSONType.True), 1);
          case JSONType.String
            % Check if there are any datetime/duration values.
            if r.hasUniformStringType(opts)
                % Homogeneous array of string/datetime/durations
                switch max(r.stringTypes)
                  case StringType.Text
                    values = repmat(string(missing), r.numValues, 1);
                    values(r.valueTypes == JSONType.String) = r.strings;
                    values(r.valueTypes == JSONType.Null) = string(missing);
                  case StringType.Datetime
                    timeValues = convertStringToHomogeneousTypeWithFormatCoercion(r.strings, opts.ValueImportOptions{"datetime"});
                    values(r.valueTypes == JSONType.String) = timeValues;
                    values(r.valueTypes == JSONType.Null) = NaT;
                  case StringType.Duration
                    timeValues = convertStringToHomogeneousTypeWithFormatCoercion(r.strings, opts.ValueImportOptions{"duration"});
                    values(r.valueTypes == JSONType.String) = timeValues;
                    values(r.valueTypes == JSONType.Null) = duration(missing);
                end
                values = reshape(values, [], 1);
            else
                % Heterogeneous types. Make a cell dictionary
                % instead.
                values = r.getCellDictionaryValues(opts);
            end

          case JSONType.Number
            if r.hasUniformNumberType()
                switch max(r.numberTypes)
                  case NumericType.Double
                    values = NaN(r.numValues, 1);
                    values(r.valueTypes == JSONType.Number) = r.doubles;
                  case NumericType.UInt64
                    values = zeros(r.numValues, 1, "uint64");
                    values(r.valueTypes == JSONType.Number) = r.uint64s;
                  case NumericType.Int64
                    values = zeros(r.numValues, 1, "int64");
                    values(r.valueTypes == JSONType.Number) = r.int64s;
                end
            else
                % Attempt coercion to uint64
                if r.canConvertToUint64()
                    values = zeros(size(r.numberTypes), "uint64");
                    values(r.numberTypes == NumericType.Double) = uint64(r.doubles);
                    values(r.numberTypes == NumericType.UInt64) = r.uint64s;
                    % Attempt coercion to int64
                elseif r.canConvertToInt64()
                    values = zeros(size(r.numberTypes), "int64");
                    values(r.numberTypes == NumericType.Double) = int64(r.doubles);
                    values(r.numberTypes == NumericType.UInt64) = int64(r.uint64s);
                    values(r.numberTypes == NumericType.Int64) = r.int64s;
                else
                    % Fall back to cell dictionary.
                    values = r.getCellDictionaryValues(opts);
                end
            end
        end
    else
        values = r.getCellDictionaryValues(opts);
    end
end
