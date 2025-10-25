%append Append an object to this list item
%    textObj = append(itemObj,'text') creates a Text object from the
%    specified text string. If the document output type is HTML, this 
%    method appends the text object to the list. If the output type is Word
%    or PDF, this method wraps the text object in a paragraph object and 
%    appends the paragraph object to the document. This is done because text 
%    objects can occur only in paragraphs in Word and PDF documents.
%
%    numberObj = append(itemObj,number) appends a Number object constructed
%    from the specified number to the list item.
%
%    textObj = append(itemObj,'text','styleName') creates a Text object 
%    containing the specified text string and having the specified 
%    stylename. If the document output type is HTML, this method appends 
%    the text object to the list. If the output type is Word or PDF, this 
%    method wraps the  text object in a paragraph object and appends the 
%    paragraph object to the document. This is done because text objects 
%    can occur only in paragraphs in Word and PDF documents.
%
%    textObj = append(itemObj,domObj) appends a DOM object to the item.
%    The object can be any of the following types:
%
%        * CustomElement
%        * EmbeddedObject
%        * ExternallLink
%        * FormalTable
%        * Image
%        * InternalLink
%        * LineBreak
%        * MATLABTable
%        * Number
%        * NumPages
%        * OrderedList
%        * Page
%        * PageRef
%        * Paragraph
%        * Table
%        * Text
%        * UnorderedList

%    Note: If the object to be appended is an inline object, such as text,
%    image, or hyperlinks, and the document output type is HTML, this
%    method appends the inline object to the document. If the output type
%    is Word or PDF, this method wraps the inline object in a paragraph
%    object and appends the paragraph to the document. This is done because
%    Word and HTML permit inline objects only in paragraph objects.

%    Copyright 2014-2021 The MathWorks, Inc.
%    Built-in function.
