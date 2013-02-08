function YCbuild(action, varargin)
% YCBUILD compiles and posts the YCweather software package
%__________________________________________________________________________
% SYNTAX: YCbuild(ver)
%
% DESCRIPTION:
%       YCbuild('build') compiles a new version of setup.exe, asking for version
%       YCbuiid('build',ver) compiles a new version of with given version num.
%       YCbuild('release') prepares the files for release including
%           building installer
%
% PROGRAM OUTLINE:
% 1 - SET FOLDER AND FILE NAMES
% 2 - RUN MATLAB COMPILIER TO BUILD A NEW RELEASE APPLICATION
%__________________________________________________________________________

% 0 - USER SPECIFIED LOCATIONS
dropbox = 'C:\Users\slaughter\Dropbox\YCweather';
%inno    = 'C:\Program Files (x86)\Inno Setup 5'; %For 64 bit systems
inno    = 'C:\Program Files\Inno Setup 5';  %For 32 bit systems

% 1 - RUN MATLAB COMPILIER TO BUILD A NEW RELEASE APPLICATION 
switch action;
    case 'build'
        
        % 1.1 - Copy external programs into current directory
        cfile = {'XYscatter\XYscatter.m','GetUnit\getunit.m',...
            'GetUnit\units.txt','waitbar.m','icons.ico'};
        for j = 1:length(cfile); 
            temp = ['..',cfile{j}]; 
            if exist(temp,'file'); copyfile(temp,prog,'f'); end
        end   

        % 1.2 - Determine the new version
            ver = num2str(dlmread([cd,filesep,'release',filesep,'version.txt']));
            if ~isempty(varargin); new = {num2str(varargin{1})};
            else
                new = inputdlg('Enter new version number:',...
                    'Version?',1,{ver});
            end

        % 1.3 - Write the new version file
            if ~isempty(new); 
                dlmwrite([cd,filesep,'release',filesep,'version.txt'],str2double(new{1})); 
            end
            
        % 1.4 - Build the executables
        pause(5);  % wait for the copy to complete
        deploytool -build YCmain.prj;
        deploytool -build YCinstaller.prj;

% 2 - SET FOLDER AND FILE NAMES
    case 'release'

    % 2.1 - Specific files to package into YCmain
        files{1} = [cd,filesep,'release',filesep,'YCmain.exe'];
        files{2} = [cd,filesep,'release',filesep,'version.txt'];
        files{3} = [cd,filesep,'release',filesep,'help.pdf'];
        files{4} = [cd,filesep,'release',filesep,'mesowest.mwu'];
        files{5} = [cd,filesep,'release',filesep,'license.txt'];
        
    % 2.2 - Create new version of help.pdf and update version
        latex = [cd,filesep,'documentation',filesep,'main_YCweather.pdf'];
        copyfile(latex, files{3},'f');
        copyfile('license.txt',['release',filesep,'license.txt']);

    % 2.3 - Create YCmain.zip and copy YCmain YCweather files to release
        zip([cd,filesep,'release',filesep,'YCmain'],files);  
        copyfile([cd,filesep,'release',filesep,'version.txt'],cd,'f');
              
    % 2.4 - Command for compiling installer
        m =['!"',inno,filesep,'compil32" /cc "installer_script.iss"'];
        eval(m);
        
% 3 - COPY DATA TO DROPBOX        
    case 'dropbox'
        
        % Copies the current years data to the dropbox folder
        copyDBfiles(dropbox);
        
        
end

%--------------------------------------------------------------------------
% SUBFUNCTION: copyDBfiles
function copyDBfiles(instl)
% COPYDBFILES current seasons database files to the release directory

% Determine the current season
    current = getfolder;
    loc = [cd,filesep,'database',filesep,current,'\'];
    out = [instl,filesep,'database',filesep,current]; mkdir(out);
    
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
