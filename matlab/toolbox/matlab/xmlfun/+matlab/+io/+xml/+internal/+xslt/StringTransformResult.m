classdef StringTransformResult < matlab.io.xml.internal.xslt.TransformResult
% STRINGTRANSFORMRESULT implements the matlab.io.xml.internal.xslt.TransformResult
% interface. Used when the output of the xslt function is an in-memory string.

% Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=private, GetAccess=public)
        Result
    end

    properties (Dependent, SetAccess=private, GetAccess=public)
        Output
        URL
    end

    methods
        function obj = StringTransformResult()
            obj.Result = matlab.io.xml.transform.ResultString();
        end

        function output = get.Output(obj)
            output = obj.Result.String;
        end

        function url = get.URL(obj)
            url = "text://" + obj.Output;
        end
    end
end