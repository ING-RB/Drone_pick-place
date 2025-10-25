%mlreportgen.ppt.FontFamily Font family
%    fontFamilyObj = FontFamily() creates a Times New Roman font family
%    object.
%
%    fontFamilyObj = FontFamily(font) creates a font family object based on
%    the specified font family name.
%
%    FontFamily properties:
%       Font                - Font family
%       ComplexScriptFont   - Font family for complex scripts
%       Id                  - ID for this PPT API object
%       Tag                 - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with different font family text
%    objects to the presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myFontFamilyPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph("Use the ");
%
%    % Append text that uses the monospace font Courier New
%    tFuncName = Text("zeros");
%    tFuncName.Style = {FontFamily("Courier New")};
%    append(p,tFuncName);
%
%    % Append text that uses the default font
%    tDesc = Text(" function to set an array to all zeros.");
%    append(p,tDesc);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.FontColor, mlreportgen.ppt.FontSize

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Font Font family
     %  Font family name, specified as a character vector or a string
     %  scalar. Specify a font that appears in the PowerPoint list of fonts
     %  in Home tab Font area.
     Font;

     %ComplexScriptFont Font family for complex scripts
     %  Font family name for complex scripts, specified as a character
     %  vector or a string scalar. Specify a font family for substituting
     %  in a locale that requires a complex script (such as Arabic) for
     %  rendering text.
     ComplexScriptFont;

end
%}