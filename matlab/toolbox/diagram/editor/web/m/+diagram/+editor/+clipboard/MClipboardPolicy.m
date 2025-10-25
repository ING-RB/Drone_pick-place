classdef (Abstract) MClipboardPolicy < diagram.editor.clipboard.AbstractClipboardPolicy
    % MCLIPBOARDPOLICY provides default implementations for some of the
    % methods of AbstractClipboardPolicy. WDF downstream should subclass
    % this class to write a custom clipboard policy. Directly subclassing
    % AbstractClipboardPolicy will mean that all the methods will have to
    % be overridden.
    methods(Abstract)
        id = getDomainId(obj)
    end

    methods
        function version = getAppVersion(~)
            version = "";
        end

        function bool = canAcceptPayload(this, clipboardData)
            bool = clipboardData.getDomainId == this.getDomainId;
        end

        function data = getCustomClipboardData(~)
            data = "";
        end

        function elems = filterElementsForCopy(this, elements, allSubElements)
            elems = this.defaultCopyFilter(elements, allSubElements);
        end

        function elems = filterElementsForCut(this, elements, allSubElements)
            elems = this.defaultCopyFilter(elements, allSubElements);
        end

        function elems = defaultCopyFilter(~, elements, allSubElements)
            
            function bool = includeElem(elem)
                bool = true;
                
                if (isa(elem, "diagram.interface.Connection"))
                    % We only copy connections if both the src and dst
                    % entities are also copied
                    srcIsCopied = any(arrayfun(@(e) e == elem.source, allSubElements, UniformOutput=true));
                    dstIsCopied = any(arrayfun(@(e) e == elem.destination, allSubElements, UniformOutput=true));
                    bool = srcIsCopied && dstIsCopied;

                elseif (isa(elem, "diagram.interface.Port"))
                    % Ports should only be copied if the parent is also
                    % copied
                    bool = any(arrayfun(@(e) e == elem.getParent, allSubElements, UniformOutput=true));
                end
            end

            elems = elements(arrayfun(@includeElem, elements));
        end

        function json = provideSemanticData(~, ~)
            json = "{}";
        end
    end
end
