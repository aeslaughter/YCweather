function YCbuild(varargin)
% YCBUILD compiles and posts the YCweather software package
%__________________________________________________________________________
% SYNTAX: YCbuild(ver)
%
% DESCRIPTION:
%       YCbuild compiles a new version of setup.exe, asking for version
%       YCbuiid(ver) compiles a new version of with given version num.
%
% PROGRAM OUTLINE:
% 1 - SET FOLDER AND FILE NAMES
% 2 - RUN MATLAB COMPILIER TO BUILD A NEW RELEASE APPLICATION
%__________________________________________________________________________

% 1 - SET FOLDER AND FILE NAMES
    % 1.1 - Command for compiling installer
        iscc = 'C:\Program Files (x86)\Inno Setup 5\compil32 /cc "installer_script.iss"';

    % 1.2 - Specific files to package into YCmain
        files{1} = [src,'YCmain.exe'];
        files{2} = [real,'version.txt'];
        files{3} = [real,'help.pdf'];
        files{4} = [real,'mesowest.mwu'];
        files{5} = [real,'winscp.exe'];
        files{6} = [real,'license.txt'];

    % 1.3 - Create new version of help.pdf
        latex = 'documentation\main_YCweather.pdf';
        copyfile(latex,files{3},'f');
  
% 2 - RUN MATLAB COMPILIER TO BUILD A NEW RELEASE APPLICATION
    % 2.1 - Copy external programs into current directory
        cfile = {'XYscatter\XYscatter.m','GetUnit\getunit.m',...
                'GetUnit\units.txt','waitbar.m','icons.ico'};
        for j = 1:length(cfile); 
            temp = ['..',cfile{j}]; 
            if exist(temp,'file'); copyfile(temp,prog,'f'); end
        end

    % 2.2 - Run compilers on YCmain and YCinstaller
        m = 'deploytool -build YCmain.prj'; eval(m);
        m = 'deploytool -build YCinstaller.prj'; eval(m);

    % 2.4 - Copy format *.yc and database files to the release folder
        copyDBfiles(real);

    % 2.5 - Change version file
        % 2.5.1 - Determine the new version
            ver = num2str(dlmread([real,'version.txt']));
            if ~isempty(varargin); new = {num2str(varargin{1})};
            else
                new = inputdlg('Enter new version number:',...
                    'Version?',1,{ver});
            end

        % 2.5.2 - Write the new file
            if ~isempty(new); 
                dlmwrite([real,'version.txt'],str2double(new{1})); 
            end

    % 2.6 - Create YCmain.zip and copy YCmain\YCweather files to release
        zip([real,'YCmain'],files);  
        copyfile(files{1},real,'f'); 
        copyfile([pkg,'YCweather.exe'],real,'f');
        copyfile([real,'version.txt'],prog,'f');

    % 2.7 - Create Windows installer program
        eval(iscc);
        
% 3 - POST LATEST VERSION TO THE WEB/DESKTOP
%     case 'web';   
%     % 3.1 - Establish generic put/rm commands
%         A{1} = '!winscp.exe ';
%         A{2} = 'snow:Sno$2008@caesar.ce.montana.edu /command ';
%         A{4} = ' "exit"'; 
%         post = {'YCmain.zip','version.txt','help.pdf','YCinstaller.exe'};    
% 
%     % 3.2 - Update files
%         for i = 1:length(post);
%             disp(['Removing old file... ',post{i}]);
%             A{3} = ['"rm ',serv,post{i},'"']; eval([A{:}]);
%             disp(['Uploading new file... ',post{i}]);
%             A{3} = ['"put ',real,post{i},' ',serv,'"']; eval([A{:}]);  
%         end
% 
%     % 3.3 - Sync format folder
%         current = getfolder;
%         A{3} = ['"synchronize remote "',real,'database\',current,...
%             '\*.yc" /home/snow/db/" '];
%         A{4} = '"rmdir /home/snow/db/.svn/" ';
%         A{5} = '"exit"'; 
%         disp('Synchronizing release\format folder...');
%         eval([A{:}]);
%         disp('Web posting complete.');

%--------------------------------------------------------------------------
% SUBFUNCTION: copyDBfiles
function copyDBfiles(instl)
% COPYDBFILES current seasons database files to the release directory

% Determine the current season
    current = getfolder;
    loc = [cd,'\database\',current,'\'];
    out = [instl,'database\',current]; mkdir(out);
    
% Copy the *.dat and *yc files to installer folder
    dat = dir([loc,'*.dat']);
    yc = dir([loc,'*.yc']);
    meso = [loc,'mesowest.txt'];
    
    if ~isempty(dat); 
        for i = 1:length(dat); 
            copyfile([loc,dat(i).name],out,'f'); 
        end; 
    end
    
    if ~isempty(yc); 
        for i = 1:length(yc); 
            copyfile([loc,yc(i).name],out,'f'); 
        end;  
    end
    
    if exist(meso,'file'); copyfile(meso,out,'f'); end

%--------------------------------------------------------------------------
% SUBFUNCTION: getfolder
function fldr = getfolder
% GETFOLDER determines the current season/folder for archiving data

% 1 -  Get the current time
    c = clock;

% 2 - Determine the current folder based on water-year
    if c(2) < 10; % Case when before October
        yr2 = num2str(c(1));
        yr1 = num2str(c(1)-1);
        fldr = [yr1(3:4),'-',yr2(3:4)];
    
    else % Case when after Octoboer
        yr1 = num2str(c(1));
        yr2 = num2str(c(1)+1);
        fldr = [yr1(3:4),'-',yr2(3:4)];
    end
