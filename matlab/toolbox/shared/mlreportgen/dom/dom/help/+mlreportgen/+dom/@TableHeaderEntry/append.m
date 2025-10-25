%append Append content to a table header entry
%     textObj = append(entry, 'text') creates a table header entry containing a Text 
%     object containing the specified text.
%
%     textObj = append(entry, 'text', 'StyleName') creates a table header entry 
%     containing a Text object containing the specified text and having 
%     the specified style.
%
%     domObj = append(entry, domObj) creates a table header entry containing 
%     domObj, where domObj is an object of any of the following types:
%
%         * CustomElement
%         * EmbeddedObject
%         * ExternalLink
%         * HTML
%         * HTMLFile
%         * HorizontalRule
%         * Image
%         * InternalLink
%         * LineBreak
%         * OrderedList
%         * NumPages
%         * Page
%         * PageRef
%         * Paragraph
%         * StyleRef
%         * UnorderedList
%         * Table
%         * Text

%    Copyright 2013-2019 MathWorks, Inc.
%    Built-in function.
