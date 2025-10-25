function logData(varNameOrMsg, data)
%MATLAB Code Generation Private Function

%   Copyright 2019-2023 The MathWorks, Inc.

% Helper function to log data in codegen and MATLAB. Logs to 2 files
% based on coder.target. By default writes to matlab.txt in MATLAB
% execution and codegen.txt in codegen modes.
%
% Example: logData('NetworkChannel::stepImpl::y(:,rx)', y(:,rx)) prints out:
%
%  NetworkChannel::stepImpl::y(:,rx) double [100 x 1] = 0 + 0i, 0 + 0i, ...

% Change these targets and file names to match what you want to compare:
%  MATLAB vs codegen - coder.target('MATLAB')
%  MEX vs standalone code - coder.target('MEX') and coder.target('rtw')
%#codegen
if coder.target('MATLAB')
    fname = 'matlab.txt';
else
    fname = 'codegen.txt';
end
% Append so we don't lose data
f = fopen(fname,'a+');
if nargin > 1
    % Print varName className [dim1 x dim2 x ... x dimn] =
    fprintf(f, '%s %s [', varNameOrMsg, class(data));
    sz = size(data);
    for k = 1:numel(sz)-1
        fprintf(f, '%d x ', int32(sz(k)));
    end
    fprintf(f, '%d] = ', int32(sz(end)));
    % Print values in linear indexing order. Values are cast to
    % double first.
    for k = 1:numel(data)
        d = double(data(k));
        fprintf(f, '%g', real(d));
        if ~isreal(data)
            id = imag(d);
            if id < 0
                fprintf(f, ' - %gi', abs(id));
            else
                fprintf(f, ' + %gi', id);
            end
        end
        fprintf(f, ', ');
    end
else
    % Print message
    fprintf(f, '%s', varNameOrMsg);
end
fprintf(f,'\n\n');
fclose(f);
