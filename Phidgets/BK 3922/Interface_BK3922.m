%
%  Interface_BK3922.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef Interface_BK3922 < handle
  
  properties (Access = private)
    h
    s
    d
  end
  
  methods
    
    function this = Interface_BK3922()
      
      % Default data
      this.d.appdir = [fileparts(mfilename('fullpath')) filesep];
      this.d.step = 0;
      
      % Main window
      this.h.window = UIComponent.Figure(...
        'CloseRequestFcn',@this.closeRequestFcn,...
        'Name','Interface Brüel & Kjær 3922  |  LAA  |  hepia',...
        'Size',[365 200]);
      
      % Dial plot
      this.h.dial = UIComponent.Dial(...
        'IndicatorAngle',-90,...
        'IndicatorNumberFormat','0°',...
        'Min',-180,...
        'Max',179,...
        'StartAngle',-90,...
        'StopAngle',269,...
        'Parent',this.h.window,...
        'Position',[10 10 180 180]);
      
      % Motor panel
      p = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[205 115 150 80],...
        'Title','Turntable Motor');
      UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Parent',p,...
        'Position',[10 40 130 20],...
        'String','Mode: Cont. Fwd.');
      this.h.led_off = UIComponent.createIcon('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MjM4NzM5RDFGQjBBMTFFNUJDMDk5QzgzNTg5NjZCM0QiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MjM4NzM5RDJGQjBBMTFFNUJDMDk5QzgzNTg5NjZCM0QiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDoyMzg3MzlDRkZCMEExMUU1QkMwOTlDODM1ODk2NkIzRCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDoyMzg3MzlEMEZCMEExMUU1QkMwOTlDODM1ODk2NkIzRCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PpWn/HYAAANMSURBVHjajJTLS1tREMYn8fpcSE2T+CpExJhESEnpwqWbFlsS60akCxf9C4ptSpcN4kYKxYX7QkuXuolVLJhu3IgQlRpNCkHxbUhCgoqP+Or3HXJDSFPowHDuPWfmN3Nm5l7D7Oys6HJ7eys3NzdczXd3d15sPTEajU6DwWDhOfZSOIvi8Sf2vuMsWVFRIVgLDE3+liEY+aEevlxfX8vV1ZU6qKystNXU1DwGeAiBf2H9hO2vxc5ayfNYVVWVnxFTqZRsbm6qlZnDWZiN2WyW9vZ2rg+x/wXgR/B7D1VRNT1dOIxVV1f76by2tibxeFwaGxvF4/FIQ0ODsslkMrK1tSULCwtit9vF7XaLpmnDLBPkjQIyKuQlwH4+LC0tyfb2tvh8PgXDFVV2FNRNzs/PZXV1VWZmZiSXy0l3dzdrOIxEwjD5RqAJGwGCI5GILC8vy+DgoDidTkkkEpKPXoAiI3E4HHJ2diaTk5NiMpmkq6uLdh9gM4dzzQd10iAUCkldXZ2q0/r6uqrdv4Q2KJHy4fVxEzsa+ILAZ+ieHB4eSjgclp6eHtnf35fj4+OyID3Tk5MTQQNlcXFR+XZ2dnL7uQaYi9fd3d2VnZ0dOTg4UMDT09N/wigMSDv67O3tqWtDHMzwPjvNiKzXysqKtLa2quuw6OVgvBFhtOWcZrNZVVvIPTbFwAzz3ZZkMinz8/PicrkUVJ9BKrtMZaBoNKpmVG8UFTYGzmEKER80NTWpEbm4uFDXT6fTYrFYpLa2thCMN2DzCOJKoU9LS4sCIniWGcYA9TAjfgEbGxvKkA6cR2akD7+ebbHQhyNGG2jMCOAPOrW1tUlfX1/ZRjAzaimM0t/fLzabTT2DNUfgNIC/OQIc6N7eXvlfoS192CQw4mAFCUwj1VFGZy0CgUDZTEvF6/XKyMiINDc36z+OUdQxaeAM5WUcUYaZKYs+NTUlwWBQYrFYYcjr6+vVZ8eAAwMDYrVa5fLyksAJHL9W3zsHWR8vAD/yQ2fHWFfOGv86R0dHyoCT0NHRoeaUWXEG0agJPL/Dca4UqHfqFWBvsboJLv4j65D8Xz2C93E8fy7+5ssBqVaoD+CnUAeOTHmTDCAxaAg6DVAiDy8w/ggwAOBzyNxQf5NuAAAAAElFTkSuQmCC');
      this.h.led_on = UIComponent.createIcon('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MjdGQTFBNjhGQjBBMTFFNTg3QjFCMENEMDg3NzYwRTkiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MjdGQTFBNjlGQjBBMTFFNTg3QjFCMENEMDg3NzYwRTkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDoyN0ZBMUE2NkZCMEExMUU1ODdCMUIwQ0QwODc3NjBFOSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDoyN0ZBMUE2N0ZCMEExMUU1ODdCMUIwQ0QwODc3NjBFOSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PlgmBtYAAAQASURBVHjabFVLb1tFFP5m5j78auraTuomgZaoJklRUSAowK5CRQU1gQ2KWBSJX4ACQSypUDcVEuqieyQQEhvYtBAVQhASCyrxaAWhBBGBTBwnaZyXYxzbuXcu3/jaaZVmpHNndM7MN995zLliamoK7aG1hu/7Zs4EQXCeqrNSygEhRKexU1ei7Q8uv6XuC9pWlVLgvIdh4cFxgZsmpVJDng9Uax4au7tNg2Pbx2ORyLClggva93/lBR9Q/fH9h61968uO40x6WmL5bgk7a38jqkuIWNrwQ9VXWJMZRNN9ONqZedyR+iPP95+g8R1K81arTZe3XY647mS5prEw/xuy+AvPDmbR2zuEWOJIc0+1soFi4R/Mzn+P/FYOPX2nkYhYEyZMHG+aj5ienjbzq0rJTyt1IH/nJobTeTzz3ChEdoimCIMbhD5Iwc8OguXb+PG7L/Hz+iPo7X8aCTdg7PVrNH5iMV4psrzoQ2EpP4uRxC8YOTsOHB4ANldI3W9FpAUqLIhkP0bOVGF9/RluFVKI507Blv679PKGxTFKGSisVnGsMoORp2KAygCl34nB2In7otzCRMUQz+DJky5Wbs9gYzuH7nQk53neSwbwhUDYaJSXMOz8xFSeAbYXQcU9sAAPou5uA7aDx+yb+KGyBJ15FJaFFy3btgcrDYW4t4CsXADKRSBKwN1KCHgQmJlsXlheRBf+RcIrwAtOIW6j3zBMBw2JmNiGC8Zr9Rbd6aHbLuA3DvDXJMdmyhebe93AQxybCBhbMkyapAjLUghY8cwL47MKFL4BjgyGoEFYg6wrMjaUKZoXbfDBVErNMyRlPlCKsMxwKRqxexvRLBqVCKKixhjS9foamfLFWVFiqBZJeuBVgRqBGtUmdkNEoKPdiLkGUG8ahnNxWw5tJQexsd6HqH+HLiE80MiHtSdab9Ww3atJ8/iBLasPQXIAcVdCaDnHJ6u+ci2BROcJLCXHwlAFrQMSoavaD8Ws9/ShLKdeRjx9HCRIhuqGAbzOzvFnZ4eD2sPjyB86R7fC28NC3ido2bhn8fA57Dw0jlTCZnjFPLGuGcA1xvGSYwU4mu3GSu4iCumxJpk94DZrfU9XTJ/HUu49ZLqOwVGBYXeJyVkVhUKhXQxXpBQTde1gc72EWOFzpEvXkKjNwfbLYS2rDvwX6UcpM4Zq7ytIprrgyjr7Z3CV5jeaDhWLxTagTdrvKyknfHay7bpAnYWryvOw6svNDZ6bhe44CaejB4fYEBTp+lpf5Rt+26RxP2Cz81Jel0K8JaQ8bYB3tYIfhFlWImAT8Dj7TLieJdAVtq4PTadvj4MAjXRRRsn4eUo/TanWlg2CzFFmKNcJtNL6Zexh/C/AAJ4Gp//dNXDKAAAAAElFTkSuQmCC');
      this.h.CCW = UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Icon',this.h.led_off,...
        'Parent',p,...
        'Position',[10 10 60 20],...
        'String','CCW');
      this.h.CW = UIComponent.Label(...
        'HorizontalAlignment','left',...
        'Icon',this.h.led_off,...
        'Parent',p,...
        'Position',[80 10 60 20],...
        'String','CW');
      
      % Position panel
      p = UIComponent.Panel(...
        'Parent',this.h.window,...
        'Position',[205 10 150 95],...
        'Title','Position');
      this.h.position = UIComponent.Spinner(...
        'Callback',@this.goto,...
        'Min',-360,...
        'Max',360,...
        'Parent',p,...
        'Position',[10 45 55 25]);
      this.h.setZero = UIComponent.Button(...
        'Callback',@this.setZero,...
        'Parent',p,...
        'Position',[75 45 65 25],...
        'String','Set 0°');
      this.h.goto = UIComponent.Button(...
        'Callback',@this.goto,...
        'Parent',p,...
        'Position',[10 10 130 25],...
        'String','Go to position');
      
      % Timer
      this.h.timer = timer(...
        'ExecutionMode','FixedRate',...
        'Period',1/25,...
        'TimerFcn',@this.timerFcn);
      
      % Connect to the Brüel & Kjær 3922
      try
        this.h.bk3922 = BK_3922();
      catch e
        jerrordlg(e.message);
        this.closeRequestFcn();
        if isdeployed
          return
        else
          rethrow(e);
        end
      end
      
      % Start the timer
      start(this.h.timer);
      
      % Show the main window
      this.h.window.Visible = 'on';
      
    end
    
  end
  
  methods (Access = private)
    
    function closeRequestFcn(this,~,~)
      try %#ok<TRYNC>
        this.h.window.Visible = 'off';
      end
      stop(this.h.timer);
      delete(this.h.timer);
      try %#ok<TRYNC>
        delete(this.h.bk3922);
      end
      close(this.h.window,'force');
    end
    
    function setZero(this,~,~,~)
      this.h.bk3922.Position = 0;
      this.h.position.Value = 0;
    end
    
    function goto(this,~,~,~)
      this.h.setZero.Enable = 'off';
      this.h.goto.Enable = 'off';
      this.h.bk3922.goto(this.h.position.Value*pi/180);
      this.d.step = 1;
    end
    
    function timerFcn(this,~,~)
      this.h.dial.Value = this.h.bk3922.Position*180/pi;
      if strcmp(this.h.bk3922.Motor,'ccw')
        this.h.CCW.Icon = this.h.led_on;
      else
        this.h.CCW.Icon = this.h.led_off;
      end
      if strcmp(this.h.bk3922.Motor,'cw')
        this.h.CW.Icon = this.h.led_on;
      else
        this.h.CW.Icon = this.h.led_off;
      end
      if this.d.step == 1 && strcmp(this.h.bk3922.Motor,'off')
        pause(1);
        this.d.step = 2;
        this.h.bk3922.goto(this.h.position.Value*pi/180);
      elseif this.d.step == 2 && strcmp(this.h.bk3922.Motor,'off')
        this.d.step = 0;
        this.h.setZero.Enable = 'on';
        this.h.goto.Enable = 'on';
      end
    end
    
  end
  
end
