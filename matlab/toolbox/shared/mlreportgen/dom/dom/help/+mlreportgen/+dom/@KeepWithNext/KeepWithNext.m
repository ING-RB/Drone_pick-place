%mlreportgen.dom.KeepWithNext Keep DOM object on same page as next
%    obj = KeepWithNext() keeps a DOM object on the same page as the
%    next that follows it.
%
%    obj = KeepWithNext(tf) keeps a DOM object on the same page as the next
%    if tf = true.
%
%    Note: this format applies only to Paragraph, Table Row, and List Item 
%          in Microsoft Word and PDF documents.
%
%    KeepWithNext properties:
%        Value    - Whether to keep DOM object on same page as next
%        Strength - Strength value of KeepWithNext for PDF report
%        Id       - Id of this object
%        Tag      - Tag of this object

%    Copyright 2014-2022 MathWorks, Inc.
%    Built-in class

%{
properties
     %Value Whether to keep the DOM object on same page as next
     %
     %      Valid values:
     %
     %      true  - keep DOM object on same page as next
     %      false - allow a page break between this DOM object and the next
     %
     Value;

     %Strength Strength of KeepWithNext for PDF report
     %    The value of this property is a character vector or string scalar 
     %    or integer that specifies the strength of KeepWithNext for PDF report. 
     %    Default value is 1. Valid values are "always" or integer values.  
     %    See for more info, https://www.w3.org/TR/xsl11/#keep-with-next
     Strength;

     %Id Id of this object
     %      Id of this object.
     Id;

     %Tag Tag of this object
     %      Tag of this object.
     Tag; 
end
%}