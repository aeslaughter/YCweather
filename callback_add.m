function callback_add(hObject,eventdata,type)
% CALLBACK_addlog enables user to add a new daily log to database
%__________________________________________________________________________
% USAGE: callback_addlog(hObject,eventdata)
%
% INPUT: hObject - handle to a Program Control object
%        eventedata - not used, MATLAB required
%
% PROGRAM OUTLINE:
% 1 - DETERMINE THE FILE TO WRITE
% 2 - ADD NEW DAILY LOG TO DATABASE
% 3 - ADD NEW IMAGES TO DATABASE
% SUBFUNCTION: getyear
%__________________________________________________________________________

try
% 1 - DETERMINE THE FILE/FOLDER TO WRITE
    % 1.1 - Get selected station
        use = getselected(hObject);
        if isempty(use);        
            errordlg('You must select a station.','Error'); return;
        elseif length(use) > 1; 
            errordlg('You may only select a single station.','Error');
            return;
        end

    % 1.2 - Set the folder for storing the new log
        GUI = guidata(hObject);
        h = guihandles(hObject);
        season = GUI.season;

    % 1.3 - Build the file name for the new log
        str = get(h.add_month,'String');
        month = str{get(h.add_month,'Value')};
        [yr,mo] = getyear(season,month);
        
        formatspec = '%02.0f';  %djwalters added to get appropriate file naming
        dy = num2str(get(h.add_day,'Value'),formatspec);
        name = [mo,'-',dy,'-',yr,];
       
% 2 - ADD NEW DAILY LOG TO DATABASE
switch type
    case 'log'
    user = get(h.(use{1}),'UserData');
    loc = [GUI.settings.paths.database,user.folder,'\',...
                user.subfolder,'\DailyLogs\'];
    filename = [loc,name,'.txt'];
    
    % 2.1 - Warn user that file already exists
    if exist(filename,'file');
        mes = ['A Daily log already exists for ',use{1},' on this date',...
                ', would you like to open a blank log anyway?'];
        a = questdlg(mes,'Open new log?','Continue','Cancel','Cancel');
        if ~strcmpi(a,'Continue'); return; end
    end

    % 2.2 - Open the GUI and set filename to save
        main = DailylogGUI;
        h = guihandles(main);
        set(h.save,'UserData',filename);

    % 2.3 - Set visibility options for object not in use
        tag = {'forward','back','popup','popuptext','openmenu'};
        for i = 1:length(tag);
            set(h.(tag{i}),'Visible','off');
        end

    % 2.4 - Set date value
        set(h.date,'String',name);
        set(main,'Name',['Add/edit daily log for ',name]);

% 3 - ADD NEW IMAGES TO DATABASE
    case 'images'
    % 3.1 - Create the directory
        user = get(h.(use{1}),'UserData');
        loc = [GUI.settings.paths.database,user.folder,'\',...
                            user.subfolder,'\Images\'];
        imagefolder = [loc,name];
        if ~exist(imagefolder,'dir');
            mkdir(imagefolder);
        end

    % 3.2 - Determine files to copy
        if ~isfield(GUI,'currentdir'); GUI.currentdir = cd; end
        [newfile,loc] = uigetfile('*.jpg','Select images...',...
            GUI.currentdir,'MultiSelect','on');
        if isnumeric(newfile); return; end

    % 3.3 - Build list of images
        try
        copyfile([loc,newfile],imagefolder,'f');  %djwalters added to copy images to dropbox folder
        catch
        end
        fid = fopen([imagefolder,'\images.txt'],'a+');
        if ~iscell(newfile); newfile = {newfile}; end
        for i = 1:length(newfile); 
            files = [newfile{i}];
            fprintf(fid,'%s\n',files);
        end
        fclose(fid);

    % 3.4 - Save current directory
        GUI.currentdir = loc;
        guidata(hObject,GUI);
end

catch
    mes = ['Error adding ',type,' to database (callback_add.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end


%--------------------------------------------------------------------------
% SUBFUNCTION: getyear
function [yr,mo] = getyear(season,month)
% GETYEAR converts the season and month to a useable string.

    % Assigns numerical month based on character month
    switch month
        case 'Jan'; mo = 1;  case 'Feb'; mo = 2; case 'Mar'; mo = 3;
        case 'Apr'; mo = 4;  case 'May'; mo = 5; case 'Jun'; mo = 6;
        case 'Jul'; mo = 7;  case 'Aug'; mo = 8; case 'Sep'; mo = 9;
        case 'Oct'; mo = 10; case 'Nov'; mo = 11; case 'Dec'; mo = 12;
    end

    % Assignes year based on month and water year
    if mo > 10 
        yr = season(1:2);
        mo = num2str(mo);
    else
        yr = season(4:5);
        mo = ['0',num2str(mo)];
    end
