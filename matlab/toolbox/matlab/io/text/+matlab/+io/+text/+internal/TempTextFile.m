classdef TempTextFile < handle
%Create a temp file to read/write with.

% Copyright 2021-2022 The MathWorks, Inc.

    properties
        Filename
        Encoding
    end

    methods
        function obj = TempTextFile(ext,namespace,enc)
        % create a TempTextFile
            arguments
                ext(1,1) string;
                namespace(1,1) string = "";
                enc(1,1) string = "UTF-8";
            end

            obj.Encoding = enc;

            if strlength(namespace) > 0
                namespace = namespace +"/";
                if ~isfolder("inmem:///"+namespace)
                    mkdir("inmem:///"+namespace);
                end
            end

            obj.Filename = "inmem:///"+namespace+(matlab.lang.internal.uuid+"."+ext);
        end

        function delete(obj)
            if exist(obj.Filename,"file")
                delete(obj.Filename);
            end
        end

        function text = getTextFromFile(obj)
            if obj.Encoding ~= "UTF-16"
                text = fileread(obj.Filename);
            else
                st = openTempFile(obj.Filename,"r");
                text = fread(st.ID,"*uint8")';
                text = char(typecast(text,"uint16"));
            end
            text = string(removeTrailingNewlines(text));
        end

        function writeTextToFile(obj,text)
            text = join(text(:),newline);
            if obj.Encoding ~= "UTF-16"
                st = openTempFile(obj.Filename,"w");
                fwrite(st.ID,char(text));
            else
                st = openTempFile(obj.Filename,"w");
                text = uint16(char(text));
                fwrite(st.ID,text,"uint16");
            end
        end
    end
end

function text = removeTrailingNewlines(text)
text = replace(text,char([13 10]),newline);
id = find(text~=newline,1,"last");
text(id+1:end) = [];
end

function st = openTempFile(fn,mode)
[st.ID,msg] = fopen(fn,mode,"n");
assert(st.ID >= 1,sprintf("Internal Error: %s",msg));
st.Cleanup = onCleanup(@()fclose(st.ID));
st.ID = matlab.io.internal.utility.updateFIDforBOM(st.ID,"system");
end
