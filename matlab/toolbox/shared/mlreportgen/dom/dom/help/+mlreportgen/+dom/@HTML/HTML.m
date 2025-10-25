%mlreportgen.dom.HTML Convert HTML text to a group of DOM objects
%     htmlObj = HTML() creates an empty HTML object.
%
%     htmlObj = HTML(htmlText) converts a string of HTML text to a group
%     of DOM objects and appends it to a newly created HTML object. This
%     constructor supports common HTML elements and attributes, including
%     the HTML class and style attributes. It supports common CSS
%     formats as values of the HTML style attributes.
%
%     Note: DOCX and PDF documents require inline elements like text and
%     links to be contained in a paragraph. To meet this requirement, the
%     HTML parser creates wrapper paragraphs to contain any inline elements
%     that are not already in a paragraph. Therefore, if you create an
%     mlreportgen.dom.HTML object from HTML that has inline elements that
%     are not in paragraphs, adding the object to a report can produce HTML
%     that is different from the original HTML. To insert HTML markup
%     directly into an HTML document, use the mlreportgen.dom.RawText
%     class.
%
%     HTML properties:
%        Id                          - Id of this group object
%        HTMLTag                     - HTML tag name of this group
%        Children                    - Children of this group
%        Parent                      - Parent of this group
%        StyleName                   - Style name of this  group
%        Style                       - Formats to be applied to this group
%        Tag                         - Tag of this group object
%        KeepInterElementWhiteSpace  - Whether to convert white space
%                                      between HTML elements
%        EMBaseFontSize              - Font size used to convert EM unit 
%                                      values to point values
%
%     HTML methods:
%        append - Append HTML text or another HTML object to this HTML object
%
%    Example:
%
%    import mlreportgen.dom.*;
%    rpt = Document('MyReport', 'docx');
%    html = HTML('<p><b>Hello</b> <i style="color:green">World</i></p>');
%    append(html, '<p>This is <u>me</u> speaking</p>');
%    append(rpt, html);
%    close(rpt);
%    rptview(rpt.OutputPath);
%
%    HTML ELEMENT SUPPORT
%
%    This object supports the following HTML elements
%
%    ELEMENT    ATTRIBUTES
%    a          class, style, href, name
%    address    class, style
%    b          class, style
%    big        class, style
%    blockquote class, style
%    body       class, style
%    br        
%    center     class, style
%    cite       class, style
%    code       class, style
%    dd         class, style
%    del        class, style
%    dfn        class, style
%    div        class, style
%    dl         class, style
%    dt         class, style
%    em         class, style
%    font       class, style, color, face, size
%    hr         class, style, align
%    h1-h6      class, style, align
%    i          class, style
%    ins        class, style
%    img        class, style, src, height, width
%    kbd        class, style
%    li         class, style
%    mark       class, style
%    nobr       class, style
%    ol         class, style
%    p          class, style, align
%    pre        class, style
%    s          class, style
%    samp       class, style
%    small      class, style
%    span       class, style
%    strike     class, style
%    strong     class, style
%    sub        class, style
%    sup        class, style
%    table      class, style, align, bgcolor, border, cellspacing,
%               cellpadding, frame, rules, width
%    tbody      class, style, align, valign
%    tfoot      class, style, align, valign
%    thead      class, style, align, valign
%    td         class, style, bgcolor, height, width, colspan, rowspan,
%               align, valign, nowrap
%    th         class, style, bgcolor, height, width, colspan, rowspan,
%               align, valign, nowrap
%    tr         class, style, align, bgcolor, valign
%    tt         class, style
%    u          class, style
%    ul         class, style
%    var        class, style
%
%    For information on these elements, see http://www.w3schools.com/tags
%
%    CSS PROPERTIES SUPPORT
%
%    This object supports the following CSS properties:
%
%    background-color
%    border
%    border-bottom
%    border-bottom-color
%    border-bottom-style
%    border-bottom-width
%    border-color
%    border-left
%    border-left-color
%    border-left-style
%    border-left-width
%    border-right
%    border-right-color
%    border-right-style
%    border-right-width
%    border-style
%    border-top
%    border-top-color
%    border-top-style
%    border-top-width
%    color
%    counter-increment
%    counter-reset
%    display
%    font-family
%    font-size
%    font-style
%    font-weight
%    height
%    line-height
%    list-style-type
%    margin
%    margin-bottom
%    margin-left
%    margin-right
%    margin-top
%    padding
%    padding-bottom
%    padding-left
%    padding-right
%    padding-top
%    text-align
%    text-decoration
%    text-indent
%    vertical-align
%    white-space
%    width
%
%    For information on these formats, see http://www.w3schools.com/cssref
%
%    CUSTOM CSS PROPERTIES
%
%    HTML objects accept HTML markup that contains custom CSS properties,
%    i.e., properties that begin with '-'. Custom CSS properties are
%    included in HTML output but skipped in DOCX and PDF output.
%
%    Example: 
%
%    import mlreportgen.dom.*;
%    outputType = 'pdf';
%    d = Document('custom_css_props', outputType);
%    append(d, HTML(['<p style="' ...
%        '-moz-appearance:button;' ...
%        '-webkit-appearance:button;' ...
%        'color:red;' ...
%        '">Hello World</p>']));
%    close(d);
%    rptview(d.OutputPath);

