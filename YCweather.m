function YCweather
% YCWEATHER is the front end to YCmain.exe program.
%__________________________________________________________________________
% SYNTAX: YCweather
%
% PROGRAM OUTLINE:
% 1 - FIND THE AVAILABLE VERSIONS
% 2 - COMPARE THE VERSIONS
% 3 - INSTALLS NEW PROGRAM
%__________________________________________________________________________

try
% 0 - WEB PATH
   % pth = '
    
% 1 - FIND THE AVAILABLE AND CURRENT VERSIONS
    % 1.1 - Find available version     
        try
            available = urlread(['http://www.coe.montana.edu/',...
                        'ce/subzero/snow/version.txt']);
            available = str2double(available);
        catch
            disp('Connection failed, cannot test version.');
            winopen('YCmain.exe'); return;
        end

    % 1.2 - Determine the current version
        if exist([cd,'\version.txt'],'file'); 
            current = dlmread([cd,'\version.txt']);
        else
            current = 0;
        end

% 2 - COMPARE THE VERSIONS
    % 2.1 - Compare available with current version
        if available <= current; 
            winopen('YCmain.exe'); return;
        else
            mes = ['A new version of YCweather is available, ',...
                    'would you like to install this version?'];
            q = questdlg(mes,'New version...','Install','Continue',...
                    'Install');
        end

    % 2.2 - Open program if desired
        if ~strcmpi(q,'Install'); winopen('YCmain.exe'); return; end;
         
% 3 - INSTALLS NEW PROGRAM
    % 3.1 - Establish the download wait display 
        h = msgbox(['Downloading newest version of YCweather, ',...
                'please wait...'],'Downloading...');
        H = guihandles(h);
        set(H.OKButton,'Visible','off');
        pause(1);

    % 3.2 - Download the new software
        try
            url = 'http://www.coe.montana.edu/ce/subzero/snow/YCmain.zip';
            unzip(url,cd);
            pause(1);
        catch 
            errorlog('Download failed, cannot update version.'); 
            close(h); winopen('YCmain.exe'); return;
        end  

    % 3.3 - Open YCweather main program
        close(h);    
        winopen('YCmain.exe');
catch
    mes = ['An error occured in running YCweather ',...
            '(YCweather.m), see errorlog.txt.'];
    errorlog(mes); 
end
    