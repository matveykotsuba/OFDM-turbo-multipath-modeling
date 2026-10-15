function cfg = config(overrides)
    persistent lastInput lastOutput;
    if nargin>0 && isequal(overrides,lastInput) && ~isempty(lastOutput)
        cfg=lastOutput; return;
    end
    cfg=struct('fftSize',2048,'subcarrierSpacing',15e3,'modulation','QPSK', ...
        'coding',codingConfig(),'channel',channelConfig(),'receiver',receiverConfig(), ...
        'experiment',experimentConfig(),'lte',lteConfig());
    n=numerologyConfig(cfg.fftSize,cfg.subcarrierSpacing,cfg.lte.enb.NDLRB);
    names=fieldnames(n);for k=1:numel(names),cfg.(names{k})=n.(names{k});end
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    validateattributes(cfg.fftSize,{'numeric'},{'scalar','real','integer','positive','finite'});
    validateattributes(cfg.subcarrierSpacing,{'numeric'},{'scalar','real','positive','finite'});
    if ~ischar(cfg.modulation)||~ismember(upper(cfg.modulation),{'QPSK','16QAM','64QAM'}),error('project:Modulation','Expected QPSK, 16QAM or 64QAM.');end
    cfg.modulation=upper(cfg.modulation);
    cfg.sampleRate=cfg.fftSize*cfg.subcarrierSpacing;
    cfg.samplePeriod=1/cfg.sampleRate;
    cfg.coding=codingConfig(cfg.coding);
    cfg.channel=channelConfig(cfg.channel);
    cfg.receiver=receiverConfig(cfg.receiver);
    cfg.experiment=experimentConfig(cfg.experiment);
    cfg.lte=lteConfig(cfg.lte);
    if ~strcmp(cfg.lte.enb.CyclicPrefix,'Normal')
        error('project:CP','This waveform implements normal CP only.');
    end
    n=numerologyConfig(cfg.fftSize,cfg.subcarrierSpacing,cfg.lte.enb.NDLRB);
    names=fieldnames(n);for k=1:numel(names),cfg.(names{k})=n.(names{k});end
    if nargin>0, lastInput=overrides; lastOutput=cfg; end
end
