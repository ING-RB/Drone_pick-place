classdef (Abstract) TransformResult
% TRANSFORMRESULT defines an object interface so the MAXP implementation of
% xslt does not need to know if an XSL transform output is a file or an
% in-memory string.

% Copyright 2024 The MathWorks, Inc.

    properties (Abstract, SetAccess=private, GetAccess=public)
        % RESULT - The result object to provide to transform@matlab.io.xml.transform.Transformer.
        % Must be a concrete subclass of matlab.io.xml.transform.Result.
        %
        Result(1, 1) matlab.io.xml.transform.Result
    end

    properties (Abstract, Dependent, SetAccess=private, GetAccess=public)
        % OUTPUT - The output to return from xslt.
        Output(1, 1) string

        % URL - The url to supply as input to web to display the XSL
        % transformation in the MATLAB Help browser.
        URL(1, 1) string
    end
end