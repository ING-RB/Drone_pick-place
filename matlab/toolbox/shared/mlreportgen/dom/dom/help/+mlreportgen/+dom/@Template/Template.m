%mlreportgen.dom.Template Create a template for a document
%    templateObj = Template(templatePath, fileType, sourceTemplatePath)
%    creates a template at templatePath having the specified fileType and
%    using the Word, HTML, or PDF template (depending on the type) at the
%    location specified by sourceTemplatePath.
%
%    Valid template types:
%
%      'docx'           - Microsoft Word document
%      'html'           - HTML document
%      'html-file'      - single-file HTML document
%      'html-multipage' - multipage HTML document
%      'pdf'            - PDF document
%
%    templateObj = Template() creates an HTML template named
%    'Untitled.htmtx' in the current directory, using the DOM API's default
%    HTML template.
%
%    templateObj = Template(templatePath) creates an HTML template at the
%    specified location, using the DOM API's default HTML template.
%
%    templateObj = Template(templatePath, fileType) creates a template of
%    the specified fileType at the specified location
%
%    Template properties:
%        TemplateDocumentParts  - Document part templates in this template's glossary
%        Stylesheet             - Stylesheet object containing styles defined by this template
%        Children               - Content of this document
%        CurrentHoleId          - Id of current hole
%        CurrentHoleType        - Type of current hole (inline or block)
%        CurrentPageLayout      - Current page layout
%        ForceOverwrite         - Whether to overwrite existing file
%        HTMLHeadExt            - HTML head element content
%        Id                     - Id of this document
%        OpenStatus             - Open status of this document
%        OutputPath             - Path of document's output directory
%        PackageType            - How to package document output
%        StreamOutput           - Whether to stream this document's output
%        Tag                    - Tag of this document
%        TemplatePath           - Path of this document's template
%        TitleBarText           - Text to put in title bar of HTML output
%        Type                   - Type of document (e.g., docx, html, html-file, html-multipage, pdf)
%
%    Template methods:
%        append            - Append a MATLAB or DOM object to this document
%        addHTML           - Appends an HTML markup string to this document
%        addHTMLFile       - Appends the contents of an HTML file to this document
%        close             - Close this document
%        createTemplate    - Create a template
%        fill              - Fill holes in this document's template
%        getCoreProperties - Get the OPC core properties of this document
%        getImageDirectory - Get a document's image directory
%        getImagePrefix    - Get a document's generated image name prefix
%        getMainPartPath   - Get the full path of this document's main part
%        getOPCMainPart    - Get the main part (file) of a document package
%        moveToNextHole    - Move to next hole in this document
%        open              - Open this document    
%        package           - Add a file to the document's OPC package
%        setCoreProperties - Set the OPC core properties of this document
%
%    Example:
%
%     import mlreportgen.dom.*;
%     t = Template("mytemplate");
%
%     % Company Logo
%     p = Paragraph("My Company");
%     p.FontSize = "24";
%     p.Color = "DeepSkyBlue";
%     p.Bold = true;
%     p.HAlign = "center";
%     append(t, p);
%
%     % Report Title
%     p = Paragraph;
%     p.FontFamilyName = "Arial";
%     p.FontSize = "18pt";
%     p.Bold = true;
%     p.HAlign = "center";
%     append(p, TemplateHole("ReportTitle","Report Title"));
%     append(t,p);
%     close(t);
%     rptview("mytemplate.htmtx");
%
%     See also mlreportgen.dom.TemplateHole,
%     mlreportgen.dom.TemplateDocumentPart, mlreportgen.dom.Document, 
%     mlreportgen.dom.TemplateStylesheet, rptview

%    Copyright 2014-2023 The MathWorks, Inc.
%    Built-in class

%{
properties

    %TemplateDocumentParts Document part templates in this template's glossary
    %     Array of mlreportgen.dom.TemplateDocumentPart objects that
    %     represent the document part templates to be included in the
    %     template. When the Template object is closed, these document part
    %     templates are written to the output template package (HTML,
    %     HTML-MULTIPAGE, PDF, DOCX) or template document (HTML-FILE). If
    %     the template document that this Template object is using contains
    %     any document parts, this property is automatically populated with
    %     TemplateDocumentPart objects that contain DOM representations of
    %     the existing document parts when the template object is opened.
    TemplateDocumentParts;

    %Stylesheet Stylesheet object containing styles defined by this template
    %     Object of type mlreportgen.dom.TemplateStylesheet that represents
    %     the template's stylesheet. The stylesheet contains style
    %     definitions that format report elements such as paragraphs,
    %     lists, and tables. The styles are used by the main template body,
    %     document part templates, or other documents that use the template
    %     generated from this template object. When this Template is opened
    %     using the open method, the stylesheet object is created and
    %     automatically populated with styles that are present in the
    %     source template on which this Template is based. Use the
    %     Stylesheet property to access and modify existing styles and add
    %     new styles. When the Template object is closed, the styles are
    %     written to the output template package (HTML, HTML-MULTIPAGE, 
    %     PDF, DOCX) or template document (HTML-FILE).
    Stylesheet;

end
%}