classdef ObjectDataModel < internal.matlab.variableeditor.ArrayDataModel & ...
        internal.matlab.variableeditor.EditableVariable

    % ObjectDataModel
    % Data Model for Objects in the Variable Editor

    % Copyright 2013-2021 The MathWorks, Inc.

    % Type
    properties (SetAccess = private)
        % Type Property
        Type = 'Object';

        % Will be set to the object name when data is set
        ClassType = 'object';
    end

    % Data
    properties (SetObservable = true)
        % Data Property
        Data = [];
    end

    properties
        NumberOfColumns;
    end

    properties(Hidden)
        % Whether the object represented by this DataModel is currently being
        % debugged or not
        ObjectBeingDebugged (1,1) logical = false;

        % The struct representation of the object represented by the DataModel.
        % This is used to display private/protected properties, because the only
        % way to get the value currently is to cast to struct.
        ObjectStruct struct = struct.empty;

        % Metaclass data for the object
        MetaclassData = [];
    end

    methods
        function storedValue = get.Data(this)
            if this.ObjectBeingDebugged
                % Use the stored ObjectStruct, so the protected/private
                % properties can be displayed
                storedValue = this.ObjectStruct;
            else
                storedValue = this.Data;
            end
        end

        function set.Data(this, newValue)
            if (~isobject(newValue) && ~ishandle(newValue))
                error(message('MATLAB:codetools:variableeditor:NotAnObject'));
            end

            % Assign the class type
            this.ClassType = class(newValue); %#ok<MCSUP>
            reallyDoCopy = this.isDataEqual(newValue);
            if reallyDoCopy
                this.Data = newValue;
            end

            this.initMetaclassData(newValue);
            if this.detectObjectBeingDebugged()
                this.initDebugProperties();
            end
        end


        function b = objectBeingDebugged(this)
            % Returns true if the object represented by the DataModel is
            % currently being debugged
            b = this.ObjectBeingDebugged;
        end
    end

    methods (Access = public)
        % getSize
        function s = getSize(this)
            if this.ObjectBeingDebugged
                s = [length(fieldnames(this.Data)) this.NumberOfColumns];
            else
                s = [length(properties(this.Data)) this.NumberOfColumns];
            end
        end

        function rhs = getRHS(~, data)
            % Called to get the RHS for an assignment
            if isnumeric(data)
                % Avoiding loss of precision by formatting to a large
                % number of decimal places
                rhs = num2str(data, '%20.20f');
            else
                rhs = data;
            end
        end

        function m = getMetaClassInfo(this)
            m = this.MetaclassData;
        end

        % Size is not cached for objects, getSize computes size
        % dynamically.
        function updateCachedSize(this)
        end
    end

    methods (Hidden)
        function initDebugProperties(this)
            % Eval a call to cast the object to a struct.  This currently is the
            % only way to get access to the value of protected/private
            % properties all in one go.
            warningState = warning("query", "MATLAB:structOnObject");
            warning("off","MATLAB:structOnObject");
            c = onCleanup(@() warning(warningState.state, "MATLAB:structOnObject"));

            try
                this.ObjectStruct = evalin("debug", "struct(" + this.Name + ");");
            catch
                % This typically only happens in unit test situations
                this.ObjectBeingDebugged = false;
            end
        end

        function initMetaclassData(this, value)
            % Initialize the metaclass data for the object
            this.MetaclassData = metaclass(value);
        end

        function b = detectObjectBeingDebugged(this, st)
            % Called to detect if the object represented by this DataModel
            % is the object currently being debugged.

            arguments
                this

                % The debug stack, the results of calling dbstack -completenames
                st = [];
            end

            b = false;
            if isempty(st)
                [st, ~] = dbstack("-completenames");
            end

            try
                % Go through the stack, stripping off any of our internal code
                for idx = 1:length(st)
                    fn = st(idx).file;
                    if (contains(fn, "datatools") && contains(fn, "+internal")) || contains(fn, "openvar")
                        continue;
                    end
                    break;
                end

                % Handle any function_handle calls, stripping off arguments
                s = string(st(idx).name);
                if contains(s, "@")
                    extractVal = extractBetween(s, ")", "(");
                    if ~isempty(extractVal)
                        s = extractVal;
                    end
                end

                % Split out any packages
                s = split(s, ".");

                if length(s) > 1
                    s = s(end-1);
                end
                callingClass = s;

                if isequal(callingClass, class(this.Data))
                    b = true;
                else
                    % Check if the breakpoint is in a superclass of the object
                    % being debugged
                    sc = superclasses(this.Data);
                    b = any(cellfun(@(x) isequal(callingClass, x), sc));
                end
            catch
            end

            this.ObjectBeingDebugged = b;
        end
    end

    methods (Access = protected)
        function lhs = getLHS(this, varargin)
            % Called to get the LHS for an assignment
            if this.ObjectBeingDebugged
                props = fieldnames(this.Data);
            else
                props = properties(this.Data);
            end
            prop = props{varargin{2}};

            % Will be '.<property>'
            lhs = sprintf('.%s', prop);
        end

        function reallyDoCopy = isDataEqual(this, newValue)
            try
                reallyDoCopy = ~isequal(this.Data, newValue);
            catch
                reallyDoCopy = true;
            end
        end

    end
end
