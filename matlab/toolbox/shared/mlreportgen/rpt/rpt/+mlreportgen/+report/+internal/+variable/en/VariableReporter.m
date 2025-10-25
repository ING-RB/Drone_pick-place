classdef VariableReporter< handle
% VariableReporter is the abstract base class of variable reporters.
% A variable reporter generates content, to describe the variable
% values, based on the specified report options.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=VariableReporter
            % this = VariableReporter(reportOptions, VarName, VarValue)
            % creates a variable reporter object for the specified varName,
            % with specified varValue. The specified reportOptions
            % specifies various variable report options.
        end

        function out=addAnchor(~) %#ok<STOUT>
            % Add an anchor to the specified object. The object can be
            % clone of a DOM Paragraph or a BaseTable reporter template
            % object specified in this reporter's report options. This
            % method is called by either makeParaReport() or
            % makeTabularReport() after cloning the Paragraph or BaseTable
            % template object and to add an anchor to it before adding any
            % content. Adding the anchor enables automatic two-way
            % navigation for hierarchical reporters.
        end

        function out=appendParaTitle(~) %#ok<STOUT>
        end

        function out=getDOMLink(~) %#ok<STOUT>
            % Create a DOM InternalLink for the specified target id and
            % title text.
        end

        function out=getTextValue(~) %#ok<STOUT>
            % Returns the value of the reported variable as string
        end

        function out=getTextualContent(~) %#ok<STOUT>
            % Returns the textual content for the reporter. By default, it
            % returns the variable's text value. The method can be
            % overriden by derived classes to provide their own textual
            % content.
        end

        function out=getTitleText(~) %#ok<STOUT>
            % Returns the title text based on the variable's report
            % options. For hierarchical reporters, i.e., if another
            % reporter contains this reporter, the generated title includes
            % a hyperlink to the container reporter.
        end

        function out=makeAnchor(~) %#ok<STOUT>
            % Creates an anchor, i.e., DOM LinkTarget object for this
            % reporter.
        end

        function out=makeLink(~) %#ok<STOUT>
            % Creates DOM InternalLink with the specified
            % titleText, clicking on which should navigate to the specified
            % linkedReporter's content. This will also update the
            % LinkedTitle property for the linkedReporter so that clicking
            % on it's title navigates back to current reporter's content.
        end

        function out=makeParaReport(~) %#ok<STOUT>
            % domParagraph = makeParaReport(this) reports on the variable as
            % a paragraph. This method returns the content in a clone of
            % DOM Paragraph object, specified as template object in the
            % ReportOptions. The reported content optionally includes a
            % title that optionally includes the variable's data type.
            % These options are also specified by the ReportOptions
            % associated with this reporter.
        end

        function out=makeTextReport(~) %#ok<STOUT>
            % domText = makeTextReport(this) reports on the variable as
            % inline text. This method returns the content in a clone of
            % DOM Text object, specified as template object in the
            % ReportOptions. The reported content optionally includes a
            % title that optionally includes the variable's data type.
            % These options are also specified by the ReportOptions
            % associated with this reporter.
        end

        function out=registerLink(~) %#ok<STOUT>
            % Registers this reporter with the ReporterLinkResolver. The
            % base method does nothing. Objects whose properties can refer
            % to other objects should override this method to avoid
            % duplicate object reports and reference cycles.
        end

        function out=report(~) %#ok<STOUT>
            % content = report(this) reports on the variable. This method
            % reports on the variable as: inline, paragraph, or tabular
            % based on the specified report options.
        end

    end
    methods (Abstract)
        % Report on the variable based on the variable's data type.
        makeAutoReport;

        % Report on the variable in a tabular form. This method returns a
        % clone of the mlreportgen.report.BaseTable object, specified as
        % template object in the ReportOptions, and fills the title with
        % the variable name and table content with the variable values.
        makeTabularReport;

    end
    properties
        % Specifies a boolean value that indicates if the reporter owns a
        % hierarchical object. Default value is false, which derived
        % reporters can override. Based on the value, the hierarchial
        % objects are flattened when reported in tabular form. The
        % hierarchical object's value in the table is displayed as a
        % hyperlink to another table that contains the hierarchical
        % object's properties. The object's properties table will display a
        % hyperlink back to the original table to facilitate navigation
        % between the two tables.
        Hierarchical;

        % Specifies the linked title for hierarchical reporter. The
        % main reporter that contains a hierarchical reporter sets the
        % linked title for the hierarchical reporter, so that clicking on
        % it navigates to the main reporter content.
        LinkedTitle;

        % Specify reporting options for the variable
        ReportOptions;

        % Specifies a unique Id for this reporter. The value is a string
        % consisting of the variable name and a unique number. The number
        % specifies this reporter's count in the reporter queue.
        ReporterID;

        % Specifies this reporter's level/depth in the reporter hierarchy.
        % Default value is 0 which indicates that it is a top-level
        % reporter.
        ReporterLevel;

        TitleWithSuffix;

        % Name of the variable to be reported
        VarName;

        % Value of the variable to be reported
        VarValue;

    end
end
