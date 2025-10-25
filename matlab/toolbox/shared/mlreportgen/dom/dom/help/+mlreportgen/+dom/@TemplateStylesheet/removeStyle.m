%removeStyle Remove styles in this stylesheet
%    styles = removeStyle(this,styleName) removes styles whose names match
%    styleName, specified as a string scalar or character vector. If no
%    styles have the specified styleName, this method returns an empty
%    double. Otherwise, it returns the removed style objects.
%
%    styles = removeStyle(this,style) removes the style whose name and type
%    match those of style, specified as any subclass of
%    mlreportgen.dom.TemplateStylesheetStyle, and returns the removed
%    style.
% 
%    styles = removeStyle(this,styleName,type) removes styles of the
%    specified type whose names match styleName. If no styles have the
%    specified type and name, this method returns an empty double.
%    Otherwise, it returns the removed style objects. The type argument can
%    be specified as any of the following values:
%
%         * text
%         * paragraph
%         * linked
%         * table
%         * list
%         * html
%         * pdf
%         * docx

%    Copyright 2023 MathWorks, Inc.
%    Built-in function.
