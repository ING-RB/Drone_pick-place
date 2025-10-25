%createTemplate Create a template
%   templatePath = createTemplate(path) creates a copy of the DOM default 
%   template at the specified path and returns the full file path of the 
%   new template.  The new template type depends on the file extension of the 
%   specified path.
%
%   templatePath = createTemplate(path,type) creates a copy of the DOM
%   default template of the specified type at the specified path and returns 
%   the full file path of the new template. 
%
%   File Extension          Template type           Template File Extension
%       .docx                   docx                    .dotx
%       .dotx                   docx                    .dotx
%       .pdf                    pdf                     .pdftx
%       .pdftx                  pdf                     .pdftx
%       .htmx                   html/html-multipage     .htmtx
%       .htmtx                  html/html-multipage     .htmtx
%       .html                   html-file               .htmt
%       .htmt                   html-file               .htmt
%
%  Note: This is a static method to be invoked on the Document class, 
%  not a Document instance.
%
%  Example
%
%  The following lines create Word templates.
%
%  templatePath = mlreportgen.dom.Document.createTemplate("MyTemplate.dotx");
%  templatePath = mlreportgen.dom.Document.createTemplate("MyTemplate","docx");

%  Copyright 2013-2023 The MathWorks, Inc.
%  Built-in method
