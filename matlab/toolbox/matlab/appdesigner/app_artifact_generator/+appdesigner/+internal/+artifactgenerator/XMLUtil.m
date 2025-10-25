classdef (Sealed) XMLUtil < handle
    %XMLUTIL Static utility-like APIs used during plain-text app appendix processing.

    %   Copyright 2024 The MathWorks, Inc.

    methods (Access = private)
        function obj = XMLUtil()
            % Static Utilities only. No instances allowed.
        end
    end

    methods (Static)
        function document = parseAppXML (filepath, fileContent, xmlString)
            parser = matlab.io.xml.dom.Parser;

            errorHandler = appdesigner.internal.artifactgenerator.AppParserErrorHandler(filepath);

            parser.Configuration.ErrorHandler = errorHandler;

            document = parseString(parser, xmlString);

            if ~isempty(errorHandler.Errors)
                count = length(errorHandler.Errors);
                for i = 1:count
                    if strcmp(errorHandler.Errors(i).Severity, "FatalError")
                        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixFatalErrorException(...
                            filepath, errorHandler.Errors(i), fileContent);

                        throw(ex);
                    end
                end
            end
        end

        function document = parseXML (xmlString)
            parser = matlab.io.xml.dom.Parser;

            document = '';

            try
                document = parseString(parser, xmlString);
            catch ME
                % todo? Inform user the run config is broken?
            end
        end

        function value = getElementValue(element)
            % Retreives the component property value of an XML elment. Taking account of
            % possible CDATA sections.

            arguments
                element matlab.io.xml.dom.Element
            end

            value = '';

            childNodes = element.getChildNodes();

            for i = 1:childNodes.getLength()
                child = childNodes.item(i - 1);

                if isa(child, 'matlab.io.xml.dom.Text') || isa(child, 'matlab.io.xml.dom.CDATASection')
                    value = [value, child.getData()];
                end
            end
        end

        function contextMenuElements = getContextMenuElements(figureChildrenElement)
            %GETCONTEXTMENUELEMENTS Context menus are created first, and are also a direct descendent of figures

            arguments
                figureChildrenElement matlab.io.xml.dom.Element
            end

            child = figureChildrenElement.getFirstElementChild();

            childNodes = figureChildrenElement.getChildNodes();

            count = childNodes.getLength();

            ctxCount = 1;
            contextMenuElements = cell(1, count);

            while ~isempty(child) && isvalid(child)
                if strcmp(child.TagName, 'ContextMenu')
                    contextMenuElements{ctxCount} = child;
                    ctxCount = ctxCount + 1;
                end

                child = child.getNextElementSibling();
            end

            contextMenuElements = contextMenuElements(1:ctxCount - 1);
        end
    end
end