classdef PositionalEditor < internal.matlab.editorconverters.EditorConverter

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class provides the editor conversion needed for positional
    % properties, which are numeric arrays of a set number of elements (2,
    % 3, or 4), but display as separate fields like (x,y), (x,y,z) or
    % (x,y,width,height).

    % Copyright 2015-2022 The MathWorks, Inc.

    properties
        position;
        dataType;
        numElements;
        classname;
        format;
        formatDataUtils;
    end

    properties (Constant)
        % All the supported labels
        X_LABEL = 'x';
        Y_LABEL = 'y';
        Z_LABEL = 'z';
        WIDTH_LABEL = 'width';
        HEIGHT_LABEL = 'height';
        MIN_LABEL = 'min';
        MAX_LABEL = 'max';

        VALIDATE_MAX_GREATER_THAN_MIN = 'maxGreaterThanMin';
    end

    methods
        function this = PositionalEditor
            this.formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils;
        end

        function setServerValue(this, value, dataType, ~)
            % Sets the server value and current datatype.  (Some data types
            % can be ambiguous, like between some duration formats and
            % numeric values, or durations and datetimes)
            this.position = value;
            this.dataType = dataType;
        end

        function setClientValue(this, value)
            % Set the value from the client.  value is an array
            if ischar(value)
                this.position = str2num(value); %#ok<ST2NM>
                if iscolumn(this.position)
                    this.position = this.position';
                end
            else
                % Object array, try to convert where possible, fill in with
                % the appropriate missing value (nan or missing)
                if this.isNumeric
                    this.position = nan(1, length(value));
                elseif isequal(this.classname,'cell')
                    this.position = value;
                else
                    this.position = eval([this.classname '(repmat(missing, 1, length(value)))']);
                end

                for i = 1:length(value)
                    if iscell(value)
                        val = value{i};
                    else
                        val = value(i);
                    end
                    if isnumeric(val)
                        % Convert text to double
                        if isequal(this.classname,'cell')
                            % if the position is a cell value (e.g. heatmap, can accept string or number) we
                            % dont want to evalute, but keep the value as cell
                            % if it is cannot be converted to a number.
                            num = double(val);
                            if ~isempty(num) && ~isnan(num)
                                this.position{i} = num;
                            end
                        else
                            this.position(i) = double(val);
                        end
                    elseif isequal(this.classname, 'datetime')
                        % Convert text to datetime using the datetime
                        % constructor which accepts text
                        this.position(i) = datetime(char(val), ...
                            'InputFormat', this.format);

                    elseif isequal(this.classname, 'duration')
                        % There currently isn't a string constructor to
                        % duration objects, so we can't treat this like
                        % datetimes
                        %this.position(i) = duration(char(val));
                        this.position(i) = internal.matlab.datatoolsservices.VariableConversionUtils.getDurationFromText(...
                            char(val), this.format);

                    elseif isequal(this.classname, 'categorical')
                        this.position(i) = categorical({char(val)});

                    elseif isequal(this.classname,'cell')
                        % if the position is a cell value (e.g. heatmap, can accept string or number) we
                        % dont want to evalute, but keep the value as cell
                        % if it is cannot be converted to a number.
                        num = str2double(val);
                        if ~isempty(num) && ~isnan(num)
                            this.position{i} = num;
                        end
                    else
                        % try to eval the value (the user could have typed
                        % in 'pi')
                        try
                            this.position(i) = evalin('base', val);
                        catch
                            % Use the nan which is already in place
                        end
                    end
                end

                if this.isNumeric && length(this.position) == 1 && isnan(this.position) && isempty(value{1})
                    % Use [] for a single empty numeric input instead of NaN
                    this.position = [];
                end
            end
        end

        function value = getServerValue(this)
            % Return the server value
            value = this.position;

        end

        function value = getClientValue(this)
            % This is the displayed value, which is the text of the numeric
            % array.  (The edit value is the actual numeric array, by
            % default).
            if isnumeric(this.position)
                if isempty(this.position)
                    value = '';
                else
                    value = this.formatDataUtils.formatSingleDataForMixedView(this.position);
                end
            else
                value = strjoin(cellstr(this.position), ',');
            end
        end

        function props = getEditorState(this)
            % The editor state contains two properties, the number of
            % elements to break this array into, and the labels for the
            % positional fields, like x/y or x/y/width/height.
            props = struct;

            [f, validation] = this.getPositionalFieldsFromType;
            props.fields = f;
            props.validation = validation;
            props.numElements = length(props.fields);
            props.classname = class(this.position);

            % Additionally, specify the rich editor module to popup
            if (all(isprop(this.dataType, 'Name')) || ...
                    isfield(this.dataType, 'Name')) && ...
                    strcmpi(this.dataType.Name,'matlab.graphics.datatype.LimitsAny')
                props.richEditor = 'inspector_client/editors/ResetLimitsEditor';
            else
                props.richEditor = 'inspector_client/editors/PropertyFieldsEditor';
            end
        end

        function setEditorState(this, editorState)
            this.classname = class(editorState.currentValue);
            if isdatetime(editorState.currentValue) || ...
                    isduration(editorState.currentValue)
                this.format = editorState.currentValue.Format;
            end
        end
    end

    methods(Access = private)
        function [f, validation] = getPositionalFieldsFromType(this)
            % Returns the field names for the property, based on the
            % property type.  (It could be (x,y), (x,y,z), or
            % (x,y,width,height)
            f = {};
            validation = {};
            dataTypeName = this.getDataTypeName(this.dataType);

            if strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.LimitsWithInfs') ||...
                    strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.LimitsAny') || ...
                    strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.Limits')|| ...
                    strcmpi(dataTypeName,...
                    'internal.matlab.editorconverters.datatype.VectorData')
                f = {this.MIN_LABEL, this.MAX_LABEL};
                validation{end+1} = this.VALIDATE_MAX_GREATER_THAN_MIN;
            elseif strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.Point3') || ...
                    strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.PositivePoint3') || ...
                    strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.TextPosition')
                f = {this.X_LABEL, this.Y_LABEL, this.Z_LABEL};
            elseif any(strcmpi(dataTypeName, ...
                    {'matlab.graphics.datatype.Position',...
                    'matlab.graphics.chart.datatype.ScribePosition'}))
                f = {this.X_LABEL, this.Y_LABEL, ...
                    this.WIDTH_LABEL, this.HEIGHT_LABEL};
            elseif strcmp(dataTypeName, ...
                    'matlab.graphics.datatype.Point2d')
                f = {this.X_LABEL, this.Y_LABEL};
            end
        end

        function n = isNumeric(this)
            n = true;
            if isequal(this.classname, 'datetime') || ...
                    isequal(this.classname, 'duration') || ...
                    isequal(this.classname, 'categorical') ||...
                    isequal(this.classname, 'cell')

                n = false;
            end
        end

    end
end
