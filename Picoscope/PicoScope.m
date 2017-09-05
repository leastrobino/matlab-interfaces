%
%  PicoScope.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

classdef PicoScope < handle
  
  properties (SetAccess = private)
    IDN
    VariantInfo
    HardwareVersion
    DriverVersion
    ClassVersion
    USBVersion
    Timebase
    ChannelA = 'off';
    ChannelB = 'off';
    Trigger = 'none';
  end
  
  properties (Access = private)
    ptr
    range = [0 0];
    dt = 0;
  end
  
  methods
    
    function this = PicoScope()
      this.ptr = ps2000('open_unit');
      if ~this.ptr
        error('PicoScope:CommunicationError','Unable to open the device.');
      else
        ps2000('set_defaults',this.ptr);
        [this.DriverVersion,this.USBVersion,this.HardwareVersion,...
          this.VariantInfo,this.IDN,...
          this.ClassVersion,t] = ps2000('get_unit_info',this.ptr);
        this.Timebase = 1E-9*double(t);
      end
    end
    
    function delete(this)
      ps2000('stop',this.ptr);
      ps2000('close_unit',this.ptr);
    end
    
    function range = setChannel(this,channel,range,coupling)
      if nargin < 4
        coupling = 'DC';
      end
      if strcmpi(channel,'A') || channel == 1
        channel = 0;
      elseif strcmpi(channel,'B') || channel == 2
        channel = 1;
      else
        error('PicoScope:UnknownChannel',...
          'Unknown channel.');
      end
      if strcmpi(coupling,'off')
        dc = -1;
        s = 'off';
      elseif strcmpi(coupling,'AC')
        dc = 0;
        s = 'AC coupling';
      elseif strcmpi(coupling,'DC')
        dc = 1;
        s = 'DC coupling';
      else
        error('PicoScope:UnknownCoupling',...
          'Unknown coupling.');
      end
      r = 0;
      if dc ~= -1
        ranges = [20E-3 50E-3 100E-3 200E-3 500E-3 1 2 5 10 20];
        [~,r] = min(abs(ranges-range));
        range = ranges(r);
        this.range(channel+1) = range;
        s = ['±' double2unit(range,3,'V') ', ' s];
      end
      try
        ps2000('set_channel',this.ptr,channel,r,dc);
      catch
        error('PicoScope:OutOfRange',...
          'Parameter out of range.');
      end
      if channel == 0
        this.ChannelA = s;
      else
        this.ChannelB = s;
      end
    end
    
    function setTrigger(this,channel,threshold,edge,delay)
      if nargin < 4
        edge = 'rising';
      end
      if nargin < 5
        delay = 0;
      end
      if strcmpi(channel,'none') || channel == 0
        ps2000('set_trigger',this.ptr,5,0,0,0);
        this.Trigger = 'none';
        return
      elseif strcmpi(channel,'A') || channel == 1
        channel = 0;
        s = 'Channel A, ';
      elseif strcmpi(channel,'B') || channel == 2
        channel = 1;
        s = 'Channel B, ';
      else
        error('PicoScope:UnknownChannel',...
          'Unknown channel.');
      end
      threshold = int16(threshold*32767/this.range(channel+1));
      s = [s double2unit(double(threshold)*this.range(channel+1)/32767,3,'V')];
      if strcmpi(edge,'rising')
        edge = 0;
        s = [s ', rising edge'];
      elseif strcmpi(edge,'falling')
        edge = 1;
        s = [s ', falling edge'];
      else
        error('PicoScope:UnknownDirection',...
          'Unknown direction.');
      end
      try
        ps2000('set_trigger',this.ptr,channel,threshold,edge,delay);
      catch
        error('PicoScope:OutOfRange',...
          'Parameter out of range.');
      end
      this.Trigger = s;
    end
    
    function dt = runBlock(this,n,dt,nbits)
      if nargin < 4
        nbits = 8;
      end
      for i = 0:31
        if this.Timebase*2^i >= dt
          break
        end
      end
      dt = this.Timebase*2^i;
      oversample = floor(max([4^(nbits-8) 1]));
      try
        ps2000('run_block',this.ptr,n,i-log2(oversample),oversample);
      catch
        error('PicoScope:OutOfRange','Parameter out of range.');
      end
      this.dt = dt;
    end
    
    function dt = runStreaming(this,n,dt)
      for i = 0:31
        if this.Timebase*2^i >= dt
          break
        end
      end
      dt = this.Timebase*2^i;
      try
        ps2000('run_streaming_ns',this.ptr,n,1E6*dt);
      catch
        error('PicoScope:OutOfRange','Parameter out of range.');
      end
      this.dt = dt;
    end
    
    function stop(this)
      ps2000('stop',this.ptr);
    end
    
    function r = isready(this)
      r = ps2000('ready',this.ptr);
    end
    
    function [t,A,B,OverflowA,OverflowB] = getValues(this,n)
      try
        [A,B,OverflowA,OverflowB] = ps2000('get_values',this.ptr,n);
      catch
        error('PicoScope:OutOfRange','Parameter out of range.');
      end
      t = this.dt*(0:length(A)-1)';
      A = double(A)*this.range(1)/32767;
      B = double(B)*this.range(2)/32767;
    end
    
    function [dt,A,B,lastValues,triggered,triggeredAt,OverflowA,OverflowB] = getStreamingLastValues(this)
      try
        [A,B,lastValues,triggered,triggeredAt,OverflowA,OverflowB] = ps2000('get_streaming_last_values',this.ptr);
      catch
        error('PicoScope:NoSamples','No samples available.');
      end
      dt = this.dt;
      A = double(A)*this.range(1)/32767;
      B = double(B)*this.range(2)/32767;
    end
    
  end
  
end
