%mlreportgen.dom.VerticalAlign Vertical alignment of an inline element
%    align = VerticalAlign() creates a superscript alignment.
%
%    align = VerticalAlign('value') creates an alignment as specified by
%    the 'value'.
%
%    VALUE                     DESCRIPTION
%    'superscript' or 'super'  Aligns the element as if it is superscript
%    'subscript' or 'sub'      Aligns the element as if it is subscript
%    'baseline'                Aligns the baseline of the element with the baseline of the parent element
%    'text-top'                Aligns the element with the top of the content area of parent element
%    'text-bottom'             Aligns the element with the bottom of the content area of parent element
%     length                   Aligns an element by the specified length. Negative values are allowed.  
%
%    The length argument is a character vector having the format valueUnits where Units is 
%    an abbreviation for the units  in which the length is expressed. 
%    The following abbreviations are valid:
%
%     Abbreviation  Units            
%     px            pixels           
%     cm            centimeters      
%     in            inches           
%     mm            millimeters      
%     pc            picas            
%     pt            points
%     %             percent
%
%    'text-top', 'text-bottom' are not supported by 'docx' document type.
%     Units %, px are not supported by 'docx' document type.
%
%    VerticalAlign properties:
%        Value - Vertical alignment of text relative to baseline
%        Id    - Id of this object
%        Tag   - Tag of this object
%
%    Example:
%    import mlreportgen.dom.*;
%    doctype = 'html';
%    d = Document('test', doctype);
%    p = Paragraph('e = mc');
%    t = Text('2');
%    t.Style = {VerticalAlign('superscript')};
%    append(p, t);
%    append(d, p);
%    close(d);
%    rptview('test', doctype);

%    Copyright 2014-2019 Mathworks, Inc.
%    Built-in class

%{
properties
     %Value Vertical alignment of text relative to baseline
     %
     %    VALUE                     DESCRIPTION
     %    'superscript' or 'super'  Aligns the text as if it is superscript
     %    'subscript' or 'sub'      Aligns the text as if it is subscript
     %    'baseline'                Aligns the baseline of the text with the baseline of the parent element
     %    'text-top'                Aligns the element with the top of the content area of parent element
     %    'text-bottom'             Aligns the element with the bottom of the content area of parent element
     %     length                   Aligns an element by the specified length. Negative values are allowed.
     %
     Value;
end
%}