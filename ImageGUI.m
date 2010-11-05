function varargout = ImageGUI(varargin)
% IMAGEGUI M-file for ImageGUI.fig
%__________________________________________________________________________
% USAGE: h = ImageGUI;
%
% INPUT: none
% 
% OUTPUT: h - handle of created viewer window
%
% NOTES: This m-file was constructed with MATLAB's guide and then modified
%__________________________________________________________________________

% 1 - BEGIN INITIALIZATION CODE - DO NOT EDIT
    gui_Singleton = 0;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @ImageGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @ImageGUI_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT

% 2 - EXECUTES JUST BEFORE IMAGEGUI IS MADE VISIBLE.
function ImageGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles); 
  
    %  2.1 - Set the date list callbacks and initilize list
        set(handles.datepopup,'Callback',{@callback_changeday});      
        
    %  2.2 - Set the image popup menu and back/forward callbacks
        set(handles.imagepopup,'Callback',{@callback_image});
        set(handles.imageforward,'Callback',{@callback_buttons});
        set(handles.imageback,'Callback',{@callback_buttons});
        set(handles.dateforward,'Callback',{@callback_buttons});
        set(handles.dateback,'Callback',{@callback_buttons});

    % 2.3 - Set the menu options callbacks
        set(handles.exit,'Callback',{@exit,handles});
        set(handles.export,'Callback',{@export});
        set(handles.openwindows,'Callback',{@openwindows});
        set(handles.rename,'Callback',{@rename});
        
          
% 3 - OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE.
function varargout = ImageGUI_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

%--------------------------------------------------------------------------
% CALLBACK: callback_changeday
function callback_changeday(hObject,eventdata)
% CALLBACK_CHANGEDAY upadates the viewer for images in selected folder

% Extract the image files from current image folder
    h = guihandles(hObject);            % Image viewer handles
    loc = get(hObject,'UserData');      % Image folders location
    str = get(hObject,'String');        % Image folders that exists
    folder = str{get(hObject,'Value')}; 
    files = dir([loc,folder,'\*.jpg']); % Available images

% Build a list of filenames and associated dates
    for i = 1:length(files);
        list{i} = files(i).name;
        name{i} = [loc,folder,'\',files(i).name];
    end

% Add images contained in the images.txt file, if it exists
    imagedb = [loc,folder,'\images.txt'];
    if exist(imagedb,'file');
        
        % Read the images.txt file
        fid = fopen(imagedb,'r');
        C = textscan(fid,'%s\n'); C = C{1};
        fclose(fid);
                
        % Append files to the name and list variables
        k = length(name)+1;
        for i = 1:length(C);
            [p,f,e] = fileparts(C{i});
            list{k} = [f,e];
            name{k} = C{i};
            k = k + 1;
        end 
    end
    
% Establish the image list and open the image
    set(h.imagepopup,'String',list,'UserData',name);
    callback_image(h.imagepopup,1);

%--------------------------------------------------------------------------
function callback_image(hObject,eventdata)
% CALLBACK_IMAGE upadates the viewer for selected image

% Determines the image to open
    h = guihandles(hObject);
    name = get(hObject,'UserData');
    idx  = get(hObject,'Value');
    if idx > length(name); set(hObject,'Value',1); idx = 1; end
    
% Sets the image axes
    if isfield(h,'ax'); ax = h.ax;
    else ax = gca;
    end

% Reads and displays the image
    I = imread(name{idx});                       % Reads image file 
    image(I,'parent',ax);                        % Inserts image
    set(ax,'YTick',[],'XTick',[],'tag','ax');    % Removes tick marks
    hz = zoom(ax);                               % Enables zooming
    set(hz,'Enable','on');
    set(h.openwindows,'UserData',name{idx});     % Stores image name
    hManager = uigetmodemanager(h.figure1); 
    set(hManager.WindowListenerHandles,'Enable','off'); 
    hh = [h.figure1,h.imageforward,h.imageback,h.dateforward,...
        h.dateback,h.datepopup,h.imagepopup];
    set(hh,'KeyPressFcn',{@enhance});

%--------------------------------------------------------------------------
function callback_buttons(hObject,eventdata)
% CALLBACK_BUTTONS cycles forward and back for associated button and list

% Determine the button that was pushed and assign handle and movement
    h = guihandles(hObject);
    switch get(hObject,'Tag');
        case 'imageforward';    handle = h.imagepopup; move = 1;
        case 'imageback';       handle = h.imagepopup; move = -1;
        case 'dateforward';     handle = h.datepopup;  move = 1;
        case 'dateback';        handle = h.datepopup;  move = -1;
    end

% Determine the new list location
    N = length(get(handle,'String'));
    current = get(handle,'Value');
    new     = current + move;
    if new > N; new = 1; end;
    if new < 1; new = N; end;
    
% Set the new list location value  
    if new >= 1 && new <= N;
        set(handle,'Value',new);
        fcall = get(handle,'Callback');
        fcall(handle,1);
    end

%--------------------------------------------------------------------------
function export(hObject,eventdata)
%EXPORT allows user to save the image to a new location

% Extract the current filename
    h = guihandles;
    name = get(h.openwindows,'UserData'); % Extracts filename from gui
    
% Case when name is empty, no image is selected    
    if isempty(name);
        warndlg('You must select an image before it can be opened.',...
            'Warning.','non-modal'); return
    end

% Prompt user to save the image
    [p,fn,ext] = fileparts(name);
    [f,p] = uiputfile([fn,ext],'Save image as...');
    if f == 0; return; end

% Copies file to new location
    copyfile(name,[p,f],'f');

%--------------------------------------------------------------------------
function rename(hObject,eventdata)
% RENAME allows user to rename the current image

% Extract the current filename
    h = guihandles(hObject);
    name = get(h.openwindows,'UserData');
    [p,fold,e] = fileparts(name);

% Prompt user for a new filename
    mes = ['Enter the new name for this image: ',fold,'. '];
    fnew  = inputdlg(mes);
    newname = [p,fnew,e];

% Rename the file
    copyfile(name,newname);
    delete(name);

% Update the list
    callback_image(h.imagepopup,1);

%--------------------------------------------------------------------------
function openwindows(hObject,eventdata)
    name = get(hObject,'UserData'); % Current filename
    winopen(name);
    
%--------------------------------------------------------------------------
function exit(hObject,eventdata,handles); close(handles.figure1);

function enhance(hObject,eventdata)   
h = guihandles(hObject);
str = get(h.figure1,'UserData');
str = [str,eventdata.Key];
if length(str) > 7; str = str(2:8); end
set(h.figure1,'UserData',str);
if strcmpi('enhance',str);
disp('enhance');
h = findobj('Type','image');
I = get(h,'Cdata');
B = fspecial('unsharp');
B1 = imfilter(imfilter(imfilter(I,B),B),B); 
[y,Fs] = wavread('enhance.wav');
set(h,'Cdata',B1);pause(0.5);
wavplay(y(1:90000),Fs);    
 set(h,'Cdata',I);
end

    