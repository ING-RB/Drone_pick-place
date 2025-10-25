classdef ReporterBase< mlreportgen.report.ReportForm & matlab.mixin.Copyable
%mlreportgen.report.ReportBase   Base class for reporters
%   
%   ReporterBase properties:
%     TemplateSrc     - Source of this reporter's template
%     TemplateName    - Template name in source template library
%     LinkTarget      - Hyperlink target for this reporter
%
%   ReporterBase methods:
%     getImpl          - Get DOM implementation for this reporter
%     parseTranslation - Parse XML title prefix/suffix translation map
%                        (static)
%     getTranslation   - Get title prefix/suffix translations (static)

     
    %   Copyright 2017-2024 The MathWorks, Inc.

    methods
        function out=ReporterBase
        end

        function out=getImpl(~) %#ok<STOUT>
            %getImpl Get DOM implementation of this reporter
            %   impl = getImpl(reporter, rpt) returns the DOM object
            %   used to implement this reporter. The DOM object is
            %   usually an object of mlreportgen.dom.DocumentPart type.
            %   Examining the implementation object may help with
            %   debugging report generation problems.
        end

        function out=getTranslation(~) %#ok<STOUT>
            %getTranslation Get translation of a title number prefix/suffix
            %   translation = getTranslation(translations, locale) returns
            %   locale-specific translations of a title number prefix and
            %   suffix. The translations input argument is a containers.Map
            %   object that maps locales to prefix/suffix translations.
            %   The locale argument is a string or character array that
            %   specifies a locale id, for example, 'en' for English.
        end

        function out=parseTranslation(~) %#ok<STOUT>
            %parseTranslation Parse title number prefix/suffix XML map
            %   translations = parseTranslation(classFolder, filename) is a
            %   static method that returns a map of locales to translations
            %   of title number prefixes and suffixes. The translations are
            %   parsed from an XML representation of the map stored in the
            %   resources directory of a reporter class. The classFolder
            %   argument specifies the path of the folder containing the
            %   reporter class definition. The filename argument specifies
            %   the XML file containing the translation map. The output
            %   argument is a containers.Map object that maps locale keys
            %   to structures containing the prefix and suffix
            %   translations.
            %
            %   Note: see the class definition directory for a subclass of
            %   the Chapter reporter for an example of an XML translation
            %   map.   
            %
            %   See also mlreportgen.report.Reporter.getClassFolder,
            %   mlreportgen.report.Chapter.customizeReporter
        end

    end
    properties
        % Property used by copyElement method. If this reporter is being
        % copied, this property is set to the handle of the copy. Once the
        % reporter is done being copied, this property is set back to
        % empty.
        CopyPtr;

        % LinkTarget Hyperlink target for content created by this reporter
        %   Specifies a hyperlink target for this reporter. The value of
        %   this property may be a character array or string that
        %   specifies the link target ID or an mlreportgen.dom.LinkTarget
        %   object. A string or character array value is converted to
        %   a LinkTarget object. In either case, the link target object
        %   immediately precedes this reporter's content in the output
        %   report.
        %
        %   See also mlreportgen.report.LinkTarget
        LinkTarget;

        %TemplateName Name of this reporter's template
        %   Specifies the name of this reporter's template in the template
        %   library of this reporter's template source.
        %
        %   See also mlreporten.report.Reporter.TemplateSrc
        TemplateName;

        %TemplateSrc Source of this reporter's template
        %   The value of this property may be
        %
        %       - Path of a file containing this reporter's template
        %       - A reporter or report whose template is to be used as this
        %         reporter's template or whose template library contains
        %         this reporter's template.
        %       - A DOM document or document part whose template is to be
        %         used as the template for this reporter or whose template
        %         library contains the template for this reporter.
        %
        %   The specified template must be of the same type as the
        %   report to which this reporter is to be appended. For example,
        %   this property must specify a Word reporter template for a
        %   Word report. An empty value specifies use of the reporter's
        %   default template for the output type of the report.
        %
        %   See also mlreportgen.report.Reporter.TemplateName,
        %   mlreportgen.report.Report.Type, mlreportgen.dom.Document,
        %   mlreportgen.dom.DocumentPart
        TemplateSrc;

        % Holds the TemplateSrc property value if specified as a
        % DocumentPart or template path.
        TemplateSrcOther;

        % Holds the TemplateSrc property if specified as a reporter or
        % report object. This must be a weak reference to avoid strong
        % reference cycles (g3298493)
        TemplateSrcReportForm;

    end
end
