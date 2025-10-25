classdef (Abstract, HandleCompatible) CustomDisplay < matlab.mixin.CustomDisplay
    %CUSTOMDISPLAY provides a way of displaying properties and
    % methods of hardware interfaces when doing a disp on the object of the
    % interface. To use this, the hardware interface class needs to inherit
    % from this class instead of matlab.mixin.CustomDisplay. In the
    % hardware interface class constructor, pass in the necessary
    % properties, as shown in the example below:
    %
    % e.g. in the constructor of a class called "CustomInterface"
    % inheriting from CustomDisplay -
    % obj.PropertyGroupNames = ["CategoryA", "CategoryB"]
    % obj.PropertyGroupList = {["A", "B", "C"], ["E", "F"]} % where "A",
    % "B", "C", "E", and "F" are class properties
    %
    % disp(obj) would give the following output -
    %     CustomInterface with properties
    %        CategoryA
    %                  A: <Value of property A>
    %                  B: <Value of property D>
    %                  C: <Value of property C>
    %
    % Show all properties <link>, functions <link>.
    %
    % Clicking on "properties" link above shows the rest of the
    % properties assigned to PropertyGroupList
    %        CategoryA
    %                  A: <Value of property A>
    %                  B: <Value of property D>
    %                  C: <Value of property C>
    %        CategoryB
    %                  E: <Value of property E>
    %                  F: <Value of property F>
    %
    % Clicking on "functions" shows the public non-hidden methods of the
    % CustomInterface
    % NOTE - The first set of properties of PropertyGroupList is the
    % set of properties that always gets displayed on disp.
    %
    % Look at the example folder for more details in:
    % \toolbox\shared\testmeaslib\general\examples\customdisplay

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (Access = protected)
        %% General Properties

        % If false - use the default displayNonScalarObject method of
        % matlab.mixin.CustomDisplay. If true, use the custom display.
        ShowNonScalarPropertiesValue (1, 1) logical = true

        % The timeout value in seconds for displaying the property. If the
        % properties are not displayed within the timeout period, a timeout
        % error is thrown.
        PropertyTimeout = 5

        %% Header Properties

        % The header string that is appended to the class type. e.g. If the
        % function header needs to read ClassA with Properties: HeaderText
        % should be "with Properties:"
        HeaderText (1, 1) string

        % true: displays the class header
        % false: does not display the class header
        ShowHeader (1, 1) logical = true

        %% Properties Display

        % true: displays the default properties
        % false: does not display the default properties
        ShowMainProperties (1, 1) logical = true

        % The properties that need to be grouped into categories. e.g. if
        % CategoryA = ["A", "B", "C"] and CategoryB = ["E", "F"], where
        % "A", "B", "C", "E", and "F" are class properties, these can be
        % passed in as obj.PropertyGroupList = {CategoryA, CategoryB}.
        % PropertyGroupList can also be a cell array of strings like {["A",
        % "B", "C"], ["E" ,"F"]}.
        %
        % NOTE: Number of categories and length of PropertyGroupNames must match.
        % The first category (CategoryA) is the default set of properties
        % that is always displayed on "disp" of an object.
        PropertyGroupList (1, :) cell

        % The category/group names for the property categories - e.g.
        % obj.PropertyGroupNames = ["CategoryA", "CategoryB"];
        PropertyGroupNames (1, :) string

        % true: displays a warning when some properties could not be
        % displayed
        % false: does not display the warning
        ShowPropertyWarning (1, 1) logical = true

        %% Footer Properties

        % true: displays the class footer
        % false: does not display the class footer
        ShowFooter (1, 1) logical = true

        % true: displays the "properties" link in the class footer false:
        % does not display the "properties" link in the class footer
        ShowAllPropertiesInFooter (1, 1) logical = true

        % true: displays the "functions" link in the class footer false: does
        % not display the "functions" link in the class footer
        ShowAllMethodsInFooter (1, 1) logical = true

        %% Custom Display Properties

        % Clicking on these property links in the footer displays the set
        % of custom properties associated with that link.
        CustomProperties (1, :) matlabshared.testmeas.CustomProperties

        %% Custom Display Methods

        % Clicking on custom links in the footer executes the
        % user-specified function.
        CustomLinks (1, :) matlabshared.testmeas.CustomLinks

        %Toggle the use of get() instead of dot indexing:
        %true  --> uses get() function to retrieve values
        %false --> uses dot indexing to retrieve values
        UseGetForPropertyValue (1, 1) logical = false

        %Toggle the use of the corresponding error message when there is a
        %failure retrieving a property value.
        %true  --> sets error message as property's value in the display
        %false --> throws normal error resulting from retrieval failure
        GetErrorMessageAsValue (1, 1) logical = false
    end

    properties(Access = protected)
        % The workspace variable name for the customer facing object
        % created.
        % Look at the example folder for more details in:
        % \toolbox\shared\testmeaslib\general\examples\customdisplay
        WorkspaceVariableName (1, 1) string
    end

    properties (Access = {?matlabshared.testmeas.internal.interface.ITestable})
        % The class type for the customer-facing interface.
        ClassType (1, 1) string
    end

    properties(Access = private, Constant)
        % The text that begins a new line in the footer.
        BeginningText = blanks(2) + message("testmeaslib:CustomDisplay:BeginningText").string + blanks(1)

        % The delimeter (or "delimiting text") that separates each
        % consecutive footer element
        FooterSeparator = ", "
        
        % "all" substring for the footer text - Show "all" properties,
        % functions
        AllText = message("testmeaslib:CustomDisplay:AllText").string + blanks(1)
    end

    %% Use when a CustomDisplay class (say, ClassTop) must display another CustomDisplay class (say, ClassBot) as one of its properties.
    % Look at the example folder for more details in:
    % \toolbox\shared\testmeaslib\general\examples\customdisplay
    properties(Access = protected)
        % Set the ParentPropertyName in ClassBot to "ClassBot", so that
        % custom footers work when displaying the contents of ClassBot from
        % ClassTop.
        ParentPropertyName (1, 1) string
    end

    methods (Hidden)
        function ws = getWorkspaceVariableHook(obj)
            % Override this method in ClassBot to return the
            % WorkspaceVariableName of ClassTop.
            ws = obj.WorkspaceVariableName;
        end
    end

    %% API
    methods (Access = protected)
        function displayScalarObject(obj)
            % Displays the class object and its properties.

            try
                % Get the header for the class object and display it
                obj.ClassType = class(obj);
                if obj.ShowHeader
                    obj.displayHeader();
                end

                % Display the Selected important Properties for class
                % object
                if obj.ShowMainProperties
                    obj.displayMainProperties();
                end

                if obj.ShowFooter
                    % Prepare and display the footer.

                    % Get the WorkspaceVariableName from the MATLAB
                    % workspace
                    obj.WorkspaceVariableName = inputname(1);

                    % If not able to get the WorkspaceVariableName, i.e.
                    % for ClassTop and ClassBottom cases (see
                    % getWorkspaceVariableHook function section)
                    if obj.WorkspaceVariableName == ""
                        obj.WorkspaceVariableName = obj.getWorkspaceVariableHook();
                    end

                    % Display the footer
                    disp(obj.getFooter);
                end
            catch ex
                throwAsCaller(ex);
            end
        end

        function displayNonScalarObject(obj)
                % Displays the class object and its properties for an array
                % of class objects

                firstValidObjIndex = 0;

                % Find the first valid object in the array
                for i = 1:numel(obj)
                    try
                        % This line is just to trigger an error for invalid
                        % objects
                        obj(i).ShowNonScalarPropertiesValue;
                        firstValidObjIndex = i;
                        break
                    catch
                        % Continue searching if an invalid object is
                        % encountered
                    end
                end

                if firstValidObjIndex == 0
                    exceptionMsg = message("testmeaslib:CustomDisplay:VectorDeletedObj", numel(obj), "object");
                    disp(exceptionMsg.string());
                    return
                end

                % The ShowNonScalarProperties value of the first element of
                % the array determines how the array is displayed. If false
                % then display the default displayNonScalarObject of
                % matlab.mixin.CustomDisplay, or the new custom display for
                % non-scalar objects.
                if ~obj(firstValidObjIndex).ShowNonScalarPropertiesValue
                    displayNonScalarObject@matlab.mixin.CustomDisplay(obj);
                    return
                end

                % Show the array header
                header = getHeader(obj);
                disp(header);

                % Display the header and properties of individual array
                % elements.
                for i = 1 : numel(obj)
                    try
                        if obj(i).ShowHeader
                            displayHeader(obj(i), true);
                        end
                        if obj(i).ShowMainProperties
                            displayMainProperties(obj(i));
                        end
                    catch ex
                        exceptionMsg = message("testmeaslib:CustomDisplay:DeletedObj", "object");
                        disp(exceptionMsg.string());
                    end
                end
            end

        function out = getFooter(obj)
            % Returns the class footer. This shows the "Show all
            % properties" for the class object.

            if ~isscalar(obj)
                out = getFooter@matlab.mixin.CustomDisplay(obj);
                return
            end
            out = getFooterText(obj);
        end
    end

    %% Additional hook methods that can be accessed by the implementing interface
    methods (Access = protected)
        function value = propertyDisplayHook(obj, propertyName)
            % Returns the value of a class property.

            if obj.UseGetForPropertyValue
                propText = "get(obj, """ + propertyName +""")";
            else
                propText = "obj." + propertyName;
            end
            value = eval(propText);
        end

        function executionText = customFooterForCustomPropertiesHook(obj, funcName, linkName, index)
            % Returns the text that executes on clicking custom property
            % links. This executionText is later wrapped in an href tag.

            workspaceName = getWorkspaceNameOfFooterObject(obj);
            executionText = """matlab:if exist('" + obj.WorkspaceVariableName + "','var')&&isa(" + workspaceName + ", '" ...
                + obj.ClassType + "'), obj = " + workspaceName +  "; " + funcName +"(obj, " + string(index)+ "); clear obj; " + ...
                "else, error(message('testmeaslib:CustomDisplay:InvalidObject', '" + linkName +"')); end""";
        end

        function executionTask = customFooterHook(obj, funcName, linkName)
            % Returns the text that executes on clicking on "properties",
            % "functions", or custom method links. This executionText is
            % later wrapped in an href tag.

            workspaceName = getWorkspaceNameOfFooterObject(obj);
            executionTask = """matlab:if exist('" + obj.WorkspaceVariableName + "','var')&&isa(" + workspaceName + ", '" ...
                + obj.ClassType + "'), obj = " + workspaceName +  "; " + funcName +"(obj); clear obj; " + ...
                "else, error(message('testmeaslib:CustomDisplay:InvalidObject', '" + linkName +"')); end""";
        end
    end

    %% Helper methods
    methods (Access = {?matlabshared.testmeas.internal.interface.ITestable})
        function displayMainProperties(obj)
            % Displays the first set of properties passed to
            % PropertyGroupList, or shows all public non-hidden properties
            % if PropertyGroupList is not defined.

            if ~isempty(obj.PropertyGroupList)
                group = createPropertyGroups(obj, obj.PropertyGroupList{1}, obj.PropertyGroupNames(1));
                matlab.mixin.CustomDisplay.displayPropertyGroups(obj, group);
            else
                allProps = {string(properties(obj))'};
                group = createPropertyGroups(obj, allProps{1}, "");
                matlab.mixin.CustomDisplay.displayPropertyGroups(obj, group);
            end
        end

        function val = getWorkspaceNameOfFooterObject(obj)
            % Return the name of the object in the workspace, be it the
            % WorkspaceVariableName, or
            % WorkspaceVariableName.ParentPropertyName
            if obj.ParentPropertyName == ""
                val = obj.WorkspaceVariableName;
            else
                val = obj.WorkspaceVariableName + "." + obj.ParentPropertyName;

                % Do not use the ParentPropertyName for the lower level
                % class(ClassBot) that exists in the MATLAB workspace. Use the
                % object's WorkspaceVariableName instead. (see
                % getWorkspaceVariableHook function section)
                if ~ismember('obj',evalin('base','who')) && ~exist(val, 'var')
                    val = obj.WorkspaceVariableName;
                end
            end
        end

        function footerText = getFooterText(obj)
            % Creates and returns the footer string.

            footerText = "";

            % "properties" link
            if obj.ShowAllPropertiesInFooter
                footerText = obj.BeginningText + obj.AllText;
                if ~feature('hotlinks')
                    footerText = footerText + "properties";
                else
                    % "all properties" below is used in the message catalog
                    footerText = footerText + "<a href=" + customFooterHook(obj, ...
                        "displayAllProperties", message("testmeaslib:CustomDisplay:AllProperties").string ...
                        ) + ">" + "properties" + "</a>";
                end
            end

            % "functions" link
            if obj.ShowAllMethodsInFooter
                if footerText ~= ""
                    footerText = footerText + obj.FooterSeparator;
                else
                    footerText = obj.BeginningText + obj.AllText;
                end

                if ~feature('hotlinks')
                    footerText = footerText + "functions";
                else
                    % "all functions" below is used in the message catalog
                    footerText = footerText + "<a href=" + customFooterHook(obj, ...
                        "methods", message("testmeaslib:CustomDisplay:AllFunctions").string ...
                        ) + ">" + "functions" + "</a>";
                end
            end

            % Prepare for "Custom Properties"
            if ~isempty(obj.CustomProperties)
                footerText = removeEndComma(obj, getCustomEntityLinks(obj, footerText, "property"));
            end

            % Prepare for "Custom Links"
            if ~isempty(obj.CustomLinks)
                footerText = removeEndComma(obj, getCustomEntityLinks(obj, footerText, "link"));
            end

            % Return the final footer.
            if footerText ~= ""
               footerText = footerText + newline;
            end
        end

        function displayHeader(obj, varargin)
            % Display the header for each scalar object. This method allows
            % an additional logical parameter that adds an extra space to
            % the class header. This is needed to correctly format the
            % class header.

            narginchk(1, 2);
            extraSpace = false;
            if nargin == 2
                validateattributes(varargin{1}, {'logical'}, {'nonempty'}, mfilename);
                extraSpace = varargin{1};
            end

            if extraSpace
                header = " ";
            else
                header = "";
            end

            % No HeaderText was provided, use the one created by
            % matlab.mixin.CustomDisplay. Else, use the class link for the
            % name and append the text specified in HeaderText.
            if obj.HeaderText == ""
                header = header + string(getHeader(obj));
            else
                header = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                header = "  " + string(header) + " " + obj.HeaderText + newline;
            end
            disp(header);
        end

        function customText = removeEndComma(obj, customText)
            % Remove the ", " when a property or link is to be displayed on
            % a newline.

            if customText == "" || customText == obj.BeginningText
                return
            end
            customText = extractBefore(customText, strlength(customText)-1);
        end

        function customText = createNewLine(obj, customText)
            % Create a new line display for Custom properties or custom
            % links. The new line always begins with "Show "

            if customText == obj.BeginningText
                return
            end
            if customText ~= "" && endsWith(customText, ", ")
                customText = removeEndComma(obj, customText);
            end

            customText = customText + newline + obj.BeginningText;
        end

        function footerText = getCustomEntityLinks(obj, footerText, entity)
            % Create, append, and return the custom footer text for custom
            % links and custom properties

            % Set the type based on whether displaying CustomProperties or
            % CustomLinks
            switch entity
                case "property"
                    type = obj.CustomProperties;
                case "link"
                    type = obj.CustomLinks;
                otherwise
                    throwAsCaller(...
                        MException(message("testmeaslib:CustomDisplay:InvalidEntity", """property"", ""link""")));
            end

            % Add "Show " if "properties" and "functions" texts are
            % not displayed
            if footerText == ""
                footerText = obj.BeginningText;
            else
                % Append a ", " to the "properties" and/or "functions"
                % text.
                footerText = footerText + obj.FooterSeparator;
            end
            % Loop over the "type" and keep updating the footer text.
            for i = 1 : length(type)
                val = type(i);

                % If the custom property or link is to be displayed on a
                % new line, remove ", " from the previous line and create a
                % new line with "Show ".
                if val.NewLine
                    if i == 1
                        % Remove ", " from the previous line for the first
                        % element.
                        footerText = obj.removeEndComma(footerText);
                    end
                    footerText = createNewLine(obj, footerText);
                end

                % If not using hotlinks, only display the name of the
                % Custom link or property, without an actual hyperlink.
                if ~feature('hotlinks')
                    footerText = footerText + val.LinkText + obj.FooterSeparator;
                    continue
                end

                % For hotlinks
                switch entity
                    case "property"
                        entityLinkCode = customFooterForCustomPropertiesHook(obj, ...
                            "displayCustomProperties", val.LinkText, i);
                    case "link"
                        entityLinkCode = customFooterHook(obj, ...
                            val.MethodName, val.LinkText);
                end

                % Update the footer with the custom entity.
                footerText = footerText + "<a href=" + entityLinkCode +">" ...
                    + val.LinkText + "</a>" + obj.FooterSeparator;
            end
        end
    end

    methods (Hidden)
        function displayAllProperties(obj)
            % Displays all the class properties using
            % matlab.mixin.CustomDisplay, when the "properties"
            % hyperlink is clicked.

            try
                allGroups = obj.PropertyGroupNames;
                if isempty(allGroups)
                    obj.PropertyGroupList = {string(properties(obj))};
                    allGroups = "";
                end
                for i = 1 : length(allGroups)
                    group(i) = createPropertyGroups(obj, obj.PropertyGroupList{i}, allGroups(i)); %#ok<*AGROW>
                end
                matlab.mixin.CustomDisplay.displayPropertyGroups(obj, group);
            catch ex
                throwAsCaller(ex);
            end
        end

        function displayCustomProperties(obj, index)
            % Displays all the class CustomProperties in a sequence using
            % matlab.mixin.CustomDisplay.
            try
                allGroups = obj.CustomProperties(index).GroupName;
                for i = 1 : length(allGroups)
                    group(i) = createPropertyGroups(obj, obj.CustomProperties(index).PropertyList{i}, allGroups(i)); %#ok<*AGROW>
                end
                matlab.mixin.CustomDisplay.displayPropertyGroups(obj, group);
            catch ex
                throwAsCaller(ex);
            end
        end

        function group = createPropertyGroups(obj, propertyList, groupName)
            % Creates the class properties group
            if ~isscalar(obj)
                group = getPropertyGroups(obj);
                return
            end
            plist1 = struct;
            tic
            for i = 1 : length(propertyList)
                if toc > obj.PropertyTimeout
                    continue
                end
                try
                    value = propertyDisplayHook(obj, propertyList{i});
                catch ex
                    if obj.GetErrorMessageAsValue
                        value = replace(string(ex.message), newline, " ");
                    else
                        continue
                    end
                end
                plist1.(propertyList{i}) = value;
            end

            % Failure to read property - either error for timeout occurring,
            % or some error in reading the property from object.
            if ~isempty(propertyList) && isempty(fields(plist1))
                if  toc > obj.PropertyTimeout
                    mExcep = MException(message("testmeaslib:CustomDisplay:PropertyTimeout"));
                    throwAsCaller(mExcep);
                else
                    try
                        mExcep = MException(message("testmeaslib:CustomDisplay:PropertyError"));
                        throwAsCaller(mExcep);
                    catch e
                        throwAsCaller(e);
                    end
                end
            end

            % For some properties that could not be displayed, show a
            % warning.
            if obj.ShowPropertyWarning && numel(propertyList) > numel(fields(plist1))
                warning('backtrace', 'off');
                oncleanup = onCleanup(@() warning('backtrace', 'on'));
                propsNotDisplayed = setdiff(propertyList, string(fields(plist1))');
                warning(message(...
                    "testmeaslib:CustomDisplay:PropertyWarning", ...
                    matlabshared.testmeas.displayutils.renderArrayOfStringsToString(propsNotDisplayed)));
            end
            group = matlab.mixin.util.PropertyGroup(plist1, groupName);
        end
    end
end

% LocalWords:  customdisplay delimeter
