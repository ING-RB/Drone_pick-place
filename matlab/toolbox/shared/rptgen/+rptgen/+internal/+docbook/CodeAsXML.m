classdef CodeAsXML < handle
    %CODEASXML Convert MATLAB code to syntax-highlighted XML.

    %   Copyright 2020-2023 Mathworks, Inc.

    methods (Static)

        function mainEl = xmlize(varargin)
            % tokenizedCode = xmlize(doc,code) parses MATLAB code into
            % tokens that are highlighted in MATLAB code: keywords,
            % strings, unterminated strings, comments, system commands. The
            % method returns the tokenized code as an XML DOM element of
            % type matlab.io.xml.dom.Element. The doc argument is an XML
            % DOM document of type matlab.io.xml.dom.Document. This method
            % uses the document to create the tokenized XML elements. The
            % XML elements returned by this method conforms to the
            % Mathworks syntaxhighlight DTD (see
            % matlab/sys/namespace/mcode/v1/syntaxhightlight.dtd); For
            % example, the element that it returns is a top-level element
            % mwsh:code that contains generated tokens of type
            % mwsh:keywords, mwsh:strings, etc.
            %
            % Use the following XSL stylesheets to transform the tokenized
            % XML into HTML or PDF syntax-highlighted MATLAB code:
            %
            %   matlab/sys/namespace/docbook/v4/xsl/html/mcode.xsl
            %   matlab/sys/namespace/docbook/v4/xsl/fo/mcode.xsl
            %
            % tokenizedCode = xmlize(code) uses an XML document that it
            % creates to tokenize the MATLAB code.

            if (nargin == 1)
                code = varargin{1};
                mainEl = matlab.internal.codeToXML(code);
            else
                ownerDoc = varargin{1};
                code = varargin{2};
                mainEl = matlab.internal.codeToXML(ownerDoc, code);
            end
        end
    end
end
