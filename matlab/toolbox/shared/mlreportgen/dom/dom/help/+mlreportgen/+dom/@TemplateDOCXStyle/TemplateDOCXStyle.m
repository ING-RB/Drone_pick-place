%mlreportgen.dom.TemplateDOCXStyle Style parsed from a DOCX template
%    This class represents a DOCX style defined by a DOCX template (.dotx)
%    file. Opening a DOCX template creates an array containing an instance
%    of this class for each style defined by the template file. You can
%    access the styles via the TemplateStyles property of the template's
%    Stylesheet property. This class is only used to indicate that a style
%    exists in the source DOCX template and that the style will be copied
%    to the generated template. A TemplateDOCXStyle can only be replaced or
%    removed from a stylesheet. It cannot be used to view or modify the
%    style formats. To view the formats for a TemplateDOCXStyle, open the
%    source DOCX template in Word and inspect the style. If you determine
%    the style does not meet your requirements, create a new text,
%    paragraph, linked, table, or list style programmatically and set its
%    formats as needed.
%
%    TemplateDOCXStyle properties:
%        Name                   - Name of this style
%        Type                   - Type of content this style formats
%        Formats                - (Ignored)
%        Id                     - Id of this style
%        Tag                    - Tag of this style
%
%    Example:
%
%    import mlreportgen.dom.*
%    % Create a Template using the default DOCX template
%    t = Template("myTemplate","docx");
%
%    % Open the template and check if the "rgMATLABTABLE" style exists
%    open(t);
%    stylesheet = t.Stylesheet;
%    tableStyle = getStyle(stylesheet,"rgMATLABTABLE")
%
%    % Open the source template in Word
%    rptview(t.TemplatePath);
%    % (Manually inspect the "Title" style in the source DOCX template)
%
%    % Create a new table style named "rgMATLABTABLE". Set it to be similar to the
%    % source template's "rgMATLABTABLE" style but have a blue border
%    newTableStyle = TemplateTableStyle("rgMATLABTABLE");
%
%    % Define formats similar to source template's style.
%    % Set font size, color, and line spacing.
%    oldFormats = [LineSpacing(1), FontFamily("Calibri"), WidowOrphanControl()];
%    % Leave a 15pt space after the table
%    om = OuterMargin();
%    om.Bottom = "15pt";
%    oldFormats(end+1) = om;
%
%    % Define format that gives the table a solid border
%    newFormat = Border("solid","blue");
%
%    % Set the formats of the new style
%    newTableStyle.Formats = [oldFormats, newFormat];
%    % Replace the old style with the new style
%    replaceStyle(stylesheet,newTableStyle);
%
%    % Close the template
%    close(t);
%
%     See also mlreportgen.dom.Template,
%     mlreportgen.dom.TemplateStylesheet,
%     mlreportgen.dom.TemplateStylesheet.replaceStyle,
%     mlreportgen.dom.TemplateStylesheet.removeStyle

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties

    %Name Name of this style
    %     Name of the style, specified as a string. This property is
    %     read-only.
    Name;

    %Type Type of content this style formats
    %     Type of content that this style formats, specified as a string.
    %     This property is read-only.
    Type;

    %Formats
    %     The Formats property is not used by the TemplateDOCXStylesheet
    %     class and does not indicate which formats define the DOCX style.
    %     Any formats added to this property programmatically are ignored
    %     when generating the template. To view the formats for a
    %     TemplateDOCXStyle, open the source DOCX template in Word and
    %     inspect the style. If you determine the style does not meet your
    %     requirements, create a new text, paragraph, linked, table, or
    %     list style programmatically and set its formats as needed.
    Formats;

end
%}

%Formats
    %     The Formats property is not used by the TemplateDOCXStylesheet
    %     class and does not indicate what formats define the DOCX style.
    %     Any formats added to this property programmatically are ignored
    %     when generating the template. To view the formats for a
    %     TemplateDOCXStyle, open the source DOCX template in Word and
    %     inspect the style. If you determine the style does not meet your
    %     requirements, create a new text, paragraph, linked, table, or
    %     list style programmatically and set its formats as needed.
    
    Formats;
