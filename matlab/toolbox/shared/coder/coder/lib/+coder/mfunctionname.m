function callerName = mfunctionname
%CODER.MFUNCTIONNAME return the name of the calling function
%
% In MATLAB, CODER.MFUNCTIONNAME uses dbstack to identify the calling
% function name.
% In code generation, CODER.MFUNCTIONNAME uses an internal name that may be
% more detailed than the MATLAB name.
%
% Example: calling "foo" displays 'foo/nested'
% function foo
%     nested;
%     function nested
%         disp(coder.mfunctionname);
%     end
% end
%
% Note: Results are not expected to be the same between MATLAB and code
% generation. In particular, differences include:
% * methods in @ folders
% * constructors
% * anonymous functions

s = dbstack;
if numel(s) < 2
    callerName = '<command_line_or_unknown>';
    return
end
callerName = s(2).name;