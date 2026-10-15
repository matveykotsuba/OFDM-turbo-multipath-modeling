function remainder = crc24a_remainder_manual(bits)
    if ~(isnumeric(bits)||islogical(bits)) || ~isreal(bits) || ...
            (~isvector(bits) && ~isempty(bits)) || any(bits(:)~=0 & bits(:)~=1)
        error('manualLTE:Bits','CRC input must be a binary vector.');
    end
    reg=uint32(0);
    polynomial=uint32(hex2dec('864CFB')); % leading x^24 is implicit
    mask=uint32(hex2dec('FFFFFF'));
    for k=1:numel(bits)
        feedback=xor(bitget(reg,24)~=0,bits(k)~=0);
        reg=bitand(bitshift(reg,1),mask);
        if feedback, reg=bitxor(reg,polynomial); end
    end
    remainder=zeros(24,1,'int8');
    for k=1:24, remainder(k)=int8(bitget(reg,25-k)); end
end
