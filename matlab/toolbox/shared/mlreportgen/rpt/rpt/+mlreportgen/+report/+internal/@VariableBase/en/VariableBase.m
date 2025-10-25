classdef VariableBase< handle
%mlreportgen.report.internal.VariableBase Abstract base class for reporting on MATLAB and Simulink variables

     
    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=VariableBase
        end

        function out=reportVariable(~) %#ok<STOUT>
            % Reports on the specified variable and populate the reported
            % content in the Content property.
        end

    end
    properties
        % DepthLimit Number of nested levels to report
        %    Specifies the maximum number of nesting levels to report on
        %    for a variable value. This is the maximum depth to which the
        %    reporter expands a structured object, a vector of structured
        %    objects, or an array of structured objects. Value of 0
        %    denotes not to expand any structured object. Default value is
        %    10.
        DepthLimit;

        % FormatPolicy Format policy for the variable values
        %    Specifies the format policy for the variable values. The value
        %    of this property can be:
        %
        %       Auto        -  (default) Formats the variable values as a
        %                      table or a paragraph depending on the
        %                      variable data type. The below table
        %                      specifies the list of data types and how
        %                      they are reported using this policy.
        %
        %                      As Table                     As Paragraph
        %                      ---------                    ------------
        %                      Cell array                   Cell vector
        %                      Logical array                Logical scalar
        %                      Numeric array                Logical vector
        %                      MATLAB table                 Numeric scalar
        %                      Simulink object              Numeric vector
        %                      Stateflow object             Character
        %                      Graphics object              Character array
        %                      MATLAB structure             String
        %                      MATLAB structure array       MATLAB structure vector
        %                      MATLAB object                MATLAB object vector
        %                      MATLAB object array          Enumeration(without properties)
        %                      Enumeration(with properties)
        %
        %       Table       -  Formats the variable values in a tabular form.
        %                      If the variable to be reported is a
        %                      hierarchical structured object, for e.g., a
        %                      MATLAB structure, a MATLAB object, a
        %                      Simulink object, a Stateflow object, or a
        %                      Graphics object, where a property of the
        %                      object can itself be another object, the
        %                      hierarchy will be flattened as follows. If
        %                      the value of a property is an object, the
        %                      value will be displayed as a hyperlink to a
        %                      table that contains the object's properties.
        %                      The object's property table will display a
        %                      hyperlink back to the original table to
        %                      facilitate navigation between the two tables.
        %                      A variable that would appear as a paragraph
        %                      by default instead appears as a table entry
        %                      if this policy is selected.
        %
        %       Paragraph   -  Formats the variable values as a paragraph.
        %                      If a variable, by default whose values are
        %                      to be reported as a table, has policy
        %                      changed to Paragraph, the reporter will
        %                      flatten the table to report on the variable
        %                      values as a paragraph.
        %
        %       Inline Text -  Formats variable inline with the surrounding
        %                      text.
        FormatPolicy;

        % IncludeTitle Whether to include title
        %    Includes title containing the variable name and optionally the
        %    variable data type, as specified by the "ShowDataType"
        %    property.
        %    Acceptable values are:
        %
        %       true    -  (default) Include title
        %       false   -  Do not include title
        IncludeTitle;

        % MaxCols Maximum number of table columns to display
        %    Specifies the maximum number of table columns to display. When
        %    reporting on array type variables in tabular form, if the
        %    actual number of columns in the table exceeds the value of
        %    this property, the data is sliced vertically (column wise)
        %    into multiple slices and reported as multiple tables. The
        %    default value for this property is 32.
        MaxCols;

        %NumericFormat Format or precision used to display noninteger values
        %   Format string, specified as a character vector or string
        %   scalar, or number that determines how real (noninteger) values
        %   are displayed. For example, "%.2f" displays double values with
        %   two digits of precision. See the help for sprintf for
        %   information on specifying number formats. If the value of this
        %   property is a number, the number specifies the maximum number
        %   of significant digits to display. For example, 2 is equivalent
        %   to num2str(val, 2) where value is the number to be displayed.
        %   See the help for num2str for more information.
        NumericFormat;

        % ObjectLimit Number of nested objects to report
        %    Specifies the maximum number of nested objects to be reported
        %    for a hierarchical variable. Default value is 200.
        ObjectLimit;

        % ParagraphFormatter MATLAB or model variable paragraph formatter
        %    Specifies a DOM Paragraph to be used to report and format the
        %    variable values as a paragraph. You can customize the
        %    appearance of the content by modifying the properties of the
        %    default paragraph or by replacing it with another Paragraph
        %    object. Any content that you add to the default or replacement
        %    paragraph will appear before the actual variable content in
        %    the generated report.
        ParagraphFormatter;

        %PropertyFilterFcn Function handle or code to filter properties
        %    Function handle or code that allows the user to specify if a
        %    property should be included in the report. If specified as a
        %    function handle, the function should return a logical true if
        %    the given property name should be filtered for the given
        %    variable, and a logical false if the property name for the 
        %    given variable should not be filtered. The function also 
        %    should take three arguments:
        %    
        %       variableName    - Name of variable currently being reported
        %       variableObject  - Variable being reported
        %       propertyName    - Property of variable to be reported
        %
        %    If specified as code in a string or character array, the
        %    code can use the above variables and should set a variable
        %    named 'isFiltered' to either true or false, with the same
        %    meanings as above.
        %
        %    Examples:
        %
        %         % Function handle to filter CoderInfo property
        %         filterFcnHandle = @(variableName, variableObject, propertyName) ...
        %               strcmp(propertyName, 'CoderInfo');
        %         myReporter.PropertyFilterFcn = filterFcnHandle;
        %
        %         % Code string to filter CoderInfo property
        %         filterStr = "isFiltered = strcmp(propertyName, 'CoderInfo');";
        %         myReporter.PropertyFilterFcn = filterStr;
        PropertyFilterFcn;

        % ShowDataType Whether to show variable's data type in the title
        %    Includes data type of the variable in the generated title.
        %    Acceptable values are:
        %
        %       false   -  (default) Do not display variable data type in
        %                  the title
        %       true    -  Display variable data type in title
        ShowDataType;

        % ShowDefaultValues Whether to show properties with default values
        %    Includes variable properties that uses default values in the
        %    generated report. This property applies only to MATLAB object,
        %    Simulink object, and Stateflow object variables. Acceptable
        %    values are:
        %
        %       true    -  (default) Display properties that uses the default value
        %       false   -  Do not display properties that uses the default value
        ShowDefaultValues;

        % ShowEmptyValues Whether to show properties with empty values
        %    Includes variable properties with empty values in the
        %    generated report. This property applies only to MATLAB object,
        %    Simulink object, and Stateflow object variables. Acceptable
        %    values are:
        %
        %       true    -  (default) Display properties that have empty values
        %       false   -  Do not display properties that has empty values
        ShowEmptyValues;

        % TableReporter MATLAB or model variable table reporter
        %    Specifies the reporter to be used by variable reporter
        %    to report on the variable values in a tabular form. The
        %    default value of this property is an object of
        %    mlreportgen.report.BaseTable type. You can customize the
        %    appearance of the table by customizing the default reporter or
        %    by replacing it with a customized version of the BaseTable
        %    reporter. See the BaseTable documentation or command-line help
        %    for information on customizing this reporter. Any content that
        %    you specify in the Title property of the default or the
        %    replacement reporter will appear before the title in the
        %    generated report.
        TableReporter;

        % TextFormatter MATLAB or model variable text formatter
        %    Specifies a DOM Text object to be used to report and format
        %    the variable values as an inline text with the surrounding
        %    text. You can customize the appearance of the content by
        %    modifying the properties of the default text or by replacing
        %    it with another Text object. Any content that you add to the
        %    default or replacement text will appear before the actual
        %    variable content in the generated report.
        TextFormatter;

        % Title Title of variable to report
        %    Specifies the variable title. If this property is empty, the
        %    variable name is used as the title. This property may be
        %    specified as any of the following types:
        %
        %        - MATLAB string scalar
        %        - character array
        %        - DOM Text object
        %        - DOM InternalLink object
        %        - DOM ExternalLink object
        %
        %    If the FormatPolicy is set to "Inline Text":
        %
        %        - If Title is set to a DOM object, the formatting
        %          specified by the DOM object is ignored.
        %        - If Title is set to a DOM InternalLink object or a DOM
        %          ExternalLink object, the link text is used for the 
        %          title, but the title is not a link.
        %        - To format the title, use the TextFormatter property of
        %          this reporter.
        Title;

    end
end
