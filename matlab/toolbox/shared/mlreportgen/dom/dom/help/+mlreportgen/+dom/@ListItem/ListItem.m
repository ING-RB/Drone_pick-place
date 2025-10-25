%mlreportgen.dom.ListItem Item in a list
%    itemObj = ListItem() creates an empty list item.
%
%    itemObj = ListItem('text') creates a list item containing the 
%    specified text string.
%
%    itemObj = ListItem(number) creates a list item containing the specified 
%    floating-point or integer number.
%
%    itemObj = ListItem('text', 'styleName') creates a list item containing 
%    a mlreportgen.dom.Text object constructed from the specified text
%    string and having the specified style name.
%
%    itemObj = ListItem(domObj) creates a list item containing the
%    specified DOM object, which can be any of the following types:
%
%        * Paragraph
%        * Text
%        * Image
%        * Table
%        * FormalTable
%        * MATLABTable
%        * EmbeddedObject
%        * ExternalLink
%        * InternalLink
%        * OrderedList
%        * UnorderedList
%        * CustomElement
%        * Page
%        * PageRef
%        * NumPages
%        * Number
%
%    ListItem methods:
%        append         - Append a MATLAB or DOM object to this part
%        clone          - Clone this item
%
%    ListItem properties:
%        Children          - Children of this list item
%        CustomAttributes  - Custom item attributes
%        Id                - Id of this item
%        Parent            - Parent of this item
%        Style             - Formats that define this item's style
%        Tag               - Tag of this item
%
%   Note: 
%       For PDF documents, if a list contains a nested list, the nested
%       list will inherit styles set for the preceding list item in the
%       parent list. For example, suppose you create the following list:
%
%           * item 1
%               * item 2
%               * item 3
%
%       If the ListItem containing "item 1" has a style element that colors
%       the text red, the items in the nested list, "item 2" and "item 3",
%       will also be colored red. To prevent the nested list from
%       inheriting the syles from the preceding ListItem, set the style in
%       the Text or Paragraph object in the ListItem.

%    Copyright 2014-2020 Mathworks, Inc.
%    Built-in class
