classdef HelpSystemCache < handle
    properties (Access=private)
        DocContentRoot (1,1) string
        DocDataRoot (1,1) string
        Language (1,1) string
        DataProp
    end

    properties (Dependent)
        Data
    end

    methods
        function obj = HelpSystemCache
            reset(obj);
        end

        function data = get.Data(obj)
            validate(obj);
            data = obj.DataProp;
        end

        function set.Data(obj, data)
            validate(obj);
            obj.DataProp = data;
        end

        function current = isCurrent(obj)
            current = matlab.internal.doc.docroot.getDocroot == obj.DocContentRoot && ...
                      matlab.internal.doc.docroot.getDocDataRoot == obj.DocDataRoot && ...
                      matlab.internal.doc.i18n.getDocLanguage == obj.Language;
        end
    end

    methods (Access=private)
        function validate(obj)
            if ~isCurrent(obj)
                reset(obj);
            end
        end

        function reset(obj)
            obj.DocContentRoot = matlab.internal.doc.docroot.getDocroot;
            obj.DocDataRoot = matlab.internal.doc.docroot.getDocDataRoot;
            obj.Language = matlab.internal.doc.i18n.getDocLanguage;
            obj.DataProp = [];
        end
    end
end