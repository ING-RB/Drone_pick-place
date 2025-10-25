classdef AtomicHelpSections < handle
    %ATOMICHELPSECTIONS - Stores information specific to one part of M-help.
    %ATOMICHELPSECTIONS stores the following:
    %* The text in the help part
    %* The title pertaining to that help part
    %* The type of help part

    % Copyright 2009-2021 The MathWorks, Inc.
    properties
        helpStr char = '';
        title   char = '';
        paragraphNumber (1,1) double = 0;
    end

    methods
        function this = AtomicHelpSections(title, helpStr, paragraphNumber)
            % ATOMICHELPSECTIONS - constructs an atomicHelpSections with the
            % default values.
            % ATOMICHELPSECTIONS(TITLE, HELPSTR, ENUMTYPE) - constructs an
            % atomicHelpSections and initializes its properties to those passed
            % in as input.
            arguments
                title   char = '';
                helpStr char = ''
                paragraphNumber (1,1) double = 0;
            end
            this.helpStr = helpStr;
            this.title = title;
            this.paragraphNumber = paragraphNumber;
        end

        function helpStr = getText(this)
            % GETTEXT - returns the stored text content as a string
            helpStr = char(join({this.helpStr}, newline));
        end

        function valid = hasValue(this)
            valid = ~isempty(this) && this(1).title ~= "";
        end

        function clearPart(this)
            arguments
                this (1,1) matlab.internal.help.AtomicHelpSections;
            end
            this.helpStr = '';
            this.title   = '';
        end
    end
end
