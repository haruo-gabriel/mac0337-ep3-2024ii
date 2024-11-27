--[[ phasevocoder~: Phase Vocoder Resynthesis ]]

--[[ Local variables ]]
M._pos = 1 -- current position
M._speed = 0 -- resynthesis speed
M._shift = 1 -- transposition factor
M._block = 2048 -- block size
M._overlap = 4 -- overlap factor
M.siglen = 1

--[[ Initialization messages ]]
print("phasevocoder~ v. 0.1: Phase Vocoder Analysis/Resynthesis")
print("using block="..math.floor(M._block))
print("using overlap="..math.floor(M._overlap))
print("resynthesis speed="..M._speed)
print("resynthesis pitch shift="..M._shift)
print("phasevocoder~ ready!")

--[[ process message |speed factor< ]]
function ofelia.speed(s)
  if M._speed~=s then
    M._speed = s
    print("resynthesis speed="..M._speed)
  end
end

--[[ process message |shift cents< ]]
function ofelia.shift(s)
  local shift = 2^(s/1200)
  if M._shift~=shift then
    M._shift = shift
    print("resynthesis pitch shift="..shift)
  end
end

--[[ process message |block size< ]]
function ofelia.block(n)
  if M._block~=n then
    -- signal pd patch for block change
    bl = ofSend("$0-blsize")
    bl:sendFloat(n)
    -- set new block size
    M._block = n
    print("using block="..math.floor(M._block))
  end
end

--[[ process message |overlap factor< ]]
function ofelia.overlap(o)
  if M._overlap~=o then
    -- signal pd patch for overlap change
    ol = ofSend("$0-olap")
    ol:sendFloat(o)
    -- set new overlap factor
    M._overlap = o
    print("using overlap="..math.floor(M._overlap))
  end
end

--[[ process message |rewind< ]]
function ofelia.rewind()
  M._pos = 1
end

--[[ process message |pos time< ]]
function ofelia.pos(p)
  M._pos = 1+p*44100
end

--[[ process message |siglength samples< ]]
function ofelia.siglength(l)
  M.siglen = l
end

--[[ process bang (once for each DSP cycle) ]]
function ofelia.bang()
  if M.siglen==1 then return end
  local pos = M._pos --starting index
  local len = M._shift*M._block -- stretched window length (in samples)
  local lenms = 1000*M._shift*M._block/M._overlap/44100 -- stretched window length (in ms)
  local delta = M._shift*M._block/M._overlap
  M._pos =  M._pos + M._speed*M._block/M._overlap
  if M._pos >= M.siglen then
    M._pos = 1
  elseif M._pos < 1 then
    M._pos = M.siglen
  end
  local psend = ofSend("pv_pos") -- send position
  psend:sendFloat((M._pos-1)/44100)
  return ofTable(pos+delta, pos+delta+len, lenms, pos, pos+len, lenms)
end

