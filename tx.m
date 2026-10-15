function [signal, info, params] = tx(cfg, varargin)
    legacy=nargin>0&&~isstruct(cfg)&&~isempty(cfg);
    if nargin==0||isempty(cfg),cfg=config();end
    if legacy
        modulation=cfg;cfg=config();cfg.modulation=modulation;
        cfg.coding.codeRate=1/3;
        if numel(varargin)>=1&&~isempty(varargin{1}),cfg.coding.codeRate=varargin{1};end
        if numel(varargin)>=2&&~isempty(varargin{2}),cfg.coding.rv=varargin{2};end
        if numel(varargin)>=3
            c=coding_config(varargin{3});cfg.coding.enabled=c.enabled;cfg.coding.backend=c.backend;cfg.coding.turboNumIter=c.turbo_num_iter;
        end
    end
    cfg=config(cfg);params=frameParameters(cfg);
    bits=int8(randi([0 1],params.tb_len,1));
    [coded,codingInfo]=encoder(bits,params);
    symbols=mapping(coded,params);
    signal=ofdmModulate(symbols,params);
    params.mod_symbol_power=mean(abs(symbols).^2);
    params.tx_signal_power=mean(abs(reshape(signal.',[],1)).^2);
    info=struct('cfg',cfg,'params',params,'bits',bits,'coding',codingInfo,'qamSymbols',symbols);
    if legacy,info=bits;end
end
