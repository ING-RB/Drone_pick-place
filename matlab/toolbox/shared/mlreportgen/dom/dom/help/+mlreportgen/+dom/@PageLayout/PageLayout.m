%mlreportgen.dom.PageLayout Page layout properties of a Word or PDF document
%    section = PageLayout() creates an empty page layout. 
%
%    PageLayout methods:
%        
%        getPageBodySize          - Get the current page body size
%        rotate                   - Switch between portrait orientation and
%                                   landscape orientation
%
%    PageLayout properties:
%        
%        Id               - Id of this object
%        PageFooters      - Page footers for this layout
%        PageHeaders      - Page headers for this layout
%        PageMargins      - Margin sizes and page orientation in this layout
%        PageSize         - Size of pages in this layout
%        PageBorder       - Border of pages in this layout
%        Parent           - Parent of this layout
%        RawFormats       - XML markup for unsupported layout formats
%        EndnoteOptions   - Specify endnote formatting options
%        FootnoteOptions  - Specify footnote formatting options
%        Style            - Style of this layout
%        Tag              - Tag of this object
%
%    See also mlreportgen.dom.DOCXPageFooter, mlreportgen.dom.PDFPageFooter, 
%    mlreportgen.dom.DOCXPageHeader, mlreportgen.dom.PDFPageHeader,
%    mlreportgen.dom.PageBorder, mlreportgen.dom.PageMargins,
%    mlreportgen.dom.PageSize

%    Copyright 2015-2024 The MathWorks, Inc.
%    Built-in class

%{
properties
     %PageFooters Array of page footer objects
     %      This property may specify as many as three page footers
     %      for this layout, one for the first page of the layout,
     %      one for even pages, and one for odd pages.
     %
     %      See also mlreportgen.dom.PageFooter
     PageFooters;

     %PageHeaders Array of page header objects
     %      This property may specify as many as three page headers
     %      for this layout, one for the first page of the layout,
     %      one for even pages, and one for odd pages. 
     %
     %      See also mlreportgen.dom.DOCXPageHeader
     PageHeaders;

     %PageMargins Page margins for this layout
     %      The value of this property is a PageMargins object
     %      that allows you to set the size of the margins, gutter,
     %      and header and footer for pages in this layout.
     %
     %      See also mlreportgen.dom.PageMargins
     %      
     PageMargins;

     %PageSize Page size and orientation for this layout
     %      The value of this property is a PageSize object that
     %      allows you to set the height and width and orientation of 
     %      pages in this layout.
     %
     %      See also mlreportgen.dom.PageSize
     %      
     PageSize;
     
     %PageBorder Border of pages for this layout
     %   The value of this property is a PageBorder object that
     %   allows you to set the border of pages in this layout.
     %
     %   See also mlreportgen.dom.PageBorder
     %
     PageBorder;


     %RawFormats XML markup for unsupported layout formats
     %      This property specifies XML markup to be inserted in
     %      the layout properties Word XML element (w:sectPr) for this
     %      layout. It allows you to programmatically specify layout 
     %      properties that are not specified in the document template 
     %      and are not yet supported directly by the DOM API.
     %
     %      Example:
     %
     %      % Turn on line numbering for a document based on the default
     %      % DOM template.
     %      import mlreportgen.dom.*;
     %      d = Document('myreport', 'docx');
     %      open(d); 
     %      s = d.CurrentPageLayout;
     %      % Note that s.RawFormats is initialized with the markup
     %      % for properties specified by the default template. Thus,
     %      % we must append the line numbering property to these
     %      % existing properties.
     %      s.RawFormats = [s.RawFormats ...
     %      {'<w:lnNumType w:countBy="1" w:start="1" w:restart="newSection"/>'}];
     %      append(d, 'This document has line numbers');
     %      close(d);
     %      rptview('myreport', 'docx');  
     %      
     %      For more information on the w:sectPr element, see
     %      http://officeopenxml.com/WPsection.php.
     %
     %      See also mlreportgen.dom.PageRawFormat
     RawFormats;

    %EndnoteOptions Specifies the formatting options of endnotes
    %       An mlreportgen.dom.EndnoteOptions object that specifies endnote options. 
    %       Set the properties of this object to specify endnote options. 
    %       The specified options override the endnote options specified by 
    %       the document to which this page layout belongs.
    %       If any property of EndnoteOptions specified in PageLayout is
    %       empty, the same corresponding property of EndnoteOptions
    %       specified in Document is used.
    %
    %       See also mlreportgen.dom.EndnoteOptions, mlreportgen.dom.Document.EndnoteOptions
    EndnoteOptions;

    %FootnoteOptions Specifies the formatting options of footnotes
    %       An mlreportgen.dom.FootnoteOptions object that specifies footnote options. 
    %       Set the properties of this object to specify footnote options. 
    %       The specified options override the footnote options specified by 
    %       the document to which this page layout belongs.
    %       If any property of FootnoteOptions specified in PageLayout is
    %       empty, the same corresponding property of FootnoteOptions
    %       specified in Document is used.
    %
    %       See also mlreportgen.dom.FootnoteOptions, mlreportgen.dom.Document.FootnoteOptions
    FootnoteOptions;
end
%}
