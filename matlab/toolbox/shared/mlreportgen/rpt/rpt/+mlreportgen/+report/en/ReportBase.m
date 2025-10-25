classdef ReportBase< mlreportgen.report.ReportForm
%REPORTBASE   Base class for objects that contain report content.
%
%   ReportBase properties
%     Locale       - Locale for which the report is to be generated
%     PackageType  - How to package document output

     
    %   Copyright 2017-2024 The MathWorks, Inc.

    methods
        function out=ReportBase
        end

        function out=add(~) %#ok<STOUT>
            %add Add content to a Report object.
            %    This method is an alias for the append method. It
            %    performs the same function as the append method.
            %    You can use either method to append content to
            %    Report objects.
            %
            %    Note: You must use append method to add content to DOM API
            %    objects, such as mlreportgen.dom.Paragraph. The add method
            %    of the Report API accepts any MATLAB object. If the object
            %    is not a type that can be formatted, the add method
            %    converts it to a text string containing the object's class
            %    name, e.g., rptgen.crg_comment. This behavior allows a
            %    client to include any MATLAB object in a report if only as
            %    the name of its class.
            %
            %    See also mlreportgen.report.Report.append
        end

        function out=append(~) %#ok<STOUT>
            %append add content to the report.
            %    append(rpt, content) adds the specified content to rpt. The
            %    content can be Report API reporters and any object that can
            %    be added to a DOM document, including DOM objects and many
            %    builtin MATLAB objects (strings, character arrays, cell
            %    arrays, etc. The append method opens the report if it is not
            %    already open.
            % 
            %    Note: The append method of the Report API accepts any MATLAB
            %    object. If the object is not a type that can be formatted, the
            %    append method converts it to a text string containing the
            %    object's class name, e.g., rptgen.crg_comment. This behavior
            %    allows a client to include any MATLAB object in a report if
            %    only as the name of its class.
            %
            %    Example
            %
            %    import mlreportgen.report.*
            %    import mlreportgen.dom.*;
            %    rpt = Report('Magic Square Magic');
            %    append(rpt, TitlePage('Title', 'Magic Square Magic', 'Subtitle', ...
            %        'Inverting a Magic Square'));
            %    append(rpt, TableOfContents);
            %    ch = Chapter('Magic Moments');
            %    m = magic(5);
            %    append(ch, BaseTable('Title', 'm = magic(5)', 'Content', m));
            %    mInverse = m^-1;
            %    append(ch, BaseTable('Title', 'mInverse = magic(5)^-1', 'Content', ...
            %        cellfun(@(x) sprintf('%0.3f', x), num2cell(mInverse), ...
            %        'UniformOutput', false)));
            %    append(ch, BaseTable('Title', 'm*mInverse', 'Content', ...
            %        cellfun(@(x) sprintf('%0.3f', x), num2cell(m*mInverse), ...
            %        'UniformOutput', false)));
            %    append(ch, Paragraph(sprintf('sum(m(1,:)) - sum(m(:,1)) = %d', ...
            %        sum(m(1,:)) - sum(m(:,1)))));
            %    append(ch, Paragraph(sprintf('sum(mInverse(1,:)) - sum(mInverse(:,1)) = %0.3f', ...
            %        sum(mInverse(1,:)) - sum(mInverse(:,1)))));
            %    append(rpt, ch);
            %    close(rpt);
            %    rptview(rpt);
            %
            %   See also mlreportgen.report, mlreportgen.dom
        end

        function out=close(~) %#ok<STOUT>
            % close Close the report
            %    close(rpt) closes the report and generates its content as
            %    a file of the type specified by the report's Type property
            %    at the location specified by the report's OutputPath 
            %    property.
            %
            %    See also mlreportgen.report.Report.Type, 
            %    mlreportgen.report.Report.OutputPath
        end

        function out=createTemplate(~) %#ok<STOUT>
            % mlreportgen.report.Report.createTemplate(templatePath, type)
            %    Static method to create a custom template with name specified by the
            %    templatePath and output type.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=fill(~) %#ok<STOUT>
            % fill Fill holes in this report's template.
            %   fill(rpt) fills each hole in this report's template with
            %   the value of a property of this report that has the same
            %   name as the hole. This method assumes that rpt is a
            %   subclass of mlreportgen.report.Report that defines the
            %   holes and the properties needed to fill them.
        end

        function out=generateFileName(~) %#ok<STOUT>
            % GenerateFileName Generate a temporary file name
            %   fname = generateFileName(report) returns a path string
            %   suitable to be used as the path of a file in the report's
            %   temporary directory.
            %
            %   fname = generateFileName(report, ext) returns a path
            %   string with the specified extension.
            %
            %   See also mlreportgen.report.Report.getTempPath
        end

        function out=getContext(~) %#ok<STOUT>
            %getContext Get a report context value
            %   value = getContext(rpt, key) gets the report context
            %   value specified by key. You can use this method to 
            %   retrieve report context information that you have set
            %   previously.
            %
            %   See also mlreportgen.report.Report.Context, 
            %   mlreportgen.report.Report.setContext
        end

        function out=getPageBodySize(~) %#ok<STOUT>
            % get the available page body height and page body width in the page layout
        end

        function out=getReportLayout(~) %#ok<STOUT>
            %getReportLayout Returns current report layout
            %   plo = getReportLayout(rpt) returns a report's
            %   current page layout. The returned value depends on the
            %   report type:
            %
            %   Report Type  Returned Value
            %
            %   pdf          mlreportgen.dom.PDFPageLayout
            %   docx         mlreportgen.dom.DOCXPageLayout
            %   HTML         []
            %
            %   If this method is invoked while a section or chapter is
            %   being added to a report, this method returns the current
            %   page layout of the section or chapter. For example, if
            %   a chapter's content includes a reporter that invokes this
            %   method, this method returns the chapter's page layout at
            %   the time that the invoking reporter is being added to 
            %   the chapter's Content hole. This ensures that the 
            %   invoking reporter obtains the correct page layout for
            %   a chapter or section whose layout differs from the 
            %   report layout just before the chapter or section is added
            %   to the report. Note that the chapter or section is not
            %   added to a report until all of its content has been added
            %   to its content hole.
            %
            %   If this method is invoked in any other context, it returns
            %   the page layout most recently added to the report.
        end

        function out=getTempPath(~) %#ok<STOUT>
            % GetTempPath Get path of report temporary directory
            %   path = getTempPath(rpt) returns the path of the directory
            %   used to store temporary files needed to generate the
            %   report. By default the report temporary directory is a
            %   subset of your temporary directory. In debug mode, the
            %   report temporary directory is a subdirectory of the report
            %   directory.
            %
            %   See also mlreportgen.report.Report.Debug
        end

        function out=isdocx(~) %#ok<STOUT>
            %isdocx Determine whether this report is a Word report
            %   tf = isdocx(rpt) returns true if this report is a Word
            %   report.
            %   
            %   See also mlreportgen.report.Report.Type
        end

        function out=ishtml(~) %#ok<STOUT>
            %ishtml Determine whether report is a multifile HTML report
            %   tf = ishtml(rpt) returns true if this report is a
            %   multifile HTML report.
            %   
            %   See also mlreportgen.report.Report.Type
        end

        function out=ishtmlfile(~) %#ok<STOUT>
            %ishtml Determine whether report is a single file HTML report
            %   tf = ishtml(rpt) returns true if this report is a
            %   multifile HTML report.
            %   
            %   See also mlreportgen.report.Report.Type
        end

        function out=ispdf(~) %#ok<STOUT>
            %ispdf Determine whether this report is a PDF report
            %   tf = ispdf(rpt) returns true if this report is a PDF
            %   report.
            %   
            %   See also mlreportgen.report.Report.Type
        end

        function out=mustBeCloseable(~) %#ok<STOUT>
            % mustBeCloseable Validate the report's close status
            %    mustBeCloseable(rpt) throws an error if the report is not
            %    ready to close.
        end

        function out=mustBeOpenable(~) %#ok<STOUT>
            % mustBeOpenable Validate the report's open status
            %    mustBeOpenable(rpt) throws an error if the report is not
            %    ready to open.
        end

        function out=mustBeUnopenedToUpdate(~) %#ok<STOUT>
        end

        function out=open(~) %#ok<STOUT>
            % Open  Open a report
            %   open(rpt) opens the report. Invoking this method on an
            %   already open report or on a closed report causes an error.
            %   The report's add method opens the report if it is not
            %   already open. For this reason, you generally need to
            %   invoke this method directly only in the open method of a
            %   custom report class that defines its own open method.
            %   
            %   See also mlreportgen.report.Report.add,
            %   mlreportgen.report.Report.Document,
            %   mlreportgen.report.Report.Layout
        end

        function out=processHole(~) %#ok<STOUT>
            % hash caracter indicate a new section
        end

        function out=releaseResources(~) %#ok<STOUT>
        end

        function out=removeContext(~) %#ok<STOUT>
            %removeContext Remove item from context
            %   removeContext(rpt,key) removes the specified key from
            %   the context along with its value.
        end

        function out=rptview(~) %#ok<STOUT>
            % rptview(rpt) opens this report in a viewer.
        end

        function out=setContext(~) %#ok<STOUT>
            %setContext Sets a report context value
            %   setContext(rpt, key, value) stores the value specified
            %   by key on the report object. You can subsequently use
            %   the report's getContext method to retrieve the value.
            %
            %   See also mlreportgen.report.Report.Context, 
            %   mlreportgen.report.Report.setContext
        end

    end
    properties
        % Report Context info needed to generate this report (read-only)
        %   The value of this property is a containers.Map object
        %   that contains information needed to generate this report,
        %   such as the hierarchical level of the current report section.
        %
        %   See also containers.Map
        Context;

        % Debug Whether this report is in debug mode
        %   A true value indicates that this report is in debug mode. In
        %   debug mode, the report's temporary files are stored in a 
        %   subdirectory of the report directory and are not deleted when
        %   the report is closed.
        %
        %   See also mlreportgen.report.Report.getTempPath
        Debug;

        % Document DOM document that implements this report (read-only)
        %   The value of this property is an mlreportgen.dom.Document used
        %   to generate the content of this report.
        %
        %   See also mlreportgen.dom.Document
        Document;

        % Layout Page layout of this report
        %    This property allows you to specify key page layout properties
        %    of this report. The layout properties of the TitlePage,
        %    TableOfContents, and Chapter reporters can override the page
        %    layout properties specified by this property.
        %
        %    Note: This property applies only to Microsoft Word and PDF
        %    reports. Also, this property must be set before the document
        %    is opened for output. Setting this property afterwards has no
        %    effect.
        %
        %    Example
        %
        %    Create a landscape report.
        %
        %    import mlreportgen.report.*
        %    rpt = Report("myreport", "pdf");
        %    rpt.Layout.Landscape = true;
        %    open(rpt);
        %    add(rpt, TitlePage("Title", "My Landscape Report"));
        %    add(rpt, TableOfContents);
        %    add(rpt, Chapter("Title", "Tests"));
        %    add(rpt, Chapter("Title", "Unit Tests"));
        %    close(rpt);
        %    rptview(rpt);
        %
        %    See also mlreportgen.report.ReportLayout, 
        %    mlreportgen.report.TitlePage.Layout,
        %    mlreportgen.report.TableOfContents.Layout,
        %    mlreportgen.report.Chapter.Layout
        Layout;

        % Locale Locale (language) of this report
        %    The value of this property may be a string or character array
        %    that specifies the ISO_639-1 two-letter language code (e.g.,
        %    en) of the locale for which this report is to be generated.
        %    See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes for
        %    a list of two-letter codes. [] specifies the language of the
        %    system locale, for example, English on an English system.
        %    
        %    The Report API uses the language code to translate chapter
        %    title prefixes to the language of the specified locale.
        %    Translations are provided for the following locales af, ca,
        %    cs, da, de, el, en, es, et, eu, fi, fr, hu, id, it, ja, ko,
        %    nl, nn, no, pl, pt, ro, ru, sk, sl, sr, sv, tr, uk, xh, zh. If
        %    an unsupported locale is specified, the English version is
        %    used.
        %
        %    Example
        %
        %    The following script translates chapter title prefixes to
        %    Japanese on an English system.
        %
        %    import mlreportgen.report.*
        %    rpt = Report('Japanese Report');
        %    rpt.Locale = 'ja';
        %    house = char(23478); % Kanji character for house
        %    add(rpt, Chapter(house));
        %    close(rpt);
        %    rptview(rpt);
        Locale;

        % OutputPath Path of this report's output document
        %     Specifies the path of a location in the file system where the
        %     report output document should be stored. The path may be a
        %     full path or a path relative to MATLAB's current directory,
        %     for example, 'reportA' or 'C:/myreports/reportA.docx'. A file
        %     extension corresponding to the report's Type property is
        %     appended to the file name if the file name does not already
        %     have an extension corresponding to the Type property.
        %
        %     See also mlreportgen.report.Report.Type
        OutputPath;

        % PackageType Specifies how to package a document's output files
        %
        %      Valid Value     Description
        %      'zipped'        The document output consists of an OPC zip file
        %                      located at the value of the document's
        %                      OutputPath property with the extension docx
        %                      (for Word output) or htmx (for multi-file HTML output).
        %                      For example, if the document type is 'docx'
        %                      and OutputPath is 's:\docs\MyDoc',
        %                      the output is packaged in a zip file named
        %                      's:\docs\MyDoc.docx'.
        %
        %      'unzipped'      The document output is stored in a directory
        %                      having the root file name of the document's
        %                      OutputPath property. For example, if the
        %                      OutputPath is 's:\docs\MyDoc',
        %                      the output directory is 's:\docs\MyDoc'.
        %
        %      'both'          Produces both zipped and unzipped output.
        %
        %      'single-file'   Produces output as a single file. This
        %                      package type is valid for PDF and HTML-File
        %                      output only.
        PackageType;

        % TemplatePath Location of the report's template
        %     This property specifies the path of the template used to
        %     format this report. You can use this property to specify a
        %     custom template for this report.
        %
        %     See also mlreportgen.report.Report.getDefaultTemplatePath,
        %     mlreportgen.report.Report.createTemplate
        TemplatePath;

        TmpDir;

        % Type Output type of this report
        %     Valid values are:
        %     
        %     'HTML'      - Packages an HTML report as a zipped file
        %                   containing the report's HTML file, images,
        %                   style sheet, and JavaScript files.
        %     'HTML-FILE' - HTML report as a single HTML file containing
        %                   the report's text, style sheet, and
        %                   base64-encoded images
        %     'PDF'       - PDF file
        %     'DOCX'      - Microsoft Word document
        %     'PDFA'      - PDF Archival report
        Type;

    end
end
