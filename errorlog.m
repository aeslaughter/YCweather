function errorlog(varargin)
% ERRORLOG saves error information to errorlog.txt
%__________________________________________________________________________

% 0 - SET THE ERRORLOG FILE LOCATION
    pth = fileparts(getpref('YCweather','default'));
    fname = [pth,filesep,'errorlog.txt'];

% 1 - RETRIVE ERROR INFORMATION
    try 
       err = lasterror; rethrow(err); 
    catch ME,
        disp(getReport(ME,'extended'));
        disp('see workspace variables: rep & err');
        assignin('base','rep',getReport(ME,'extended'));
        assignin('base','err',ME);
    end
    
% 2 - BUILD THE TEXT FOR WRITING
    a{1} = ['-------------------------------------------------------',...
            '---------------------------'];
    a{2} = ['ERROR: ',datestr(now,'mmm/dd/yyyy HH:MM:SS')];
    a{3} = '';
    a{4} = ['MESSAGE: ',err.message];
    a{5} = ['IDENTIFIER: ',err.identifier];
    a{6} = '';
    a{7} = 'STACK:';

    for i = 1:length(err.stack);
        a = [a,['   File: ',err.stack(i).file]];
        a = [a,['   Name: ',err.stack(i).name]];
        a = [a,['   Line: ',num2str(err.stack(i).line)]];
        a = [a,''];
    end

% 3 - WRITE INFO TO FILE
    fid = fopen(fname,'a');
    for i = 1:length(a); fprintf(fid,'%s\n',a{i}); end
    fclose(fid);

% 4 - DISPLAY ERROR MESSAGE
    if isempty(varargin); 
        mes = 'An error was encountered, see errorlog.txt';
    else                  
        mes = varargin{1};
    end
    errordlg(mes,'ERROR');
