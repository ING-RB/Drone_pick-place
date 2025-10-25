%mlreportgen.ppt.BaseDimension Base class for PPT API dimension format classes
%    Specifies the base class for the PPT API dimension format classes.
%
%    BaseDimension properties:
%       Value       - Dimension value
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Value Dimension value
     %  Value specified as a character vector or a string scalar. Use the
     %  format valueUnits, where Units is an abbreviation for the units.
     %  These abbreviations are valid:
     %
     %  Abbreviation    Units
     %
     %  px              pixels (default)
     %  cm              centimeters
     %  in              inches
     %  mm              millimeters
     %  pc              picas
     %  pt              points
     Value;

end
%}