%     Copyright 2014-2020 Mathworks, Inc.
%     Built-in class

%{
properties
     %KeepInterElementWhiteSpace Whether to convert white space between
     %HTML elements. 
     %    If this property is true, the DOM converts white space between 
     %    elements in the input HTML markup to DOM Text objects. 
     %    If false (the default), the DOM ignores white space between elements. 
     %    HTML browsers ignore white space between elements, allowing you 
     %    to use white space to format markup for readability, for example,
     %    using line feeds to divide markup into lines and spaces to indent
     %    the lines. This option allows you to specify that the DOM similarly 
     %    ignore white space used purely to format the HTML markup for readability.
     %
     %    Note: To use this property, create an empty HTML object and set the 
     %    property before appending the htmlText to the HTML object.
     %
     %    Note: This option allows you to to convert but not preserve 
     %    inter-element white space. To preserve white space, use the CSS 
     %    preserve-whitespace format in the style property of the parent HTML 
     %    element or use a WhiteSpace('preserve') format for the HTML object
     %    Style property. Do not use both approaches.
     %
     %    For example,
     %
     %    import mlreportgen.dom.*
     %    h = HTML();
     %    h.KeepInterElementWhiteSpace = true;
     %    % Works only if the parent HTML element does not have class and style 
     %    % properties.
     %    h.Style = {WhiteSpace('preserve')};
     %    append(h, '<p>     <span>Hello</span>      </p>');
     %
     %    h = HTML();
     %    h.KeepInterElementWhiteSpace = true;
     %    append(h, '<p style="white-space:pre">     <span>Hello</span>      </p>');
     %
     %    h = HTML();
     %    h.KeepInterElementWhiteSpace = true;
     %    append(h, [ ...
     %        '<style type="text/css">.myStyle { white-space: pre}</style>' ...
     %        '<p class="myStyle">    <span>Hello</span>     </p>']);
     KeepInterElementWhiteSpace;
     
     %EMBaseFontSize Font size used to convert EM unit values to point values
     %    This property specifies the font size, in points, that is used to
     %    convert values with EM units to point units. Any style in the 
     %    HTML text that has units of EM is converted to points by
     %    multiplying the EM numeric value with the EMBaseFontSize 
     %    property. 
     %
     %    For example, the font size for the paragraph
     %    
     %    h = HTML('<p style="font-size:2em">Hello</p>');
     %    
     %    produces a paragraph with font size of 24 points, which is
     %    calculated using the default EMBaseFontSize of 12 multiplied by
     %    2.
     %
     %    Note: In order to use this property create an empty HTML object 
     %    and set this property before appending the htmlText to the created
     %    HTML object.
     %
     %    For example,
     %
     %    h = HTML();
     %    h.EMBaseFontSize = 10;
     %    append(h, '<p style="font-size:2em">Hello</p>');
     %
     %    produces a paragraph with font size of 20 points.
     EMBaseFontSize;
    end
%}