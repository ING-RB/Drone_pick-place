%append Append content to a table entry
%     textObj = append(entry,'text') wraps 'text' in a Paragraph object
%     and appends the Paragraph object to the table entry. The text is 
%     wrapped in a paragraph only in Microsoft Word and PDF output because
%     Word and PDF do not permit unwrapped text in table entries. In HTML 
%     output, the text is not wrapped in a paragraph.
%
%     Note: text wrapping can cause unexpected behavior in PDF output.
%
%     textObj = append(entry,'text','StyleName') wraps 'text' in a
%     Paragraph object and appends the Paragraph object to the table entry.
%     The text is wrapped in a paragraph only in Microsoft Word and PDF
%     output because Word and PDF do not permit unwrapped text in table
%     entries. In HTML output, the text is not wrapped in a paragraph.
%
%     domObj = append(entry,domObj) creates a table entry containing
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
%         * Number
%         * NumPages
%         * Page
%         * PageRef
%         * Paragraph
%         * StyleRef
%         * UnorderedList
%         * Table
%         * Text
%
%    Note: If the object to be appended is an inline object, such as text,
%    image, or hyperlinks, and the document output type is HTML, this
%    method appends the inline object to the document. If the output type
%    is Word or PDF, this method wraps the inline object in a paragraph
%    object and appends the paragraph to the document. This is done because
%    Word and HTML permit inline objects only in paragraph objects.
%
%    Copyright 2013-2021 The MathWorks, Inc.
%    Built-in function.
