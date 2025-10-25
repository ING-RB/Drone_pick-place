classdef Reporter< mlreportgen.report.ReporterBase
%mlreportgen.report.Reporter Creates a MATLAB reporter
%   reporter = mlreportgen.report.Reporter() creates an empty reporter.
%
%   reporter = mlreportgen.report.Reporter(p1,v1,p2,v2,...) creates
%   a reporter and sets its properties (p1,p2,...) to the specified
%   values (v1,v2,...).
%   
%   Reporter properties:
%     TemplateSrc     - Source of this reporter's template
%     TemplateName    - Template name in source template library
%     LinkTarget      - Hyperlink target for this reporter
%
%   Reporter methods:
%     getImpl           - Get DOM implementation for this reporter
%     createTemplate    - Copy one of the default Reporter templates
%     customizeReporter - Subclass Reporter for customization
%     getClassFolder    - Get class definition folder

 
    %   Copyright 2017-2020 The MathWorks, Inc.

    methods
        function out=Reporter
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Reporter.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the Reporter
            %    template specified by type at the location specified by
            %    templatePath. You can use this method to create a copy of
            %    the default Reporter template to serve as a starting
            %    point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.Reporter.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of the mlreportgen.report.Reporter
            %    class. You can use this file as a starting point for
            %    defining a custom reporter class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    For example:
            %    mlreportgen.report.Reporter.customizeReporter("+my/@Reporter")
            %    defines a Reporter subclass named my.Reporter.
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.Reporter.getClassFolder()
            %    is a static method that returns the path of the folder
            %    that contains the class definition file.
        end

    end
end
