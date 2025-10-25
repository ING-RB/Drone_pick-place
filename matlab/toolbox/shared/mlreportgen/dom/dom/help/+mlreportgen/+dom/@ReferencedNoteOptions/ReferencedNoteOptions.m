%mlreportgen.dom.ReferencedNoteOptions Base class of FootnoteOptions and EndnoteOptions
%
%    ReferencedNoteOptions properties:
%        NumberingType        - Numbering type of the marks
%        NumberingStartValue  - Start value of the mark numbering
%        NumberingRestart     - Specifies where the numbering should restart
%        Location             - Specifies the location of footnotes/endnotes
%        Id                   - Id of this element
%        Tag                  - Tag of this element
%
%    See also mlreportgen.dom.EndnoteOptions, mlreportgen.dom.FootnoteOptions

%    Copyright 2023-2024 MathWorks, Inc.
%    Built-in class

%{
properties
     %NumberingType Numbering type of footnote/endnote elements
     %    Value can be specified as empty or a character vector or
     %    string scalar as one of the following: 
     %        * "decimal" (default for FootnoteOptions)
     %        * "upperRoman"
     %        * "lowerRoman" (default for EndnoteOptions)
     %        * "upperLetter"
     %        * "lowerLetter"
     %        * "chicago"
     NumberingType;

     %NumberingRestart Specifies when footnote/endnote numbering should restart
     %    Value can be specified as empty or a character vector 
     %    or string scalar as one of the following:
     %    For FootnoteOptions: 
     %        * "continuous" (default)
     %        * "eachSect"
     %        * "eachPage"
     %
     %    "eachPage" option is only supported by DOCX output type.
     %
     %    For EndnoteOptions: 
     %        * "continuous" (default)
     %        * "eachSect"
     %
     %    For DOCX: Setting NumberingRestart in FootnoteOptions/EndnoteOptions 
     %              to any value apart from "continuous" restarts the numbering 
     %              to 1 and overrides NumberingStartValue, if any specified.
     NumberingRestart;

     %Location Specifies the location of footnote/endnote elements
     %    Value can be specified as empty or a character vector 
     %    or string scalar as one of the following:
     %    For FootnoteOptions:
     %        * "pageBottom" (default)
     %        * "beneathText"
     %
     %      "beneathText" option is only supported by DOCX output type. 
     %
     %    For EndnoteOptions:
     %        * "docEnd" (default)
     %        * "sectEnd"
     Location;

     %NumberingStartValue Start value of footnote/endnote mark numbering.
     %    Value can be specified as empty or a positive nonzero integer, specified 
     %    as a double which is rounded down if it contains a decimal part.
     %    Default is 1.   
     NumberingStartValue;
end
%}