%mlreportgen.dom.PDFPageLayout Page layout properties of PDF document
%   section = PDFPageLayout() creates an empty page layout.
%
%   PDFPageLayout methods:
%
%       rotate           - Switch between portrait orientation and
%                          landscape orientation
%
%   PDFPageLayout properties:
%
%       Id               - Id of this object
%       PageFooters      - Page footers for this layout
%       PageHeaders      - Page headers for this layout
%       PageMargins      - Margin sizes and page orientation in this layout
%       PageSize         - Size of pages in this layout
%       PageBorder       - Border of pages in this layout
%       FirstPageNumber  - Page number of the first page in this layout
%       PageNumberFormat - Format (arabic, roman, etc.) of page numbers in this layout
%       SectionBreak     - Page on which this layout starts
%       EndnoteOptions   - Specify the formatting options of endnotes
%       FootnoteOptions  - Specify the formatting options of footnotes
%       Parent           - Parent of this layout
%       Style            - Style of this layout
%       Hyphenation      - Hyphenation character (deprecated)
%       Tag              - Tag of this object
%       Watermark        - Watermark for this page layout
%
%   See also mlreportgen.dom.PDFPageFooter,
%   mlreportgen.dom.PDFPageHeader, mlreportgen.dom.PageMargins,
%   mlreportgen.dom.PageSize, mlreportgen.dom.PageBorder,
%   mlreportgen.dom.PageNumber, mlreportgen.dom.Watermark,
%   mlreportgen.dom.FootnoteOptions, mlreportgen.dom.EndnoteOptions

%   Copyright 2015-2023 The MathWorks, Inc.
%   Built-in class

%{
properties

    %PageFooters Array of page footer objects
    %   This property may specify as many as three page footers
    %   for this layout, one for the first page of the layout,
    %   one for even pages, and one for odd pages.
    %
    %   See also mlreportgen.dom.PDFPageFooter
    %
    PageFooters;
    
    %PageHeaders Array of page header objects
    %   This property may specify as many as three page headers
    %   for this layout, one for the first page of the layout,
    %   one for even pages, and one for odd pages.
    %
    %   See aldo mlreportgen.dom.PDFPageHeader
    %
    PageHeaders;
    
    %PageMargins Page margins for this layout
    %   The value of this property is a PageMargins object
    %   that allows you to set the size of the margins, gutter,
    %   and header and footer for pages in this layout.
    %
    %   See also mlreportgen.dom.PageMargins
    %
    PageMargins;
    
    %PageSize Page size and orientation for this layout
    %   The value of this property is a PageSize object that
    %   allows you to set the height and width and orientation of 
    %   pages in this layout.
    %
    %   See also mlreportgen.dom.PageSize
    %
    PageSize;
 
    %FirstPageNumber Page number of the first page in this layout
    %   This property specifies the numeric value of the first
    %   page. When its value is empty, page numbering continues
    %   from previous section.
    %
    %   See also mlreportgen.dom.PageNumber
    %
    FirstPageNumber;
    
    %PageNumberFormat Page number format in this layout
    %   This property specifies the type of characters used to 
    %   represent the page number value.
    %   
    %   VALUE   DESCRIPTION
    %   'a'     Lower case alphabetic (a, b, c, ...)
    %   'A'     Upper case alphabetic (A, B, C, ...)
    %   'i'     Lower case roman numerals (i, ii, iii, ...)
    %   'I'     Uppercase roman numerals (I, II, III, ...)
    %   'n'     Arabic numerals
    %   'N'     Arabic numerals
    %
    %    See also mlreportgen.dom.PageNumber
    %
    PageNumberFormat;
    
    %SectionBreak Page on which this layout starts	 
    %   This property specifies where this page layout starts: 
    %   on the next page, or on the next odd or even page. 
    %   An empty value indicates 'Next Page'.
    %   
    %   VALUE     
    %   'Same Page' 
    %   'Next Page' 
    %   'Odd Page' 
    %   'Even Page' 
    SectionBreak;
    
    %Watermark Watermark for this page layout.
    %   This property may be empty or specify a Watermark object
    %   that creates a watermark for this page layout, i.e., an
    %   image repeated on each page of this page layout.
    %   
    %   See also mlreportgen.dom.Watermark
    Watermark;
end
%}