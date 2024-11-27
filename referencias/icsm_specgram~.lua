--[[ specgram~: STFT Analysis ]]

--[[ Local variables ]]
local  pi = math.pi
M.status     = 0          -- 0=stand-by, 1=record (analysis)
M.ind        = 1          -- current frame index
M.maxmag     = 1          -- maximum magnitude
M._block     = 2048       -- block size
M._overlap   = 4          -- overlap factor
M._imagefile = "specgram" -- image file name
M.stopflag   = 0          -- used to synchronize control and DSP

--[[ Initialization messages ]]
print("specgram~ v. 0.1: STFT Analysis")
print("using block="..math.floor(M._block))
print("using overlap="..math.floor(M._overlap))
print("saving spectrogram image in file "..M._imagefile)
print("specgram~ ready!")

--[[ Magnitude and Phase arrays ]]
M.specgram = ofTable() -- magnitude spectrogram
M.specgraph = ofTable() -- phase spectrogram
M.speclen = 1 -- spectrogram length
M.specheight = M._block/2+1 -- FFT bins

--[[ process status updates ]]
function ofelia.float(n)
  --[[ signal perform function to stop recording ]]
  if M.status==1 and n==0 then
    M.stopflag = 1
    return
  end
  --[[ set new status ]]
  if M.status~=n then
    M.status = n
    --[[ all status changes rewind spectrogram ]]
    M.ind = 1
    --[[ print status messages ]]
    if M.status==0 then
      print("specgram~ ready!")
    elseif M.status==1 then
      print("specgram~ analyzing...")
    else
      print("status must be 0 or 1...")
      M.status = 0
    end
  end
end

--[[ user-friendly commands: stop, record ]]
function ofelia.stop()
  ofelia.float(0)
end

function ofelia.record()
  ofelia.float(1)
end

--[[ process message |block size< ]]
function ofelia.block(b)
  if M._block~=b then
    -- signal pd patch for block change
    bl = ofSend("$0-blsize")
    bl:sendFloat(b)
    -- set new block size and spectrogram height (# of FFT bins)
    M._block = b
    print("using block="..math.floor(M._block))
    M.specheight = M._block/2+1
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

--[[ process message |imagefile filename< ]]
function ofelia.imagefile(f)
  if M._imagefile~=f then
    M._imagefile = f
    print("saving spectrogram image in file "..M._imagefile)
  end
end

--[[ process DSP blocks ]]
function ofelia.perform(a,b)
  --[[ when in stand-by, return ]]
  if M.status==0 then
    return
  end
  --[[ when recording, store STFT coefficients ]]
  if M.status==1 then
    -- create new spectrogram columns
    M.specgram[M.ind] = ofTable()
    M.specgraph[M.ind] = ofTable()
    -- copy STFT coefficients
    for n=1, M.specheight do
      M.specgram[M.ind][n] = a[n]
      M.specgraph[M.ind][n] = b[n]
      -- keep maximum amplitude for visualization
      if a[n]>M.maxmag then M.maxmag = a[n] end
    end
    -- advances frame index
    M.ind = M.ind+1
  end
  --[[ stopflag==2: bookkeeping in the first full frame after recording ]]
  if M.stopflag==2 then
    M.stopflag = 0 -- next frame is regular
    M.speclen = M.ind-1 -- set size of spectrogram (number of frames)
    M.writeimage() -- generate image file for GEM visualization
    M.ind = 1 -- rewind spectrogram frame index
    M.status = 0 -- set status as stand-by
    print("specgram~ ready!")
  end
  --[[ stopflag==1: this frame is partially full ]]
  if M.stopflag==1 then
    M.stopflag = 2
  end
end


--[[ write spectrogram to ppm file and convert it to jpg ]]
function ofelia.writeimage()
  -- generate image ppm text file
  print("writing file "..M._imagefile..".ppm...")
  arq=io.open(M._imagefile..".ppm", "w")
  -- write file header
  arq:write("P3 "..math.floor(M.speclen).." "..math.floor(M.specheight).." 255 ")
  -- horizontal traversal of magnitude spectrogram matrix
  for j=M.specheight, 1, -1 do
    for i=1, M.speclen do
      c = M.specgram[i][j]/M.maxmag --normalization
      c = c^0.5 -- "amplify" very low values
      c = math.floor(255.9*c) -- 8-bit color values
      -- maps [0..1] values onto black..blue..red color palette
      arq:write(math.max(0,2*c-255), " ",0, " ",255-math.abs(2*c-255), " ")
    end
    arq:write(" ")
  end
  arq:close()
  -- use imagemagick for generating GEM-compatible jpg file
  print("converting to jpg...")
  print("command: convert "..M._imagefile..".ppm "..M._imagefile..".jpg")
  os.execute("convert "..M._imagefile..".ppm "..M._imagefile..".jpg")
  -- signal pd patch for new image file
  sendgem = ofSend("gem")
  sendgem:sendSymbol(M._imagefile..".jpg")
end
