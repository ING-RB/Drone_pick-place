classdef StructuredObjectReporter< mlreportgen.report.internal.variable.VariableReporter
% StructuredObjectReporter is the base class for reporters that report
% on structure-like objects, e.g., struct, MCOS, or UDD objects.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=StructuredObjectReporter
        end

        function out=getFilteredPropNames(~) %#ok<STOUT>
            % Filters the list of specified properties based on the report
            % options and returns filtered property names to report on.
        end

        function out=getTableHeader(~) %#ok<STOUT>
            % Returns the header row for the table when the variable is
            % reported in a tabular form
        end

        function out=getTextualContent(~) %#ok<STOUT>
            % Override the base class method to return the textual content. 
            % Get textual content by calling the base class method and then
            % normalize the content string. Normalizing the content string
            % is done to remove any unnecessary line breaks in the content
            % after each property in the structured object.
        end

        function out=isFilteredProperty(~) %#ok<STOUT>
            % Returns if the current property needs to be filterted or not.
            % Derived classes can override this method and filter the
            % property based on the report options.
        end

        function out=makeAutoReport(~) %#ok<STOUT>
            % content = makeAutoReport(this) reports on the variable in a
            % tabular form
        end

        function out=makeTabularReport(~) %#ok<STOUT>
            % content = makeTabularReport(this) generates a table that
            % contains entries for the object property name/value pair. If
            % the object does not have any property to be reported, it
            % returns a paragraph with note to notify to the user.
        end

        function out=registerLink(~) %#ok<STOUT>
            % Override base class method to register itself with the
            % ReporterLinkResolver, to make sure that this reporter is
            % always reported once in the report. Any future reference to
            % this reporter will create a hyperlink that navigates to the
            % existing content in the report.
        end

    end
    methods (Abstract)
        % Get the object properties to report on. All the derived reporters
        % should implement this method.
        getObjectProperties;

    end
end
