function callback_openimage(hObject,eventdata)
% CALLBACK_OPENIMAGE opens an image viewer for each station selected;
%__________________________________________________________________________
% USEAGE:
%
% INPUT: hObject = handle of calling object
%        eventdata = not used, MATLAB requied
%__________________________________________________________________________
try
% Open a viewer window for each station selected
    GUI = guidata(hObject);             % Program guidata
    pth = GUI.settings.paths.database;  % Folder of DATA directory

% Determine the selected stations
    use = getselected(hObject);
    if isempty(use); disp('No station selected.'); return; end

% Open a viewer for each station 
    for i = 1:length(use);
        image_viewer(hObject,pth,use{i});
    end
catch
    mes = ['Error openning image viewer (callback_openimage.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: image_viewer
function image_viewer(hObject,pth,station)
% IMAGE_VIEWER opens a GUI to view images.

% 1 - BUILD THE IMAGE FOLDER LOCATION
    GUI    = guidata(hObject);              % Program Control guidata
    h      = guihandles(hObject);           % Handles of Program Control
    user   = get(h.(station),'UserData');   % Data for selected station
    loc = [pth,user.folder,'\',user.subfolder,'\Images\'];  % Image folder to open

% 2 - CHECK THAT IMAGES EXIST
    % 2.1 - Check that folder exists
        if ~exist(loc,'dir')
            warndlg(['No image folders exist for ',station,'.']); return;
        end

    % 2.2 - Search for folders within image directory
        available = dir(loc);

% 3 - BUILD LIST OF IMAGE FOLDERS AND DATES ASSOCIATED
    % 3.1 - Get folders and datenum values, removes . and empty directories
        k = 1; time = [];
        for i = 1:length(available);
            name = available(i).name;
            test = length(dir([loc,name]));
            if ~strcmpi(name(1),'.') && test > 2 && available(i).isdir
                folder{k} = available(i).name;
                try   time(k) = datenum(folder{k});
                catch time(k) = 0;
                end
                k = k + 1;
        end,end

    % 3.2 - Check that image files exist
        if isempty(time)
            warndlg(['No images exist for ',station,'.']); return;
        end
    
    % 3.3 - Re-order folders cronologically
        [time,idx] = sort(time);
        folder = folder(idx);

% 4 - OPEN THE VIEWER GUI
    % 4.1 - Set the selected date to open
        t = floor(GUI.time(1)); 
        idx = find(time==t,1,'first');
        if isempty(idx); idx = 1; end

    % 4.2 - Open the gui and set the title
        main = ImageGUI;
        h = guihandles(main);
        figname = [user.group,': ',user.display];
        set(main,'Name',figname)

    % 4.3 - Initilize station list and execute it's callback
        set(h.datepopup,'String',folder,'UserData',loc);
        set(h.datepopup,'Value',idx);

        fhandle = get(h.datepopup,'Callback');
        fhandle(h.datepopup,1);
