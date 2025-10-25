% mlreportgen.ppt.TablePlaceholder Slide placeholder to replace with table
%     Slide placeholder to replace with table. You can create a table
%     placeholder using a layout slide. In the default PPT API, when you
%     add a "Title and Table" layout slide to a presentation, the API
%     creates a TablePlaceholder object. Use the find method with the slide
%     object, to find the table placeholder. You can then set properties
%     for that TablePlaceholder object.
%
%    TablePlaceholder methods:
%      replace            - Replace table placeholder with table
%
%    TablePlaceholder properties:
%      Bold                 - Option to use bold for text
%      Font                 - Font family for text
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color for text
%      FontSize             - Font size for text
%      Italic               - Option to use italic for text
%      Strike               - Text strikethrough style
%      Subscript            - Option to display text as a subscript
%      Superscript          - Option to display text as a superscript
%      Underline            - Text underline style
%      BackgroundColor      - Table placeholder background color
%      VAlign               - Vertical alignment of text
%      Name                 - Table placeholder name
%      X                    - Upper-left x-coordinate position of placeholder
%      Y                    - Upper-left y-coordinate position of placeholder
%      Width                - Width of placeholder
%      Height               - Height of placeholder
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Tag                  - Tag for this PPT API object
%      Id                   - ID for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myTablePlaceholderPresentation.pptx");
%    open(ppt);
%
%    % Add a slide with "Title and Table" layout to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % The "Title and Table" layout includes a TablePlaceholder object with
%    % name "Table". Use the slide's find method to find the object.
%    contents = find(slide,"Table");
%
%    % Replace the placeholder with a table
%    table = Table(magic(9));
%    replace(contents(1),table);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.TemplateTable,
%    mlreportgen.ppt.TableRow, mlreportgen.ppt.TableEntry

%    Copyright 2020 The MathWorks, Inc.
%    Built-in class

