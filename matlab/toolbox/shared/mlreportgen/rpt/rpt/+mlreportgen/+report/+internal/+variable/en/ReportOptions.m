classdef ReportOptions< handle
% ReportOptions Specifies various variable report options.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=ReportOptions
            % reportOptionsObj = ReportOptions(source) constructs a report
            % options object. The constructor optionally accepts a source
            % object, e.g., a MATLABVariable reporter object that allows a
            % user to specify the report options for the variable. The
            % option property names of the source reporter object must
            % match the option property names of this object.
        end

    end
    properties
        % DepthLimit Number of nested levels to report
        DepthLimit;

        % DisplayPolicy Display style for the variable values
        DisplayPolicy;

        % IncludeTitle Whether to include title
        IncludeTitle;

        % InlineTextReporterTemplate A DOM Text object to be used as a
        % template for reporting the variable as inline text.
        InlineTextReporterTemplate;

        % MaxCols Maximum number of table columns to display
        MaxCols;

        % NumericFormat Format or precision used to display noninteger values
        NumericFormat;

        % ObjectLimit Number of nested objects to report
        ObjectLimit;

        % ParagraphReporterTemplate A DOM Paragraph object to be used as a
        % template for reporting the variable as a paragraph
        ParagraphReporterTemplate;

        % PropertyFilterFcn Function handle or code to filter properties
        PropertyFilterFcn;

        % ShowDataType Whether to show variable's data type in the title
        ShowDataType;

        % ShowDefaultValues Whether to show properties with default values
        ShowDefaultValues;

        % ShowEmptyValues Whether to show properties with empty values
        ShowEmptyValues;

        % TableReporterTemplate A BaseTable reporter object to be used as a
        % template for reporting the variable in a tabular form
        TableReporterTemplate;

        % Title Content used for variable title
        Title;

    end
end
