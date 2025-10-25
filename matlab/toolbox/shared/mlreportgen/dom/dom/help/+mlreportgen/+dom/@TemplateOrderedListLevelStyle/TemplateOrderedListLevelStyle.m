%mlreportgen.dom.TemplateOrderedListLevelStyle Style that formats a level in an ordered list
%    This class represents a level of an ordered list style. Creating an
%    mlreportgen.dom.TemplateOrderedListStyle object populates the object's
%    Levels property with instances of this class. Use the LevelStyles
%    property to format the ordered list's levels.
%
%    TemplateOrderedListLevelStyle properties:
%        Level                  - List level modified by this style
%        NumberStyle            - Style of numbering used for this level
%        Formats                - DOM formatting objects that define this style
%        NumberFormats          - DOM formatting objects that apply to this level's list number
%        Id                     - Id of this style
%        Tag                    - Tag of this style
%
%    Example:
%
%     import mlreportgen.dom.*;
%     t = Template("myTemplate","pdf");
%     open(t);
%
%     % Create a list style
%     listStyle = TemplateOrderedListStyle("myOrderedListStyle");
%     % Define formats for level 1
%     level1Style = listStyle.LevelStyles(1);
%     level1Style.Formats = [Color("blue"), FontSize("32pt")];
%     % Define formats for level 2
%     level2Style = listStyle.LevelStyles(2);
%     level2Style.Formats = [Color("red"), FontSize("16pt")];
%     % Add style to the stylesheet
%     addStyle(t.Stylesheet,listStyle);
%
%     % Close the template
%     close(t);
%
%     % Use the style from the template
%
%     % Create a document using the generated template
%     d = Document("myDoc","pdf","myTemplate");
%     open(d);
%
%     % Create a list object with 2 levels
%     list = OrderedList(["first level item 1", "first level item 2"]);
%     secondLevelList = OrderedList(["second level item 1", "second level item 2"]);
%     append(list, secondLevelList);
%     % Set the style name
%     list.StyleName = "myOrderedListStyle";
%
%     % Add the list to the document
%     append(d,list);
%
%     % Close and view the document
%     close(d);
%     rptview(d);
%
%     See also mlreportgen.dom.TemplateOrderedListStyle.LevelStyles

%    Copyright 2023 Mathworks, Inc.
%    Built-in class

%{
properties
    %Level List level modified by this style
    %     Read-only property indicating the list level that this object
    %     formats, specified as an integer 1-9.
    Level;

    %NumberStyle Style of numbering used for this level
    %     Style of numbering used for this level, specified as a string. 
    %     The default value of this property is "decimal". The following
    %     are valid values:
    %
    %    VALUE                    SUPPORTED FORMATS  DESCRIPTION
    %    "circle"                 All                The marker is a circle
    %    "cjk-ideographic"        All                The marker is plain ideographic numbers
    %    "decimal"                All                The marker is a number
    %    "decimal-leading-zero"   All                The marker is a number with leading zeros (01, 02, 03, etc.)
    %    "disc"                   All                The marker is a filled circle
    %    "hiragana"               HTML, PDF          The marker is traditional Hiragana numbering
    %    "hiragana-iroha"         HTML, PDF          The marker is traditional Hiragana iroha numbering
    %    "katakana"               All                The marker is traditional Katakana numbering
    %    "katakana-iroha"         All                The marker is traditional Katakana iroha numbering
    %    "lower-alpha"            All                The marker is lower-alpha (a, b, c, d, e, etc.)
    %    "lower-greek"            HTML, PDF          The marker is lower-greek
    %    "lower-latin"            All                The marker is lower-latin (a, b, c, d, e, etc.)
    %    "lower-roman"            All                The marker is lower-roman (i, ii, iii, iv, v, etc.)
    %    "none"                   All                No marker is shown
    %    "upper-alpha"            All                The marker is upper-alpha (A, B, C, D, E, etc.)
    %    "upper-greek"            All                The marker is upper-greek
    %    "upper-latin"            All                The marker is upper-latin (A, B, C, D, E, etc.)
    %    "upper-roman"            All                The marker is upper-roman (I, II, III, IV, V, etc.)
    %    "decimal-hierarchical"   DOCX               The markers are numbers that include the  
    %                                                numbers of parent list levels. For example:
    %                                                   1.
    %                                                       1.1
    %                                                       1.2
    %                                                           1.2.1
    NumberStyle;

    %NumberFormats DOM formatting objects that apply to this level's list number
    %     Array of DOM formatting objects that are applied to only the list
    %     numbers for this level. This property is ignored for PDF list
    %     styles.
    NumberFormats;
end
%}