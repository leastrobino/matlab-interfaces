%
%  BK_3922.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef BK_3922 < matlab.mixin.SetGet
  
  properties
    Motor
    Position
  end
  
  properties (Access = private) %#ok<*MCSUP>
    interface
    encoder
    async
  end
  
  methods
    
    function this = BK_3922()
      global BK_3922_instance
      if BK_3922_instance == 1
        error('BK_3922:OneInstanceAllowed',...
          'Only one instance of the BK_3922 class is allowed.');
      end
      this.interface = PhidgetInterface('BK_3922');
      this.encoder = PhidgetEncoder('BK_3922');
      this.encoder.setCountsPerRevolution(1,16000);
      this.async.timer = timer(...
        'ExecutionMode','FixedRate',...
        'Name','BK_3922::goto',...
        'Period',1/50,...
        'TimerFcn',@this.asyncTimerFcn);
      this.Motor = 'off';
      BK_3922_instance = 1;
    end
    
    function delete(this)
      global BK_3922_instance
      try %#ok<TRYNC>
        this.Motor = 'off';
      end
      try %#ok<TRYNC>
        delete(this.interface);
      end
      try %#ok<TRYNC>
        delete(this.encoder);
      end
      BK_3922_instance = 0;
    end
    
    function set.Motor(this,mode)
      stop(this.async.timer);
      switch lower(mode)
        case 'ccw'
          this.interface.setDigitalOutput(1:2,[0 1]);
        case 'cw'
          this.interface.setDigitalOutput(1:2,[1 1]);
        case 'off'
          this.interface.setDigitalOutput(1:2,[0 0]);
        otherwise
          error('MATLAB:datatypes:InvalidEnumValueFor',...
            'Invalid enum value. Use one of these values: ''ccw'' | ''cw'' | ''off''.');
      end
      this.Motor = lower(mode);
    end
    
    function set.Position(this,position)
      this.encoder.setPosition(1,position);
    end
    
    function p = get.Position(this)
      p = mod(this.encoder.getPosition(1)+pi,2*pi)-pi;
    end
    
    function goto(this,position)
      p = this.encoder.getPosition(1);
      d = mod(position-p+pi,2*pi)-pi;
      this.async.position = p+d;
      if d > 0
        this.async.ccw = 1;
        this.Motor = 'ccw';
      else
        this.async.ccw = 0;
        this.Motor = 'cw';
      end
      try %#ok<TRYNC>
        start(this.async.timer);
      end
    end
    
  end
  
  methods (Access = private)
    
    function asyncTimerFcn(this,~,~)
      p = this.encoder.getPosition(1);
      if (~this.async.ccw && p <= this.async.position) || ...
          (this.async.ccw && p >= this.async.position)
        this.Motor = 'off';
      end
    end
    
  end
  
end
