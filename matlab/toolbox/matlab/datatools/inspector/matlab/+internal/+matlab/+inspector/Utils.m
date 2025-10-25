classdef Utils
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Utilities class used by the Property Inspector.

    % Copyright 2013-2025 The MathWorks, Inc.

    methods (Static = true)
        function s = createStructForObject(obj, p, excludeGraphics)
            % TODO: update callers of this to point to the
            % datatoolsservices version, there are some items that are
            % outside of our area.
            arguments
                obj

                % Properties can be passed in, or if not will be determined by
                % calling properties on the object.
                p = properties(obj);

                excludeGraphics logical = false;
            end

            warning("internal.matlab.inspector.Utils.createStructForObject deprecated and will soon be removed, use matlab.internal.datatoolsservices.createStructForObject");

            s = matlab.internal.datatoolsservices.createStructForObject(obj, p, excludeGraphics);
        end

        %
        % The following functions are only used by the Java Desktop
        % Property Inspector
        %

        function state = compare(obj1,obj2,propName)
            % Java utility method for comparing a property shared by 2
            % objects to determine if the property values are the same.
            state = isequal(get(obj1,propName),get(obj2,propName));
        end

        function jobj = java(obj)

            if numel(obj)==1
                jobj = java(obj);
                return
            end
            jobj = javaArray(class(java(obj(1))),numel(obj));
            for k=1:numel(obj)
                jobj(k) = java(obj(k));
            end
        end


        function outStr = getPossibleMessageCatalogString(inStr)
            l = lasterror; %#ok<LERR>
            try
                outStr = getString(message(inStr));
            catch
                outStr = inStr;
            end
            lasterror(l); %#ok<LERR>
        end
        
        % Strips the trailing zeros from the text representation of an
        % array of numeric values.  For example, value will be something
        % like: editValue = '[0.010000000000000,500,0.025000000000000]'
        % The return value will be: '[0.01,500,0.025]'
        function val = getArrayWithZerosStripped(value)
            if (isstring(value) || ischar(value)) && ...
                    startsWith(value, '[') && endsWith(value, ']')              
                % get indexed value such that length and indexing work
                % as expected
                value = convertStringsToChars(value);
                if contains(value, ";")
                    % This is the case where there's multiple rows in the array.
                    % For example: [1.000,2.000,3.000; 4.000,5.000,6.000]
                    % Split on the , and ; and then reassemble
                    
                    s = split(split(string(value(2:length(value)-1)), ";"), ",");
                    idx = contains(s, ".");
                    s(idx) = strip(s(idx), 'right', '0');

                    if size(s, 2) == 1
                        % This is one column, rejoin with semi-colons only
                        val = char("[" + join(s, ";") + "]");
                    else
                        % This is either a row vector or an NxM matrix
                        val = char("[" + join(join(s, ","), ";") + "]");
                    end
                else
                    % This is the case where there's a single row in the array.
                    % For example: [1.000,2.000,3.000]
                    s = split(string(value(2:length(value)-1)), ",");
                    idx = contains(s, ".");
                    s(idx) = strip(s(idx), 'right', '0');
                    s = strip(s, 'right', '.');
                    val = char("[" + join(s, ",") + "]");
                end
            else
                % Just return the argument if this doesn't appear to be an
                % array representation
                val = value;
            end
        end

        %support new class definition, using validation to get access the
        %property data type
        function PropDataType = getPropDataType(prop)
            if ~isempty(prop.Validation)
                PropDataType = prop.Validation.Class.Name;
            else
                PropDataType = prop.Type.Name;
            end
        end

        %support new class definition, using validation to get access the property
        function classType = getProp(prop)
            if ~isempty(prop.Validation)
                if isempty(prop.Validation.Class)
                    if isempty(prop.Validation.ValidatorFunctions)
                        % An empty Class object will be encountered if the user
                        % creates a validation for a property, but doesn't define
                        % its type, in which case it is defaulted to double.  For
                        % example:
                        %     properties
                        %         A (:,5)
                        %     end
                        classType = 'double';
                    else
                        % But if the ValidatorFunctions is set, the class must
                        % have a class value expected.  The inspector can treat
                        % this as 'any'
                        classType = 'any';
                    end
                else
                    classType = prop.Validation.Class;

                    % The only size validation the inspector differentiates with
                    % is for double scalar values.  Add additional check for
                    % this only.
                    if classType.Name == "double" && isequal(size(prop.Validation.Size), [1,2]) && ...
                            isa(prop.Validation.Size, 'meta.FixedDimension')
                        if prop.Validation.Size(1).Length == 1 && ...
                                prop.Validation.Size(2).Length == 1
                            classType = "double scalar";
                        end
                    end
                end
            else
                classType = prop.Type;
            end
        end

        %support new class definition, using validation to get access the
        %enumeration property
        function isEnum = isEnumeration(prop)
            if ~isempty(prop.Validation)
                isEnum = prop.Validation.Class.Enumeration;
            else
                isEnum = isa(prop.Type, 'meta.EnumeratedType');
            end
        end

        %support new class definition, using validation to get access the
        %enumeration property
        function isEnum = isEnumerationFrompropType(propType)
            if  isa(propType, 'meta.class')
                isEnum = propType.Enumeration;
            else
                isEnum = isa(propType, 'meta.EnumeratedType');
            end
        end

        % Get the help tooltip information.  Returns a struct array, with
        % one struct for each property of the given object, where each
        % contains the following fields:
        % - property:  the property name
        % - description:  the doc short description of the property
        % - inputs: the valid inputs.  For example: '[] | text value'
        function props = getObjectProperties(objName, data)
            arguments
                % Object name to get the help property information for.
                objName string
                data = []
            end

            if isempty(data)
                data = internal.matlab.inspector.Utils.getHelpDocResults(objName);
                if isempty(data) && contains(objName, '.tall')
                    % There are a set of graphics objects which are tall
                    % versions of the original object (tall line, tall scatter,
                    % etc...).  They have different class names, but are
                    % essentially the same in all other ways.  If we see one of
                    % these, look to its original object for help.
                    objName = replace(objName, '.tall', '');
                    data = internal.matlab.inspector.Utils.getHelpDocResults(objName);
                end
            end

            props = struct("property", {}, "description", {}, "inputs", {});

            if ~isempty(data)
                % Help doc data is in property groups.  Traverse each of
                % the groups, and get the information for each property
                % contained in the groups
                classPropertyGroups = data.ClassPropertyGroups;
                defaultTxt = getString(message("MATLAB:codetools:inspector:InspectorDefaultPropValue"));
                propIdx = 1;
                for idx = 1:length(classPropertyGroups)
                    classPropertyGroup = classPropertyGroups(idx);
                    classProperties = classPropertyGroup.ClassProperties;
                    for idx2 = 1:length(classProperties)
                        % Get the property object from the group
                        classProp = classProperties(idx2);
                        props(propIdx) = internal.matlab.inspector.Utils.getClassHelpProps(classProp, defaultTxt);
                        propIdx = propIdx + 1;
                    end
                end
            end
        end

        function classHelpProps = getClassHelpProps(classProp, defaultTxt)
            % Returns the struct containing the following fields:
            % 1. property: the property name
            % 2. description: short description of the property
            % 3. inputs: a pipe separated list of allowable values.  The
            % default value will have (Default) after it.
            classHelpProps = struct;
            classHelpProps.property = classProp.Name;
            classHelpProps.description = classProp.Purpose;

            % Denote which of the property values is the
            % default value
            match = classProp.Values == classProp.DefaultValue;
            if any(match)
                classProp.Values(match) = classProp.Values(match) + " (" + defaultTxt + ")";
            end

            classHelpProps.inputs = join(classProp.Values, " | ");

            % Replace any double-quotes in the tooltip info or description,
            % as this causes errors with JSON decoding on the client
            if contains(classHelpProps.inputs, '"')
                classHelpProps.inputs = strrep(classHelpProps.inputs, '"', "'");
            end
            if contains(classHelpProps.description, '"')
                classHelpProps.description = strrep(classHelpProps.description, '"', "'");
            end
        end

        function data = getHelpDocResults(objName)
            % Some uicomponent's properties can be found under Object and not Properties, 
            % so check for both
            p = [matlab.internal.reference.property.RefEntityType.Properties, matlab.internal.reference.property.RefEntityType.Object];
            req = matlab.internal.reference.api.ReferenceRequest(objName, p, "matlab");
            data = matlab.internal.reference.api.ReferenceDataRetriever(req).getReferenceData;

            if length(data) > 1
                % Some components are transitioning and have both Properties and Object pages, 
                % so just use the first one found 
                data = data(1);
            end
        end

        function flag = hasHelpInfo(applicationMap)
            for objectKey = keys(applicationMap)
                objectString = string(applicationMap(char(objectKey)));
                s = split(objectString, "tooltip");
                % check for tooltip information in any of the items (except the first
                % one since it has extra content at the beginning
                if any(~startsWith(extractAfter(s(2:end),5), "\"))
                    flag = true;
                    return;
                end
            end
            flag = false;
        end

        function [dispLocale, dtDispFormat, dtDateDispFormat, dtInputFormat] = ...
                getLocaleAndDTFormats()

            s = settings;
            dispLocale = s.matlab.datetime.DisplayLocale.ActiveValue;
            dtDispFormat = s.matlab.datetime.DefaultFormat.ActiveValue;
            dtDateDispFormat = s.matlab.datetime.DefaultDateFormat.ActiveValue;
            dtInputFormat = internal.matlab.inspector.Utils.getInputFormatForView(dtDateDispFormat);
        end

        function inputFormat = getInputFormatForView(displayFormat)
            % GETINPUTFORMATFORVIEW - Compute the format the end user will use when
            % entering dates in the edit field

            s = settings;
            defaultFormat = matlab.internal.datetime.filterTimeIdentifiers(...
                s.matlab.datetime.DefaultDateFormat.FactoryValue);

            % if the format is the factory default or all numeric, use that
            if isNumericOnly(displayFormat)

                % Display Format is all numeric
                inputFormat = displayFormat;
            else

                % Display Format has alpha representation of month or day
                % Use Localized numeric representation of component
                if isNumericOnly(defaultFormat)
                    inputFormat = defaultFormat;
                else
                    % Since CJK is numeric, if the default is not numeric, the default
                    % is US (dd-MMM-uuuu)
                    inputFormat = 'MM/dd/uuuu';
                end
            end

            function isNumericOnly = isNumericOnly(format)
                % ISNUMERICONLY - returns true if the format is rendered without day or
                % month names in localized text

                tempDate = datetime('today', 'Format', format);
                if isempty(regexprep(char(tempDate), '[\W\d]', ''))
                    isNumericOnly = true;
                else
                    isNumericOnly = false;
                end
            end
        end

        function v = isComponentInUIFigure(obj)
            % Returns true if the component is parented to a uifigure.  Non-graphics
            % objects will of course return false.
            v = false;
            if ~isempty(obj)
                try
                    if isa(obj, "matlab.ui.Figure")
                        v = all(arrayfun(@(x) matlab.ui.internal.FigureServices.isUIFigure(x), obj));
                    elseif isscalar(obj)
                        h = ancestor(obj, "figure");
                        v = matlab.ui.internal.FigureServices.isUIFigure(h);
                    else
                        v = all(arrayfun(@(x) matlab.ui.internal.FigureServices.isUIFigure(ancestor(x, "figure")), obj));
                    end
                catch
                    % This may fail for some non-graphics objects, ignore errors
                end
            end
        end
        
        function s = getPropValidationStruct(prop)
            % Uses the metaclass property info, props, to determine the min/max
            % value, the include min/max settings, and whether the property is
            % scalar (based on its size being set to (1,1) in the property
            % definition.
            %
            % Returns a struct with fields: MinValue, MaxValue, IsScalar,
            % IncludeMin and IncludeMax.

            [min, max, isScalar, includeMin, includeMax] = internal.matlab.inspector.Utils.getPropValidation(prop);
            s = struct;
            s.MinValue = min;
            s.MaxValue = max;
            s.IsScalar = isScalar;
            s.IncludeMin = includeMin;
            s.IncludeMax = includeMax;
        end
        
        function [minVal, maxVal, isScalar, includeMin, includeMax] = getPropValidation(prop) 
            % Uses the metaclass property info, props, to determine the min/max
            % value, the include min/max settings, and whether the property is
            % scalar (based on its size being set to (1,1) in the property
            % definition.
            minVal = -inf;
            maxVal = inf;
            isScalar = false;
            includeMin = true;
            includeMax = true;
            
            if ~isempty(prop) && ~isempty(prop.Validation) && ~isempty(prop.Type) && isa(prop.Type, "meta.type")
                typeName = string(prop.Type.Name);
                isScalar = contains(typeName, "(1,1)");
                
                validation = extractBetween(typeName, "{", "}");
                if ~isempty(validation)
                    pat = "mustBe" + wildcardPattern;

                    validationFcns = split(validation, pat);
                    for idx = 2:length(validationFcns)
                        validation = validationFcns(idx);
                        
                        if contains(validation, "(")
                            validationFcn = extractBefore(validation, "(");
                        elseif contains(validation, ",")
                            validationFcn = extractBefore(validation, ",");
                        else
                            validationFcn = validation;
                        end
                        validationArgs = extractBetween(validation, "(", ")");
                        validationArgsSep = validationArgs.split(",");
                        
                        switch(validationFcn)
                            case "GreaterThan"
                                minVal = str2double(validationArgsSep(2));
                                includeMin = false;
                                
                            case "GreaterThanOrEqual"
                                minVal = str2double(validationArgsSep(2));
                                
                            case "LessThan"
                                maxVal = str2double(validationArgsSep(2));
                                includeMax = false;
                                
                            case "LessThanOrEqual"
                                maxVal = str2double(validationArgsSep(2));
                                
                            case "InRange"
                                minVal = str2double(validationArgsSep(2));
                                maxVal = str2double(validationArgsSep(3));
                                
                            case "Positive"
                                minVal = 1;
                                
                            case "Nonpositive"
                                maxVal = 0;
                                
                            case "Nonnegative"
                                minVal = 0;
                                
                            case "Negative"
                                maxVal = -1;
                        end
                    end
                end
            end
        end

        function b = isAllGraphics(objs)
            % Returns true for objects in which isgraphics() returns true, or in
            % which their class name starts with "matlab.graphics".  This is
            % needed for objects like DataTipTemplate, which isgraphics() is
            % false, but are inspectable as part of the figure hierarchy.

            b = all(isgraphics(objs), "all");
            if ~b
                if length(objs) == 1 %#ok<ISCL>
                    % Need to call length() explicitly instead of isscalar
                    % because some objects override isscalar
                    c = class(objs);
                else
                    c = arrayfun(@class, objs, "UniformOutput", false, "ErrorHandler", @(~,~) '');
                end
                b = all(startsWith(c, "matlab.graphics"), "all");
            end
        end
    end
end
