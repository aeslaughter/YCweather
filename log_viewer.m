function log_viewer(hObject,station,varargin)
% LOG_VIEWER opens a GUI to view images.
%__________________________________________________________________________
% USAGE: 
%   log_viewer(hObject,station)
%   log_viewer(hObject,station,day)
%
% INPUT: hObject - handle of calling object
%        station - the weather station of the desired log
%        day (optional) - the datenum of desired log

%__________________________________________________________________________

% 1 - BUILD THE DAILY LOG FOLDER LOCATION
    GUI    = guidata(hObject);              % Program Control guidata
    h      = guihandles(hObject);           % Handles of Program Control
    user   = get(h.(station),'UserData');   % Data for selected station
    pth = GUI.settings.paths.database;      % Folder of DATA directory
    loc = [pth,user.folder,'\',user.subfolder,...
                '\DailyLogs\'];           % Dailylog folder to open

% 2 - CHECK THAT LOG FILES EXIST
    % 2.1 - Search for folders within daily log directory
        available = dir([loc,'*.txt']);

    % 2.1 - Check that files exist
        if isempty(available)
            warndlg(['No daily logs exist for ',station,'.']); return;
        end

% 3 - BUILD LIST OF DAILY LOGS AVAILABLE
    [file,time] = build_log_list(available);

% 4 - OPEN THE VIEWER GUI
    % 4.1 - Set the selected date to open
        if isempty(varargin);
            t = floor(GUI.time(1));
        else
            t = varargin{1};
        end
        idx = find(time==t,1,'first');
        if isempty(idx); idx = 1; end

    % 4.2 - Open the gui and set the title
        main = DailylogGUI;
        h = guihandles(main);
        figname = [user.group,': ',user.display];
        set(main,'Name',figname)

    % 4.3 - Initilize the Dailylog GUI
        user = {loc,hObject,time};
        set(h.popup,'String',file,'UserData',user);
        set(h.popup,'Value',idx)

        % Envokes callback as if the user had sected a log from the list
        fhandle = get(h.popup,'Callback');
        fhandle(h.popup,1);

        % Set needed information for opening corresponding images
        set(h.openimages,'UserData',{time(idx),hObject});
        
%-----------------------------------------------------------------------
function [file,time] = build_log_list(available)
% BUILD_LOG_LIST creates a list of filenames and dates
    
% - BUILD CELL ARRAY OF FILENAMES
	x = struct2cell(available);
    file = x(1,:);
    
% - BUILD A LIST OF TIMES
    for i = 1:length(file);
        [p,n,e] = fileparts(file{i});
        try
            time(i) = datenum(n,'mm-dd-yy');
        catch
            time(i) = 0;
        end
    end
    
% - SORT THE LIST
    [time,idx] = sort(time);
    file = file(idx);
