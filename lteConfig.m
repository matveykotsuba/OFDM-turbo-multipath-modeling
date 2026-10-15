function cfg = lteConfig(overrides)
    enb=struct('NDLRB',25,'NCellID',0,'CyclicPrefix','Normal','CellRefP',1, ...
        'NSubframe',0,'CFI',1,'DuplexMode','FDD');
    chs=struct('TxScheme','Port0','NLayers',1,'RNTI',1);
    cfg=struct('enb',enb,'chs',chs);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    if cfg.chs.NLayers~=1||~strcmp(cfg.chs.TxScheme,'Port0')
        error('project:Layers','This model supports one layer, Port0 only.');
    end
end
