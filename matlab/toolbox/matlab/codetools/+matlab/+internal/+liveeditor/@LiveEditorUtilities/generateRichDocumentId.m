function [output, error] = generateRichDocumentId()
    % generateRichDocumentId - This function is used by MATLAB Mobile
    % Returns an ID used by Live Script on MATLAB Mobile
try
    rd = com.mathworks.mde.liveeditor.widget.rtc.RichDocument();
    output = char(rd.getUniqueKey());
    error = '';
catch ME
    output = '';
    error = ME.getReport();
end
