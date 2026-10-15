function [bits, crc_error] = crc24a_decode_manual(bits_crc)
    if numel(bits_crc)<24
        error('manualLTE:CRCBlock','CRC block must contain at least 24 bits.');
    end
    remainder=crc24a_remainder_manual(bits_crc);
    bits=int8(bits_crc(1:end-24)); bits=bits(:);
    crc_error=any(remainder~=0);
end
