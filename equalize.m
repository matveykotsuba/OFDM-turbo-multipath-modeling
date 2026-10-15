function [symbols, variance, info] = equalize(grid, params, channelInfo)
    enabled=~isfield(params,'equalizer_enabled')||params.equalizer_enabled;
    applied=enabled&&~strcmpi(channelInfo.type,'awgn');
    if ~applied
        processed=grid;
        variance=channelInfo.noisePower*ones(numel(grid),1);
    else
        H=fftshift(fft(channelInfo.h(:),params.N,1),1);
        H=H(params.active_indices);
        hm=repmat(H.',params.num_symbols,1);
        processed=grid./(hm+1e-12);
        hv=reshape(hm.',[],1);
        variance=channelInfo.noisePower./(abs(hv).^2+1e-12);
    end
    symbols=reshape(processed.',[],1);
    symbols=symbols(1:params.mod_symbol_len);
    variance=variance(1:params.mod_symbol_len);
    info=struct('enabled',logical(enabled),'applied',logical(applied),'mode','bypass');
    if applied,info.mode='zf';end
end
