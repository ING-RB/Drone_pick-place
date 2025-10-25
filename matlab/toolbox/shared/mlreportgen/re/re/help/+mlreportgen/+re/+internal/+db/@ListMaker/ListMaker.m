%mlreportgen.re.internal.db.ListMaker Generate a DocBook XML list
%    lm = ListMaker(listContents) creates an object that generates a
%    DocBook list element that contains listContents. Specify listContents
%    as a cell array that contains strings, character vectors, or DocBook XML
%    text, link, or paragraph nodes.
%
%    ListMaker properties:
%      ListContent          - Content of list
%      ListType             - Type of list
%      NumerationType       - Type of numeration to display for each list item
%      InheritnumType       - Whether to use compound list item numbers in nested lists
%      ContinuationType     - Whether to continue numbering from previous list
%      SpacingType          - How to space list items
%      ListTitle            - Title of list
%      ListTitleStyleName   - Style name of the list title
%      ListStyleName        - Style name of the list
%
%    ListMaker methods:
%      createList           - Generate a DocBook XML list element
%      getContent           - Get list content
%      setContent           - Set list content
%      getListType          - Get type of list to generate
%      setListType          - Set type of list to generate
%      getNumerationType    - Get numeration type to use
%      setNumerationType    - Set numeration type to use
%      getInheritnumType    - Whether to use compound list numbers
%      setInheritnumType    - Specify whether to use compound list numbers
%      getContinuationType  - Whether to continue numbering from previous list
%      setContinuationType  - Specify whether to continue numbering from previous list
%      getSpacingType       - How to space list items
%      setSpacingType       - Specify how to space list items
%      getTitle             - Get title of list
%      setTitle             - Set title of list
%      getTitleStyleName    - Get style name of list title
%      setTitleStyleName    - Set style name of list title
%      getListStyleName     - Get list style name
%      setListStyleName     - Set list style name

% Copyright 2021 MathWorks, Inc.

%{
properties

    % ListContent Contents of list
    %     This property contains a cell array of content to be made into
    %     list items. The cell array can contain any of the following types
    %     of content:
    %         - Character vectors
    %         - Strings
    %         - Numeric values
    %         - DocBoox XML Paragraph elements
    %         - DocBook XML Text nodes
    %         - DocBook XML Link elements
    % 
    %     To create a nested list, specify ListContent as a nested cell
    %     array. For example, if ListContent is specified as 
    %     {'item1', {'nestedItem1', 'nestedItem2'}, 'item2'}, the generated
    %     list will have the following layout:
    % 
    %         1. item1
    %             1. nestedItem1
    %             2. nestedItem2
    %         2. item2
    ListContent;

    % ListType Type of list
    %     Type of list, specified as one of the following:
    %         - "orderedlist"     - (default) A list in which each entry is marked 
    %                               with a sequentially incremented label.
    %         - "itemizedlist"    - A list in which each entry is marked with a
    %                               bullet point
    %         - "simplelist"      - An undecorated list usually for single words
    %                               or short phrases
    %
    %     See also https://tdg.docbook.org/tdg/4.5/orderedlist.html, 
    %     https://tdg.docbook.org/tdg/4.5/itemizedlist.html, 
    %     https://tdg.docbook.org/tdg/4.5/simplelist.html
    ListType;

    % NumerationType Type of numeration to display for each list item
    %     Type of numeration, specified as one of the following:
    %         - "arabic"        - (default) Arabic numerals (1, 2, 3, ...)
    %         - "loweralpha"    - Lower case alphabetic characters (a, b,
    %                             c, ...)
    %         - "upperalpha"    - Upper case alphabetic characters (A, B,
    %                             C, ...)
    %         - "lowerroman"    - Lower case roman numerals (i, ii, ...)
    %         - "upperroman"    - Upper case roman numerals (I, II, ...)
    %
    %     This property is only applicable if the ListType is
    %     "orderedlist".
    NumerationType;

    % InheritnumType Whether to use compound list item numbers in nested lists
    %     This property specifies how items in nested lists are numbered.
    %     Acceptable values are:
    %         - "ignore"    - (default) Do not use compound list item
    %                         numbers for nested lists. For example:
    %
    %                               1. item 1
    %                                   1. nested item 1
    %                                   2. nested item 2
    %                               2. item 2
    %
    %         - "inherit"   - Use compound list item numbers for nested
    %                         lists. For example:
    %
    %                               1. item 1
    %                                   1.1 nested item 1
    %                                   1.2 nested item 2
    %                               2. item 2
    %
    %     This property is only applicable if the ListType is
    %     "orderedlist".
    InheritnumType;

    % ContinuationType Whether to continue numbering from previous list
    %     This property specifies if the list numbering should continue the
    %     numbering from a preceding list or restart at 1.
    %     Acceptable values are:
    %         - "restarts"  - (default) Restart list numbering at 1
    %         - "continues" - Numbering should begin where the preceding
    %                         list left off
    %
    %     This property is only applicable if the ListType is
    %     "orderedlist".
    ContinuationType;

    % SpacingType How to space list items
    %     This property specifies whether the vertical space in the list
    %     should be minimized. Acceptable values are:
    %         - "compact"   - (default) Minimize vertical spacing
    %         - "normal"    - Do not minimize vertical spacing
    %
    %     This property is only applicable if the ListType is
    %     "orderedlist" or "itemizedlist".
    SpacingType;

    % ListTitle Title of list
    %     This property holds the title to be displayed before the
    %     list, specified as a string or character vector.
    ListTitle;

    % ListTitleStyleName Style name of the list title
    %     This property holds the style name used to format the list title,
    %     specified as a string or character vector.
    ListTitleStyleName;

    % ListStyleName Style name of the list
    %     This property holds the style name used to format the list,
    %     specified as a string or character vector.
    ListStyleName;

end
%}
