function varargout = prefGUI(varargin)
%PREFGUI M-file for prefGUI.fig as created using GUIDE
%__________________________________________________________________________
% USAGE: varargout = prefGUI(varargin)
%
% INPUT:
%
% OUTPUT:
%__________________________________________________________________________

% 1 - BEGIN INITIALIZATION CODE - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @prefGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @prefGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% 2 - EXECUTES JUST BEFORE PREFGUI IS MADE VISIBLE.
function prefGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles);

% 3 - OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE.
function varargout = prefGUI_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
