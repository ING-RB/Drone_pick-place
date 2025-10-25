%mlreportgen.dom.TemplateStylesheetStyle Base class for DOM style classes
%    This class is the base class for all DOM style objects that define
%    styles in an mlreportgen.dom.TemplateStylesheet.
%
%    TemplateStylesheetStyle properties:
%        Formats                - DOM formatting objects that define this style
%        Id                     - Id of this style
%        Tag                    - Tag of this style

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties

    %Formats DOM formatting objects that define this style
    %     Array of DOM formatting objects such as mlreportgen.dom.Bold,
    %     mlreportgen.dom.FontSize, etc. that define how this style affects 
    %     report content.
    Formats;

end
%}